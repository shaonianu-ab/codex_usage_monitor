import SwiftUI

struct MonitorSettingsView: View {
  let settings: SettingsStore
  let launchAtLogin: LaunchAtLoginStore
  let close: () -> Void

  private var localizer: AppLocalizer {
    AppLocalizer(language: settings.language)
  }

  var body: some View {
    VStack(spacing: 0) {
      header

      Rectangle()
        .fill(Color.monitorBorder)
        .frame(height: 1)
        .padding(.horizontal, PopoverStyle.panelPadding)

      ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 12) {
          LanguageSettingsCard(settings: settings, localizer: localizer)
          AppearanceSettingsCard(settings: settings, localizer: localizer)
          LaunchAtLoginSettingsCard(store: launchAtLogin, localizer: localizer)
          RefreshSettingsCard(settings: settings, localizer: localizer)
          ThresholdSettingsCard(
            settings: settings,
            metric: .fiveHour,
            localizer: localizer
          )
          ThresholdSettingsCard(
            settings: settings,
            metric: .weekly,
            localizer: localizer
          )
          ThresholdSettingsCard(
            settings: settings,
            metric: .creditDays,
            localizer: localizer
          )
        }
        .padding(PopoverStyle.panelPadding)
      }
    }
    .task {
      launchAtLogin.refresh()
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      Button(action: close) {
        Image(systemName: "chevron.left")
          .font(.system(size: 13, weight: .semibold))
          .frame(width: PopoverStyle.iconButtonSize, height: PopoverStyle.iconButtonSize)
      }
      .buttonStyle(PopoverIconButtonStyle())
      .help(localizer.text(.back))
      .accessibilityLabel(localizer.text(.back))

      Text(localizer.text(.settingsTitle))
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Spacer()

      Button(localizer.text(.resetDefaults)) {
        settings.resetThresholds()
      }
      .buttonStyle(PopoverQuietButtonStyle())
      .font(.system(size: 12, weight: .medium))
      .help(localizer.text(.resetDefaults))
    }
    .padding(.horizontal, PopoverStyle.panelPadding)
    .frame(height: 48)
  }
}

private struct LaunchAtLoginSettingsCard: View {
  let store: LaunchAtLoginStore
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(localizer.text(.launchAtLogin), systemImage: "power")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Text(localizer.text(.launchAtLoginDescription))
        .font(.system(size: 11.5, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)
        .fixedSize(horizontal: false, vertical: true)

      Divider()
        .overlay(Color.monitorBorder)

      Toggle(
        localizer.text(.launchAtLoginToggle),
        isOn: Binding(
          get: { store.isOn },
          set: { store.setEnabled($0) }
        )
      )
      .font(.system(size: 12, weight: .regular))
      .foregroundStyle(Color.monitorTextSecondary)
      .toggleStyle(.switch)
      .controlSize(.small)
      .tint(Color.monitorGreen)
      .disabled(!store.canToggle)

      if let statusMessage {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Label(statusMessage.text, systemImage: statusMessage.icon)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(statusMessage.color)
            .fixedSize(horizontal: false, vertical: true)

          Spacer(minLength: 8)

          if store.requiresApproval {
            Button(localizer.text(.openLoginItemsSettings)) {
              store.openSystemSettings()
            }
            .buttonStyle(PopoverQuietButtonStyle())
            .font(.system(size: 11, weight: .medium))
          }
        }
      }
    }
    .settingsCard()
  }

  private var statusMessage: (text: String, icon: String, color: Color)? {
    if store.operationFailed {
      return (
        localizer.text(.launchAtLoginOperationFailed),
        "exclamationmark.circle",
        .monitorRedText
      )
    }
    if store.requiresApproval {
      return (
        localizer.text(.launchAtLoginRequiresApproval),
        "exclamationmark.triangle",
        .monitorYellowText
      )
    }
    if store.isUnavailable {
      return (
        localizer.text(.launchAtLoginUnavailable),
        "exclamationmark.circle",
        .monitorRedText
      )
    }
    return nil
  }
}

private struct RefreshSettingsCard: View {
  let settings: SettingsStore
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(localizer.text(.automaticRefresh), systemImage: "clock.arrow.circlepath")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Text(localizer.text(.automaticRefreshDescription))
        .font(.system(size: 11.5, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)
        .fixedSize(horizontal: false, vertical: true)

      Divider()
        .overlay(Color.monitorBorder)

      HStack(spacing: 10) {
        Text(localizer.text(.refreshInterval))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(Color.monitorTextSecondary)

        Spacer()

        Text(
          localizer.format(.refreshIntervalValue, settings.refreshIntervalMinutes)
        )
        .font(.system(size: 12, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(Color.monitorTextPrimary)

        Stepper(
          "",
          value: Binding(
            get: { settings.refreshIntervalMinutes },
            set: { settings.setRefreshIntervalMinutes($0) }
          ),
          in: SettingsStore.refreshIntervalRange
        )
        .labelsHidden()
        .controlSize(.small)
        .accessibilityLabel(localizer.text(.refreshInterval))
        .accessibilityValue(
          localizer.format(.refreshIntervalValue, settings.refreshIntervalMinutes)
        )
      }
    }
    .settingsCard()
  }
}

private struct AppearanceSettingsCard: View {
  let settings: SettingsStore
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(localizer.text(.appearance), systemImage: "circle.lefthalf.filled")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Text(localizer.text(.appearanceDescription))
        .font(.system(size: 11.5, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)

      ThemeSegmentedControl(settings: settings, localizer: localizer)
    }
    .settingsCard()
  }
}

private struct ThemeSegmentedControl: View {
  let settings: SettingsStore
  let localizer: AppLocalizer

  var body: some View {
    HStack(spacing: 2) {
      option(theme: .system, title: localizer.text(.themeSystem), icon: "circle.lefthalf.filled")
      option(theme: .light, title: localizer.text(.themeLight), icon: "sun.max")
      option(theme: .dark, title: localizer.text(.themeDark), icon: "moon")
    }
    .padding(2)
    .background(Color.monitorBackground.opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 7, style: .continuous)
        .stroke(Color.monitorBorder.opacity(0.9), lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(localizer.text(.appearance))
  }

  private func option(theme: AppearanceTheme, title: String, icon: String) -> some View {
    let isSelected = settings.theme == theme

    return Button {
      withAnimation(.easeOut(duration: 0.12)) {
        settings.setTheme(theme)
      }
    } label: {
      Label(title, systemImage: icon)
        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
        .foregroundStyle(
          isSelected ? Color.monitorTextPrimary : Color.monitorTextSecondary
        )
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background {
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(isSelected ? Color.monitorSelectionBackground : Color.clear)
        }
        .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct LanguageSettingsCard: View {
  let settings: SettingsStore
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(localizer.text(.language), systemImage: "globe")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Text(localizer.text(.languageDescription))
        .font(.system(size: 11.5, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)

      LanguageSegmentedControl(settings: settings, localizer: localizer)
    }
    .settingsCard()
  }
}

private struct LanguageSegmentedControl: View {
  let settings: SettingsStore
  let localizer: AppLocalizer

  var body: some View {
    HStack(spacing: 2) {
      option(title: "English", language: .english)
      option(title: "中文", language: .simplifiedChinese)
    }
    .padding(2)
    .background(Color.monitorBackground.opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 7, style: .continuous)
        .stroke(Color.monitorBorder.opacity(0.9), lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(localizer.text(.language))
  }

  private func option(title: String, language: AppLanguage) -> some View {
    let isSelected = settings.language == language

    return Button {
      withAnimation(.easeOut(duration: 0.12)) {
        settings.setLanguage(language)
      }
    } label: {
      Text(title)
        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
        .foregroundStyle(
          isSelected ? Color.monitorTextPrimary : Color.monitorTextSecondary
        )
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background {
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(isSelected ? Color.monitorSelectionBackground : Color.clear)
        }
        .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct ThresholdSettingsCard: View {
  let settings: SettingsStore
  let metric: ThresholdMetric
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.monitorTextPrimary)

      Text(description)
        .font(.system(size: 11.5, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)
        .fixedSize(horizontal: false, vertical: true)

      Divider()
        .overlay(Color.monitorBorder)

      thresholdRow(bound: .red)
      thresholdRow(bound: .yellow)

      ThresholdLegend(
        thresholds: thresholds,
        unit: unit,
        localizer: localizer
      )
    }
    .settingsCard()
  }

  private var thresholds: ColorThresholds {
    switch metric {
    case .fiveHour: settings.fiveHourThresholds
    case .weekly: settings.weeklyThresholds
    case .creditDays: settings.creditDayThresholds
    }
  }

  private var title: String {
    switch metric {
    case .fiveHour: localizer.text(.fiveHourThresholds)
    case .weekly: localizer.text(.weeklyThresholds)
    case .creditDays: localizer.text(.creditDayThresholds)
    }
  }

  private var description: String {
    metric == .creditDays
      ? localizer.text(.creditThresholdDescription)
      : localizer.text(.quotaThresholdDescription)
  }

  private var maximum: Int {
    metric == .creditDays ? 365 : 100
  }

  private var unit: ThresholdUnit {
    metric == .creditDays ? .days : .percent
  }

  private func thresholdRow(bound: ThresholdBound) -> some View {
    let value = bound == .red ? thresholds.redUpperBound : thresholds.yellowUpperBound
    let level: TrafficLightLevel = bound == .red ? .red : .yellow
    let title =
      bound == .red
      ? localizer.text(.redUpperBound) : localizer.text(.yellowUpperBound)

    return HStack(spacing: 8) {
      Circle()
        .fill(level.fillColor)
        .frame(width: 7, height: 7)

      Text(title)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(Color.monitorTextSecondary)

      Spacer()

      Text("≤ \(unit.valueText(value, localizer: localizer))")
        .font(.system(size: 12, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(level.textColor)
        .frame(minWidth: 58, alignment: .trailing)

      Button {
        change(bound: bound, delta: -1)
      } label: {
        Image(systemName: "minus")
          .font(.system(size: 10, weight: .semibold))
          .frame(width: 22, height: 22)
      }
      .buttonStyle(PopoverIconButtonStyle())
      .disabled(!canChange(bound: bound, delta: -1))
      .accessibilityLabel("\(title) −")

      Button {
        change(bound: bound, delta: 1)
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 10, weight: .semibold))
          .frame(width: 22, height: 22)
      }
      .buttonStyle(PopoverIconButtonStyle())
      .disabled(!canChange(bound: bound, delta: 1))
      .accessibilityLabel("\(title) +")
    }
    .accessibilityElement(children: .contain)
  }

  private func canChange(bound: ThresholdBound, delta: Int) -> Bool {
    switch bound {
    case .red:
      let candidate = thresholds.redUpperBound + delta
      return candidate >= 0 && candidate < thresholds.yellowUpperBound
    case .yellow:
      let candidate = thresholds.yellowUpperBound + delta
      return candidate > thresholds.redUpperBound && candidate <= maximum
    }
  }

  private func change(bound: ThresholdBound, delta: Int) {
    guard canChange(bound: bound, delta: delta) else { return }
    let current = bound == .red ? thresholds.redUpperBound : thresholds.yellowUpperBound
    let value = current + delta

    switch (metric, bound) {
    case (.fiveHour, .red): settings.setFiveHourRed(value)
    case (.fiveHour, .yellow): settings.setFiveHourYellow(value)
    case (.weekly, .red): settings.setWeeklyRed(value)
    case (.weekly, .yellow): settings.setWeeklyYellow(value)
    case (.creditDays, .red): settings.setCreditDaysRed(value)
    case (.creditDays, .yellow): settings.setCreditDaysYellow(value)
    }
  }
}

private struct ThresholdLegend: View {
  let thresholds: ColorThresholds
  let unit: ThresholdUnit
  let localizer: AppLocalizer

  var body: some View {
    HStack(spacing: 6) {
      legendItem(
        level: .red,
        title: localizer.text(.red),
        range: "0–\(unit.valueText(thresholds.redUpperBound, localizer: localizer))"
      )
      legendItem(
        level: .yellow,
        title: localizer.text(.yellow),
        range:
          "\(thresholds.redUpperBound + 1)–\(unit.valueText(thresholds.yellowUpperBound, localizer: localizer))"
      )
      legendItem(
        level: .green,
        title: localizer.text(.green),
        range: ">\(unit.valueText(thresholds.yellowUpperBound, localizer: localizer))"
      )
    }
  }

  private func legendItem(level: TrafficLightLevel, title: String, range: String) -> some View {
    VStack(spacing: 2) {
      Text(title)
        .font(.system(size: 10.5, weight: .semibold))
      Text(range)
        .font(.system(size: 9.5, weight: .medium))
        .monospacedDigit()
    }
    .foregroundStyle(level.textColor)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 5)
    .background(level.softColor)
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
  }
}

private enum ThresholdMetric {
  case fiveHour
  case weekly
  case creditDays
}

private enum ThresholdBound {
  case red
  case yellow
}

private enum ThresholdUnit {
  case percent
  case days

  func valueText(_ value: Int, localizer: AppLocalizer) -> String {
    switch self {
    case .percent:
      "\(value)\(localizer.text(.percent))"
    case .days:
      localizer.language == .simplifiedChinese
        ? "\(value)\(localizer.text(.days))"
        : "\(value) \(localizer.text(.days))"
    }
  }
}

private struct SettingsCardModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.monitorCard)
      .clipShape(
        RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
          .stroke(Color.monitorBorder.opacity(0.72), lineWidth: 1)
      }
  }
}

extension View {
  fileprivate func settingsCard() -> some View {
    modifier(SettingsCardModifier())
  }
}
