import Foundation
import XCTest

@testable import CodexUsageMonitor

@MainActor
final class LegacyLaunchAgentServiceTests: XCTestCase {
  func testRegisterWritesAndBootstrapsAUserLaunchAgent() throws {
    let temporaryDirectory = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    let bundleURL = temporaryDirectory.appendingPathComponent("Codex Usage Monitor.app")
    let runner = StubLaunchctlRunner()
    let service = LegacyLaunchAgentService(
      bundleURL: bundleURL,
      bundleIdentifier: "dev.example.CodexUsageMonitor",
      libraryDirectory: temporaryDirectory,
      runner: runner,
      userID: 501
    )

    try service.register()

    XCTAssertEqual(service.status, .enabled)
    XCTAssertEqual(
      runner.calls,
      [
        ["bootout", "gui/501/dev.example.CodexUsageMonitor.LaunchAtLogin"],
        [
          "bootstrap",
          "gui/501",
          temporaryDirectory
            .appendingPathComponent("LaunchAgents")
            .appendingPathComponent("dev.example.CodexUsageMonitor.LaunchAtLogin.plist")
            .path,
        ],
      ]
    )

    try service.unregister()
    XCTAssertEqual(service.status, .notRegistered)
    XCTAssertEqual(
      runner.calls.last,
      ["bootout", "gui/501/dev.example.CodexUsageMonitor.LaunchAtLogin"]
    )
  }

  func testFailedBootstrapRemovesTheLaunchAgentFile() {
    let temporaryDirectory = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    let runner = StubLaunchctlRunner(failingCommand: "bootstrap")
    let service = LegacyLaunchAgentService(
      bundleURL: temporaryDirectory.appendingPathComponent("Codex Usage Monitor.app"),
      bundleIdentifier: "dev.example.CodexUsageMonitor",
      libraryDirectory: temporaryDirectory,
      runner: runner,
      userID: 501
    )

    XCTAssertThrowsError(try service.register())
    XCTAssertEqual(service.status, .notRegistered)
  }

  private func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("CodexUsageMonitorTests-\(UUID().uuidString)")
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}

private final class StubLaunchctlRunner: LaunchctlRunning {
  private(set) var calls: [[String]] = []
  private let failingCommand: String?

  init(failingCommand: String? = nil) {
    self.failingCommand = failingCommand
  }

  func run(arguments: [String]) throws {
    calls.append(arguments)
    if arguments.first == failingCommand {
      throw LegacyLaunchAgentError.launchctlFailed(1)
    }
  }
}
