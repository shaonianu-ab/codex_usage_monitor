import AppKit
import SwiftUI

@MainActor
enum SnapshotRenderer {
  static func write(
    store: UsageStore,
    settings: SettingsStore,
    launchAtLogin: LaunchAtLoginStore,
    screen: PopoverScreen = .dashboard,
    to outputURL: URL
  ) throws {
    let maximumSize = CGSize(
      width: UsagePopoverView.preferredWidth,
      height: UsagePopoverView.maximumHeight
    )
    let hostingView = NSHostingView(
      rootView: UsagePopoverView(
        store: store,
        settings: settings,
        launchAtLogin: launchAtLogin,
        initialScreen: screen
      )
    )
    hostingView.frame = NSRect(origin: .zero, size: maximumSize)

    // ScrollView does not reliably draw through ImageRenderer when it has
    // never joined an AppKit view hierarchy. A tiny off-screen host window
    // gives SwiftUI a real layout pass without showing anything to the user.
    let window = NSWindow(
      contentRect: NSRect(origin: NSPoint(x: -4_000, y: -4_000), size: maximumSize),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.contentView = hostingView
    window.orderFrontRegardless()
    hostingView.layoutSubtreeIfNeeded()
    window.displayIfNeeded()

    let fittingHeight = ceil(hostingView.fittingSize.height)
    let size = CGSize(
      width: UsagePopoverView.preferredWidth,
      height: min(UsagePopoverView.maximumHeight, fittingHeight)
    )
    window.setContentSize(size)
    hostingView.frame = NSRect(origin: .zero, size: size)

    // Let subtle progress animations reach their final value before capture.
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    hostingView.layoutSubtreeIfNeeded()
    window.displayIfNeeded()

    guard
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width * 2),
        pixelsHigh: Int(size.height * 2),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    else {
      throw SnapshotError.renderFailed
    }
    bitmap.size = size
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
    window.orderOut(nil)

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
      throw SnapshotError.renderFailed
    }

    try FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try png.write(to: outputURL, options: .atomic)
  }
}

enum SnapshotError: Error {
  case renderFailed
}
