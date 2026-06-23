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
        window: snapshot.primaryWindow,
        relativeTo: snapshot.updatedAt,
        thresholds: settings.fiveHourThresholds,
        localizer: localizer
      )
      .padding(.top, 16)

      QuotaBlock(
        title: localizer.text(.weekRemaining),
        window: snapshot.secondaryWindow,
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
  let window: RateLimitWindow?
  let relativeTo: Date
  let thresholds: ColorThresholds
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(title)
          .font(.system(size: 19, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(Color.monitorTextPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.9)

        Spacer(minLength: 12)

        Text(percentText)
          .font(.system(size: 20, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(Color.monitorTextPrimary)
      }

      UsageProgressBar(
        value: window?.remainingPercent ?? 0,
        color: thresholds.level(for: window?.remainingPercent ?? 0).fillColor,
        accessibilityLabel: localizer.text(.remainingUsage)
      )
      .frame(height: PopoverStyle.progressHeight)
      .padding(.top, 8)

      Text(resetText)
        .font(.system(size: 12.5, weight: .regular))
        .monospacedDigit()
        .foregroundStyle(Color.monitorTextMuted)
        .lineLimit(1)
        .padding(.top, 7)
        .help(resetHelp)
    }
  }

  private var percentText: String {
    guard let window else { return "—" }
    return "\(Int(window.remainingPercent.rounded()))%"
  }

  private var resetText: String {
    guard let resetAt = window?.resetAt else { return localizer.text(.usageDataUnavailable) }
    let timestamp = UsageFormatting.compactTimestamp(
      resetAt,
      relativeTo: relativeTo,
      language: localizer.language
    )
    return "\(localizer.text(.reset)) \(timestamp)"
  }

  private var resetHelp: String {
    guard let resetAt = window?.resetAt else { return localizer.text(.usageDataUnavailable) }
    return UsageFormatting.fullTimestamp(resetAt, language: localizer.language)
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
