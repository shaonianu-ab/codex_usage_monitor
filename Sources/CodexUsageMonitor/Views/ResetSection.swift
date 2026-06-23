import SwiftUI

struct ResetSection: View {
  let store: UsageStore
  let snapshot: UsageSnapshot
  let settings: SettingsStore

  private var localizer: AppLocalizer {
    AppLocalizer(language: settings.language)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 8) {
            Text(localizer.text(.rateLimitResets))
              .font(.system(size: 13, weight: .bold))
              .tracking(0.5)
              .foregroundStyle(Color.monitorTextSecondary)
              .lineLimit(1)

            Text("\(snapshot.availableCount)")
              .font(.system(size: 12, weight: .semibold))
              .monospacedDigit()
              .foregroundStyle(Color.monitorTextPrimary)
              .padding(.horizontal, 7)
              .frame(minWidth: 20, minHeight: 20)
              .background(Color.monitorButtonBackground)
              .clipShape(Capsule())
          }

          Text(nextExpirationText)
            .font(.system(size: 12, weight: .regular))
            .monospacedDigit()
            .foregroundStyle(Color.monitorTextMuted)
            .lineLimit(1)
            .help(nextExpirationHelp)
        }

        Spacer(minLength: 12)

        Button {
          Task { await store.refresh() }
        } label: {
          RefreshGlyph(isRefreshing: store.isRefreshing)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: PopoverStyle.iconButtonSize, height: PopoverStyle.iconButtonSize)
        }
        .buttonStyle(PopoverIconButtonStyle())
        .disabled(store.isRefreshing)
        .help(
          store.isRefreshing
            ? localizer.text(.refreshingUsage) : localizer.text(.refreshNow)
        )
        .accessibilityLabel(localizer.text(.refresh))
      }
      .padding(.horizontal, 2)

      if snapshot.credits.isEmpty {
        Text(localizer.text(.noRateLimitResets))
          .font(.system(size: 12.5, weight: .regular))
          .foregroundStyle(Color.monitorTextMuted)
          .frame(maxWidth: .infinity, minHeight: PopoverStyle.emptyStateHeight)
          .background(Color.monitorCard)
          .clipShape(
            RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
          )
          .overlay {
            RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
              .stroke(Color.monitorBorder.opacity(0.72), lineWidth: 1)
          }
          .padding(.top, 10)
      } else {
        ScrollView(.vertical) {
          LazyVStack(spacing: PopoverStyle.resetItemSpacing) {
            ForEach(snapshot.credits) { credit in
              ResetItem(
                credit: credit,
                relativeTo: snapshot.updatedAt,
                thresholds: settings.creditDayThresholds,
                localizer: localizer
              )
            }
          }
        }
        .scrollIndicators(.hidden)
        .frame(height: PopoverStyle.resetListHeight(for: snapshot.credits.count))
        .padding(.top, 10)
      }
    }
  }

  private var nextExpiration: Date? {
    snapshot.credits.map(\.expiresAt).min()
  }

  private var nextExpirationText: String {
    guard let nextExpiration else { return "\(localizer.text(.nextExpires)) —" }
    let timestamp = UsageFormatting.compactTimestamp(
      nextExpiration,
      relativeTo: snapshot.updatedAt,
      language: settings.language
    )
    return "\(localizer.text(.nextExpires)) \(timestamp)"
  }

  private var nextExpirationHelp: String {
    guard let nextExpiration else { return localizer.text(.noUpcomingExpiration) }
    return UsageFormatting.fullTimestamp(nextExpiration, language: settings.language)
  }
}

private struct ResetItem: View {
  @State private var isHovering = false

  let credit: RateLimitCredit
  let relativeTo: Date
  let thresholds: ColorThresholds
  let localizer: AppLocalizer

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(statusText)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(statusForeground)
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(statusBackground)
        .clipShape(Capsule())

      VStack(spacing: 4) {
        ResetMetadataRow(
          label: localizer.text(.granted),
          date: credit.grantedAt,
          relativeTo: relativeTo,
          language: localizer.language
        )
        ResetMetadataRow(
          label: localizer.text(.expires),
          date: credit.expiresAt,
          relativeTo: relativeTo,
          language: localizer.language
        )
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, minHeight: PopoverStyle.resetItemHeight, alignment: .leading)
    .background(isHovering ? Color.monitorCardHover : Color.monitorCard)
    .clipShape(
      RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: PopoverStyle.resetCornerRadius, style: .continuous)
        .stroke(Color.monitorBorder.opacity(0.72), lineWidth: 1)
    }
    .contentShape(Rectangle())
    .onHover { isHovering = $0 }
    .animation(.easeOut(duration: 0.12), value: isHovering)
    .accessibilityElement(children: .combine)
  }

  private var statusText: String {
    guard !credit.isAvailable else { return localizer.text(.available) }
    switch credit.status.lowercased() {
    case "redeemed": return localizer.text(.redeemed)
    case "expired": return localizer.text(.expired)
    case "unavailable": return localizer.text(.unavailable)
    default: return credit.status.capitalized
    }
  }

  private var statusForeground: Color {
    credit.isAvailable ? expirationLevel.textColor : .monitorTextSecondary
  }

  private var statusBackground: Color {
    credit.isAvailable ? expirationLevel.softColor : .monitorButtonBackground
  }

  private var expirationLevel: TrafficLightLevel {
    let remainingDays = UsageFormatting.remainingDays(
      until: credit.expiresAt,
      relativeTo: relativeTo
    )
    return thresholds.level(for: Double(remainingDays))
  }
}

private struct ResetMetadataRow: View {
  let label: String
  let date: Date
  let relativeTo: Date
  let language: AppLanguage

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(label)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(Color.monitorTextMuted)
        .frame(width: 62, alignment: .leading)

      Text(
        UsageFormatting.compactTimestamp(
          date,
          relativeTo: relativeTo,
          language: language
        )
      )
      .font(.system(size: 13, weight: .medium))
      .monospacedDigit()
      .foregroundStyle(Color.monitorTextSecondary)
      .lineLimit(1)
      .truncationMode(.tail)
      .help(UsageFormatting.fullTimestamp(date, language: language))

      Spacer(minLength: 0)
    }
  }
}

private struct RefreshGlyph: View {
  let isRefreshing: Bool

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30, paused: !isRefreshing)) { timeline in
      Image(systemName: "arrow.clockwise")
        .rotationEffect(.degrees(rotation(at: timeline.date)))
    }
  }

  private func rotation(at date: Date) -> Double {
    guard isRefreshing else { return 0 }
    let progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.8) / 0.8
    return progress * 360
  }
}
