import AppKit
import SwiftUI

@main
struct CodexUsageMonitorApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    MenuBarExtra {
      UsagePopoverView(
        store: appDelegate.store,
        settings: appDelegate.settings,
        launchAtLogin: appDelegate.launchAtLogin
      )
    } label: {
      Image(systemName: "chart.bar.fill")
        .accessibilityLabel("Codex Usage Monitor")
    }
    .menuBarExtraStyle(.window)
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  let store: UsageStore
  let settings: SettingsStore
  let launchAtLogin: LaunchAtLoginStore
  private let snapshotRequest: SnapshotRequest?

  override init() {
    let arguments = ProcessInfo.processInfo.arguments
    snapshotRequest = Self.snapshotRequest(from: arguments)
    if let snapshotRequest {
      store = UsageStore(preview: .preview)
      settings = SettingsStore(
        previewLanguage: snapshotRequest.language,
        theme: snapshotRequest.theme
      )
      launchAtLogin = LaunchAtLoginStore(previewStatus: .notRegistered)
    } else {
      let persistedSettings = SettingsStore()
      settings = persistedSettings
      store = UsageStore(
        refreshInterval: persistedSettings.refreshInterval,
        notificationSender: QuotaResetNotificationService()
      )
      launchAtLogin = LaunchAtLoginStore()
    }
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    if let snapshotRequest {
      Task { @MainActor in
        do {
          try SnapshotRenderer.write(
            store: store,
            settings: settings,
            launchAtLogin: launchAtLogin,
            screen: snapshotRequest.screen,
            to: URL(fileURLWithPath: snapshotRequest.path)
          )
        } catch {
          fputs("Unable to render preview snapshot.\n", stderr)
        }
        NSApp.terminate(nil)
      }
    } else {
      store.start()
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    store.stop()
  }

  private static func snapshotRequest(from arguments: [String]) -> SnapshotRequest? {
    let flags: [(String, PopoverScreen, AppLanguage, AppearanceTheme)] = [
      ("--render-snapshot", .dashboard, .english, .dark),
      ("--render-snapshot-light", .dashboard, .english, .light),
      ("--render-settings-snapshot", .settings, .english, .dark),
      ("--render-settings-snapshot-light", .settings, .english, .light),
      ("--render-settings-snapshot-zh", .settings, .simplifiedChinese, .dark),
      ("--render-settings-snapshot-light-zh", .settings, .simplifiedChinese, .light),
    ]
    for (flag, screen, language, theme) in flags {
      guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1)
      else { continue }
      return SnapshotRequest(
        path: arguments[index + 1],
        screen: screen,
        language: language,
        theme: theme
      )
    }
    return nil
  }
}

private struct SnapshotRequest {
  let path: String
  let screen: PopoverScreen
  let language: AppLanguage
  let theme: AppearanceTheme
}
