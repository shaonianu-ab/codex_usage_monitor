import ServiceManagement

enum LaunchAtLoginStatus: Sendable, Equatable {
  case notRegistered
  case enabled
  case requiresApproval
  case unavailable

  var isRegistered: Bool {
    self == .enabled || self == .requiresApproval
  }
}

@MainActor
protocol LaunchAtLoginServicing: AnyObject {
  var status: LaunchAtLoginStatus { get }

  func register() throws
  func unregister() throws
  func openSystemSettings()
}

@MainActor
final class SystemLaunchAtLoginService: LaunchAtLoginServicing {
  private let service: SMAppService

  init(service: SMAppService = .mainApp) {
    self.service = service
  }

  var status: LaunchAtLoginStatus {
    switch service.status {
    case .notRegistered:
      .notRegistered
    case .enabled:
      .enabled
    case .requiresApproval:
      .requiresApproval
    case .notFound:
      .unavailable
    @unknown default:
      .unavailable
    }
  }

  func register() throws {
    try service.register()
  }

  func unregister() throws {
    try service.unregister()
  }

  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}

@MainActor
final class PreferredLaunchAtLoginService: LaunchAtLoginServicing {
  private let primary: any LaunchAtLoginServicing
  private let fallback: any LaunchAtLoginServicing

  init(
    primary: any LaunchAtLoginServicing = SystemLaunchAtLoginService(),
    fallback: any LaunchAtLoginServicing = LegacyLaunchAgentService()
  ) {
    self.primary = primary
    self.fallback = fallback
  }

  var status: LaunchAtLoginStatus {
    activeService.status
  }

  func register() throws {
    try activeService.register()
  }

  func unregister() throws {
    try activeService.unregister()
  }

  func openSystemSettings() {
    activeService.openSystemSettings()
  }

  private var activeService: any LaunchAtLoginServicing {
    primary.status == .unavailable ? fallback : primary
  }
}
