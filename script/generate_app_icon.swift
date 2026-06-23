#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private enum IconGeneratorError: LocalizedError {
    case invalidArguments
    case unreadableSource(URL)
    case contextCreationFailed
    case imageCreationFailed
    case destinationCreationFailed(URL)
    case iconutilFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "usage: generate_app_icon.swift <source.png> <output-directory>"
        case .unreadableSource(let url):
            return "unable to read source image: \(url.path)"
        case .contextCreationFailed:
            return "unable to create a bitmap context"
        case .imageCreationFailed:
            return "unable to create a rendered image"
        case .destinationCreationFailed(let url):
            return "unable to create PNG destination: \(url.path)"
        case .iconutilFailed(let message):
            return "iconutil failed: \(message)"
        }
    }
}

private let colorSpace = CGColorSpaceCreateDeviceRGB()
private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

private func loadImage(at url: URL) throws -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw IconGeneratorError.unreadableSource(url)
    }
    return image
}

private func renderedPixels(from source: CGImage, size: Int) throws -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: size * size * 4)
    let sourceSide = min(source.width, source.height)
    let sourceRect = CGRect(
        x: (source.width - sourceSide) / 2,
        y: (source.height - sourceSide) / 2,
        width: sourceSide,
        height: sourceSide
    )
    guard let cropped = source.cropping(to: sourceRect) else {
        throw IconGeneratorError.imageCreationFailed
    }

    try pixels.withUnsafeMutableBytes { buffer in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw IconGeneratorError.contextCreationFailed
        }
        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: size, height: size))
    }
    return pixels
}

/// Removes only the near-black area connected to the four canvas corners.
/// Dark pixels inside the artwork are never reached, so the supplied logo remains unchanged.
private func clearConnectedCanvas(in pixels: inout [UInt8], size: Int) {
    let cornerOffsets = [
        0,
        (size - 1) * 4,
        (size - 1) * size * 4,
        ((size * size) - 1) * 4,
    ]
    let cornerColor = cornerOffsets.reduce(into: (r: 0, g: 0, b: 0)) { result, offset in
        result.r += Int(pixels[offset])
        result.g += Int(pixels[offset + 1])
        result.b += Int(pixels[offset + 2])
    }
    let reference = (
        r: cornerColor.r / cornerOffsets.count,
        g: cornerColor.g / cornerOffsets.count,
        b: cornerColor.b / cornerOffsets.count
    )

    func isCanvasPixel(_ pixelIndex: Int) -> Bool {
        let offset = pixelIndex * 4
        let red = Int(pixels[offset])
        let green = Int(pixels[offset + 1])
        let blue = Int(pixels[offset + 2])
        let distance = abs(red - reference.r) + abs(green - reference.g) + abs(blue - reference.b)
        return distance <= 30 && max(red, green, blue) <= 18
    }

    var visited = [Bool](repeating: false, count: size * size)
    var queue = [Int]()
    queue.reserveCapacity(size * size / 4)
    let corners = [0, size - 1, (size - 1) * size, (size * size) - 1]
    for corner in corners where isCanvasPixel(corner) {
        visited[corner] = true
        queue.append(corner)
    }

    var cursor = 0
    while cursor < queue.count {
        let index = queue[cursor]
        cursor += 1
        let x = index % size
        let y = index / size
        let neighbors = [
            x > 0 ? index - 1 : -1,
            x + 1 < size ? index + 1 : -1,
            y > 0 ? index - size : -1,
            y + 1 < size ? index + size : -1,
        ]

        for neighbor in neighbors where neighbor >= 0 && !visited[neighbor] && isCanvasPixel(neighbor) {
            visited[neighbor] = true
            queue.append(neighbor)
        }
    }

    for index in queue {
        let offset = index * 4
        pixels[offset] = 0
        pixels[offset + 1] = 0
        pixels[offset + 2] = 0
        pixels[offset + 3] = 0
    }
}

private func makeImage(pixels: inout [UInt8], size: Int) throws -> CGImage {
    try pixels.withUnsafeMutableBytes { buffer in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw IconGeneratorError.contextCreationFailed
        }
        guard let image = context.makeImage() else {
            throw IconGeneratorError.imageCreationFailed
        }
        return image
    }
}

private func resized(_ source: CGImage, to size: Int) throws -> CGImage {
    var pixels = [UInt8](repeating: 0, count: size * size * 4)
    return try pixels.withUnsafeMutableBytes { buffer in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw IconGeneratorError.contextCreationFailed
        }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let image = context.makeImage() else {
            throw IconGeneratorError.imageCreationFailed
        }
        return image
    }
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw IconGeneratorError.destinationCreationFailed(url)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw IconGeneratorError.destinationCreationFailed(url)
    }
}

private func runIconutil(iconsetURL: URL, outputURL: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
    let errorPipe = Pipe()
    process.standardError = errorPipe
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        throw IconGeneratorError.iconutilFailed(String(decoding: data, as: UTF8.self))
    }
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw IconGeneratorError.invalidArguments
    }

    let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
    let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let source = try loadImage(at: sourceURL)
    var masterPixels = try renderedPixels(from: source, size: 1024)
    clearConnectedCanvas(in: &masterPixels, size: 1024)
    let master = try makeImage(pixels: &masterPixels, size: 1024)
    try writePNG(master, to: outputDirectory.appendingPathComponent("AppIcon-1024.png"))

    let temporaryIconset = FileManager.default.temporaryDirectory
        .appendingPathComponent("CodexUsageMonitor-\(UUID().uuidString).iconset")
    try FileManager.default.createDirectory(at: temporaryIconset, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryIconset) }

    let iconFiles: [(name: String, size: Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for iconFile in iconFiles {
        let image = iconFile.size == 1024 ? master : try resized(master, to: iconFile.size)
        try writePNG(image, to: temporaryIconset.appendingPathComponent(iconFile.name))
    }

    let icnsURL = outputDirectory.appendingPathComponent("CodexUsageMonitor.icns")
    try runIconutil(iconsetURL: temporaryIconset, outputURL: icnsURL)
    print("Generated \(icnsURL.path)")
} catch {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
