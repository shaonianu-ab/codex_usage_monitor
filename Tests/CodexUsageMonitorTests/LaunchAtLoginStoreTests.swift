import XCTest

@testable import CodexUsageMonitor

@MainActor
final class LaunchAtLoginStoreTests: XCTestCase {
  func testReadsTheSystemServiceAsTheSourceOfTruth() {
    let service = StubLaunchAtLoginService(status: .requiresApproval)
    let store = LaunchAtLoginStore(service: service)

    XCTAssertTrue(store.isOn)
    XCTAssertTrue(store.canToggle)
    XCTAssertTrue(store.requiresApproval)
    XCTAssertFalse(store.operationFailed)
  }

  func testRegistersAndUnregistersTheMainApp() {
    let service = StubLaunchAtLoginService(status: .notRegistered)
    let store = LaunchAtLoginStore(service: service)

    store.setEnabled(true)
    XCTAssertEqual(service.registerCallCount, 1)
    XCTAssertEqual(store.status, .enabled)
    XCTAssertTrue(store.isOn)

    store.setEnabled(false)
    XCTAssertEqual(service.unregisterCallCount, 1)
    XCTAssertEqual(store.status, .notRegistered)
    XCTAssertFalse(store.isOn)
  }

  func testFailedRegistrationRollsBackAndReportsTheFailure() {
    let service = StubLaunchAtLoginService(status: .notRegistered)
    service.registerError = StubError.failed
    let store = LaunchAtLoginStore(service: service)

    store.setEnabled(true)

    XCTAssertFalse(store.isOn)
    XCTAssertTrue(store.operationFailed)
  }

  func testApprovalStateIsRegisteredAndCanOpenSystemSettings() {
    let service = StubLaunchAtLoginService(status: .notRegistered)
    service.statusAfterRegister = .requiresApproval
    let store = LaunchAtLoginStore(service: service)

    store.setEnabled(true)
    store.openSystemSettings()

    XCTAssertTrue(store.isOn)
    XCTAssertTrue(store.requiresApproval)
    XCTAssertFalse(store.operationFailed)
    XCTAssertEqual(service.openSettingsCallCount, 1)
  }

  func testUnavailableServiceCannotBeChanged() {
    let service = StubLaunchAtLoginService(status: .unavailable)
    let store = LaunchAtLoginStore(service: service)

    store.setEnabled(true)

    XCTAssertFalse(store.canToggle)
    XCTAssertEqual(service.registerCallCount, 0)
  }

  func testPreferredServiceFallsBackWhenSMAppServiceIsUnavailable() {
    let primary = StubLaunchAtLoginService(status: .unavailable)
    let fallback = StubLaunchAtLoginService(status: .notRegistered)
    let preferred = PreferredLaunchAtLoginService(primary: primary, fallback: fallback)
    let store = LaunchAtLoginStore(service: preferred)

    store.setEnabled(true)

    XCTAssertEqual(primary.registerCallCount, 0)
    XCTAssertEqual(fallback.registerCallCount, 1)
    XCTAssertTrue(store.isOn)
  }
}

@MainActor
private final class StubLaunchAtLoginService: LaunchAtLoginServicing {
  var status: LaunchAtLoginStatus
  var statusAfterRegister: LaunchAtLoginStatus = .enabled
  var registerError: (any Error)?
  var unregisterError: (any Error)?
  private(set) var registerCallCount = 0
  private(set) var unregisterCallCount = 0
  private(set) var openSettingsCallCount = 0

  init(status: LaunchAtLoginStatus) {
    self.status = status
  }

  func register() throws {
    registerCallCount += 1
    if let registerError {
      throw registerError
    }
    status = statusAfterRegister
  }

  func unregister() throws {
    unregisterCallCount += 1
    if let unregisterError {
      throw unregisterError
    }
    status = .notRegistered
  }

  func openSystemSettings() {
    openSettingsCallCount += 1
  }
}

private enum StubError: Error {
  case failed
}
