import SwiftUI

enum PopoverScreen: Sendable {
  case dashboard
  case settings
}

struct UsagePopoverView: View {
  static let preferredWidth = PopoverStyle.preferredWidth
  static let maximumHeight = PopoverStyle.maximumHeight

  let store: UsageStore
  let settings: SettingsStore
  let launchAtLogin: LaunchAtLoginStore
  var showsFooter = true

  @State private var screen: PopoverScreen

  init(
    store: UsageStore,
    settings: SettingsStore,
    launchAtLogin: LaunchAtLoginStore,
    showsFooter: Bool = true,
    initialScreen: PopoverScreen = .dashboard
  ) {
    self.store = store
    self.settings = settings
    self.launchAtLogin = launchAtLogin
    self.showsFooter = showsFooter
    _screen = State(initialValue: initialScreen)
  }

  var body: some View {
    Group {
      switch screen {
      case .dashboard:
        DashboardContent(
          store: store,
          settings: settings,
          showsFooter: showsFooter,
          openSettings: openSettings
        )
        .padding(PopoverStyle.panelPadding)
      case .settings:
        MonitorSettingsView(
          settings: settings,
          launchAtLogin: launchAtLogin,
          close: closeSettings
        )
          .frame(height: PopoverStyle.settingsHeight)
      }
    }
    .frame(width: Self.preferredWidth)
    .background(Color.monitorBackground)
    .background(
      PopoverWindowBackground(theme: settings.theme) {
        Task { await store.refresh() }
      }
    )
    .preferredColorScheme(settings.theme.colorScheme)
    .task {
      store.setAutomaticRefreshInterval(settings.refreshInterval)
      store.start()
    }
    .onChange(of: settings.refreshIntervalMinutes) { _, _ in
      store.setAutomaticRefreshInterval(settings.refreshInterval)
    }
  }

  private func openSettings() {
    withAnimation(.easeInOut(duration: 0.16)) {
      screen = .settings
    }
  }

  private func closeSettings() {
    withAnimation(.easeInOut(duration: 0.16)) {
      screen = .dashboard
    }
  }
}

private struct DashboardContent: View {
  let store: UsageStore
  let settings: SettingsStore
  let showsFooter: Bool
  let openSettings: () -> Void

  private var localizer: AppLocalizer {
    AppLocalizer(language: settings.language)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let snapshot = store.snapshot {
        UsageCard(snapshot: snapshot, settings: settings)

        ResetSection(store: store, snapshot: snapshot, settings: settings)
          .padding(.top, PopoverStyle.sectionSpacing)
      } else {
        PopoverInitialState(store: store, localizer: localizer)
      }

      if let message = store.message {
        PopoverMessage(message: localizer.message(message))
          .padding(.top, PopoverStyle.compactSpacing)
      }

      if showsFooter {
        PopoverFooter(store: store, settings: settings, openSettings: openSettings)
          .padding(.top, PopoverStyle.footerSpacing)
      }
    }
  }
}

private struct PopoverInitialState: View {
  let store: UsageStore
  let localizer: AppLocalizer

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "chart.bar.fill")
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(Color.monitorGreen)

      Text(
        store.isRefreshing
          ? localizer.text(.loadingUsage) : localizer.text(.usageUnavailableYet)
      )
      .font(.system(size: 14, weight: .medium))
      .foregroundStyle(Color.monitorTextPrimary)
      .multilineTextAlignment(.center)

      if store.isRefreshing {
        ProgressView()
          .controlSize(.small)
      } else {
        Button(localizer.text(.retry)) {
          Task { await store.refresh() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel(localizer.text(.retryRefresh))
      }
    }
    .frame(maxWidth: .infinity, minHeight: 164)
    .padding(PopoverStyle.usageCardPadding)
    .background(Color.monitorPanel)
    .clipShape(
      RoundedRectangle(cornerRadius: PopoverStyle.cardCornerRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: PopoverStyle.cardCornerRadius, style: .continuous)
        .stroke(Color.monitorBorder, lineWidth: 1)
    }
  }
}

private struct PopoverMessage: View {
  let message: String

  var body: some View {
    Label {
      Text(message)
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: "exclamationmark.circle")
    }
    .font(.system(size: 12, weight: .regular))
    .foregroundStyle(Color.monitorErrorText)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color.monitorErrorSoft)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(Color.monitorErrorText.opacity(0.14), lineWidth: 1)
    }
  }
}
