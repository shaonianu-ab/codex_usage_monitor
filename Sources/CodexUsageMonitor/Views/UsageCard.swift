import SwiftUI

struct UsageCard: View {
  let snapshot: UsageSnapshot
  let settings: SettingsStore

  private var localizer: AppLocalizer {
    AppLocalizer(language: settings.language)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(planText)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.monitorTextSecondary)
          .lineLimit(1)

        Spacer(minLength: 12)

        Text(UsageFormatting.clock(snapshot.updatedAt, language: settings.language))
          .font(.system(size: 14, weight: .medium))
          .monospacedDigit()
          .foregroundStyle(Color.monitorTextSecondary)
          .help(
            "\(localizer.text(.lastUpdated)) \(UsageFormatting.fullTimestamp(snapshot.updatedAt, language: settings.language))"
          )
      }

      QuotaBlock(
        title: localizer.text(.fiveHourRemaining),
        inactiveTitle: localizer.text(.fiveHourLimit),
        state: snapshot.fiveHourQuota,
        relativeTo: snapshot.updatedAt,
        thresholds: settings.fiveHourThresholds,
        localizer: localizer
      )
      .padding(.top, 16)

      QuotaBlock(
        title: localizer.text(.weekRemaining),
        inactiveTitle: localizer.text(.weeklyLimit),
        state: snapshot.weeklyQuota,
        relativeTo: snapshot.updatedAt,
        thresholds: settings.weeklyThresholds,
        localizer: localizer
      )
      .padding(.top, 16)
    }
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

  private var planText: String {
    let plan = UsageFormatting.plan(snapshot.planType)
    return plan == "unknown" ? localizer.text(.unknown) : plan
  }
}

private struct QuotaBlock: View {
  let title: String
  let inactiveTitle: String
  let state: UsageQuotaState
  let relativeTo: Date
  let thresholds: ColorThresholds
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(displayedTitle)
          .font(.system(size: 19, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(Color.monitorTextPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.9)

        Spacer(minLength: 12)

        quotaValue
      }

      quotaDetails
    }
  }

  @ViewBuilder
  private var quotaValue: some View {
    switch state {
    case .limited(let window):
      Text("\(Int(window.remainingPercent.rounded()))%")
        .font(.system(size: 20, weight: .bold))
        .monospacedDigit()
        .foregroundStyle(Color.monitorTextPrimary)
    case .unlimited:
      Label(localizer.text(.noActiveLimit), systemImage: "infinity")
        .font(.system(size: 12.5, weight: .semibold))
        .foregroundStyle(Color.monitorGreenText)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.monitorGreenSoft)
        .clipShape(Capsule())
    case .unavailable:
      Text("—")
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(Color.monitorTextPrimary)
        .accessibilityLabel(localizer.text(.usageDataUnavailable))
    }
  }

  @ViewBuilder
  private var quotaDetails: some View {
    switch state {
    case .limited(let window):
      UsageProgressBar(
        value: window.remainingPercent,
        color: thresholds.level(for: window.remainingPercent).fillColor,
        accessibilityLabel: localizer.text(.remainingUsage)
      )
      .frame(height: PopoverStyle.progressHeight)
      .padding(.top, 8)

      Text(resetText(for: window))
        .font(.system(size: 12.5, weight: .regular))
        .monospacedDigit()
        .foregroundStyle(Color.monitorTextMuted)
        .lineLimit(1)
        .padding(.top, 7)
        .help(resetHelp(for: window))
    case .unlimited:
      statusDescription(localizer.text(.noActiveLimitDescription))
    case .unavailable:
      statusDescription(localizer.text(.usageDataUnavailable))
    }
  }

  private var displayedTitle: String {
    switch state {
    case .limited: title
    case .unlimited, .unavailable: inactiveTitle
    }
  }

  private func resetText(for window: RateLimitWindow) -> String {
    guard let resetAt = window.resetAt else { return localizer.text(.usageDataUnavailable) }
    let timestamp = UsageFormatting.compactTimestamp(
      resetAt,
      relativeTo: relativeTo,
      language: localizer.language
    )
    return "\(localizer.text(.reset)) \(timestamp)"
  }

  private func resetHelp(for window: RateLimitWindow) -> String {
    guard let resetAt = window.resetAt else { return localizer.text(.usageDataUnavailable) }
    return UsageFormatting.fullTimestamp(resetAt, language: localizer.language)
  }

  private func statusDescription(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 12.5, weight: .regular))
      .foregroundStyle(Color.monitorTextMuted)
      .lineLimit(1)
      .padding(.top, 7)
  }
}

private struct UsageProgressBar: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var displayedValue = 0.0

  let value: Double
  let color: Color
  let accessibilityLabel: String

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.monitorTrack)

        Capsule()
          .fill(color)
          .frame(width: proxy.size.width * clamped(displayedValue) / 100)
      }
    }
    .onAppear {
      updateDisplayedValue(to: value, animated: !reduceMotion)
    }
    .onChange(of: value) { _, newValue in
      updateDisplayedValue(to: newValue, animated: !reduceMotion)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityValue("\(Int(clamped(value).rounded())) percent")
  }

  private func clamped(_ value: Double) -> Double {
    min(100, max(0, value))
  }

  private func updateDisplayedValue(to newValue: Double, animated: Bool) {
    if animated {
      withAnimation(.easeOut(duration: 0.24)) {
        displayedValue = clamped(newValue)
      }
    } else {
      displayedValue = clamped(newValue)
    }
  }
}
