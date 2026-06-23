import Foundation
import ServiceManagement

protocol LaunchctlRunning {
  func run(arguments: [String]) throws
}

struct ProcessLaunchctlRunner: LaunchctlRunning {
  func run(arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw LegacyLaunchAgentError.launchctlFailed(process.terminationStatus)
    }
  }
}

enum LegacyLaunchAgentError: Error, Equatable {
  case invalidBundle
  case launchctlFailed(Int32)
}

@MainActor
final class LegacyLaunchAgentService: LaunchAtLoginServicing {
  private let bundleURL: URL
  private let label: String
  private let launchAgentsDirectory: URL
  private let runner: any LaunchctlRunning
  private let userID: uid_t
  private let fileManager: FileManager

  init(
    bundleURL: URL = Bundle.main.bundleURL,
    bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "dev.example.CodexUsageMonitor",
    libraryDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library", isDirectory: true),
    runner: any LaunchctlRunning = ProcessLaunchctlRunner(),
    userID: uid_t = getuid(),
    fileManager: FileManager = .default
  ) {
    self.bundleURL = bundleURL.standardizedFileURL
    self.label = "\(bundleIdentifier).LaunchAtLogin"
    self.launchAgentsDirectory = libraryDirectory
      .appendingPathComponent("LaunchAgents", isDirectory: true)
    self.runner = runner
    self.userID = userID
    self.fileManager = fileManager
  }

  var status: LaunchAtLoginStatus {
    guard launchAgentMatchesCurrentBundle else { return .notRegistered }
    return SMAppService.statusForLegacyPlist(at: plistURL) == .requiresApproval
      ? .requiresApproval : .enabled
  }

  func register() throws {
    guard bundleURL.pathExtension == "app" else {
      throw LegacyLaunchAgentError.invalidBundle
    }

    try? runner.run(arguments: ["bootout", serviceTarget])
    try fileManager.createDirectory(
      at: launchAgentsDirectory,
      withIntermediateDirectories: true
    )
    try launchAgentData.write(to: plistURL, options: .atomic)

    do {
      try runner.run(arguments: ["bootstrap", domainTarget, plistURL.path])
    } catch {
      try? fileManager.removeItem(at: plistURL)
      throw error
    }
  }

  func unregister() throws {
    try? runner.run(arguments: ["bootout", serviceTarget])
    guard fileManager.fileExists(atPath: plistURL.path) else { return }
    try fileManager.removeItem(at: plistURL)
  }

  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }

  private var domainTarget: String {
    "gui/\(userID)"
  }

  private var serviceTarget: String {
    "\(domainTarget)/\(label)"
  }

  private var plistURL: URL {
    launchAgentsDirectory.appendingPathComponent("\(label).plist")
  }

  private var launchAgentData: Data {
    get throws {
      try PropertyListSerialization.data(
        fromPropertyList: [
          "Label": label,
          "ProgramArguments": ["/usr/bin/open", "-g", bundleURL.path],
          "RunAtLoad": true,
          "ProcessType": "Interactive",
          "LimitLoadToSessionType": "Aqua",
        ],
        format: .xml,
        options: 0
      )
    }
  }

  private var launchAgentMatchesCurrentBundle: Bool {
    guard
      let data = try? Data(contentsOf: plistURL),
      let propertyList = try? PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      ),
      let dictionary = propertyList as? [String: Any],
      let arguments = dictionary["ProgramArguments"] as? [String]
    else {
      return false
    }
    return arguments == ["/usr/bin/open", "-g", bundleURL.path]
  }
}
