import AppKit
import SwiftUI

struct PopoverFooter: View {
  let store: UsageStore
  let settings: SettingsStore
  let openSettings: () -> Void

  private var localizer: AppLocalizer {
    AppLocalizer(language: settings.language)
  }

  var body: some View {
    VStack(spacing: 8) {
      Rectangle()
        .fill(Color.monitorBorder)
        .frame(height: 1)

      HStack(spacing: 12) {
        Text(localizer.format(.refreshSchedule, settings.refreshIntervalMinutes))
          .font(.system(size: 12, weight: .regular))
          .monospacedDigit()
          .foregroundStyle(Color.monitorTextMuted)
          .lineLimit(1)

        Spacer(minLength: 12)

        Button {
          openSettings()
        } label: {
          Label(localizer.text(.settings), systemImage: "gearshape")
        }
        .buttonStyle(PopoverQuietButtonStyle())
        .font(.system(size: 12, weight: .medium))
        .help(localizer.text(.settings))
        .accessibilityLabel(localizer.text(.settings))

        Button(localizer.text(.quit)) {
          store.stop()
          NSApplication.shared.terminate(nil)
        }
        .buttonStyle(PopoverQuietButtonStyle())
        .font(.system(size: 12, weight: .medium))
        .keyboardShortcut("q")
        .help(localizer.text(.quit))
        .accessibilityLabel(localizer.text(.quit))
      }
      .frame(height: 28)
      .padding(.horizontal, 4)
    }
  }
}
