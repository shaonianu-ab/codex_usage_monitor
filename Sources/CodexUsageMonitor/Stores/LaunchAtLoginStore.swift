import Observation

@MainActor
@Observable
final class LaunchAtLoginStore {
  private(set) var status: LaunchAtLoginStatus
  private(set) var operationFailed = false

  private let service: any LaunchAtLoginServicing

  init(service: any LaunchAtLoginServicing) {
    self.service = service
    self.status = service.status
  }

  convenience init() {
    self.init(service: PreferredLaunchAtLoginService())
  }

  convenience init(previewStatus: LaunchAtLoginStatus) {
    self.init(service: PreviewLaunchAtLoginService(status: previewStatus))
  }

  var isOn: Bool {
    status.isRegistered
  }

  var canToggle: Bool {
    status != .unavailable
  }

  var requiresApproval: Bool {
    status == .requiresApproval
  }

  var isUnavailable: Bool {
    status == .unavailable
  }

  func refresh() {
    status = service.status
    operationFailed = false
  }

  func setEnabled(_ enabled: Bool) {
    guard canToggle, enabled != isOn else { return }
    operationFailed = false

    do {
      if enabled {
        try service.register()
      } else {
        try service.unregister()
      }
    } catch {
      status = service.status
      operationFailed = status.isRegistered != enabled
      return
    }

    status = service.status
    operationFailed = status.isRegistered != enabled
  }

  func openSystemSettings() {
    service.openSystemSettings()
  }
}

@MainActor
private final class PreviewLaunchAtLoginService: LaunchAtLoginServicing {
  var status: LaunchAtLoginStatus

  init(status: LaunchAtLoginStatus) {
    self.status = status
  }

  func register() throws {
    status = .enabled
  }

  func unregister() throws {
    status = .notRegistered
  }

  func openSystemSettings() {}
}
