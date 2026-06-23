import AppKit
import SwiftUI

enum PopoverStyle {
  static let preferredWidth: CGFloat = 392
  static let minimumWidth: CGFloat = 320
  static let maximumWidth: CGFloat = 420
  static let maximumHeight: CGFloat = 620
  static let settingsHeight: CGFloat = 600

  static let panelPadding: CGFloat = 12
  static let panelCornerRadius: CGFloat = 18
  static let cardCornerRadius: CGFloat = 16
  static let resetCornerRadius: CGFloat = 14
  static let usageCardPadding: CGFloat = 18
  static let sectionSpacing: CGFloat = 14
  static let compactSpacing: CGFloat = 8
  static let footerSpacing: CGFloat = 10

  static let progressHeight: CGFloat = 8
  static let iconButtonSize: CGFloat = 30
  static let resetItemHeight: CGFloat = 86
  static let resetItemSpacing: CGFloat = 8
  static let emptyStateHeight: CGFloat = 52
  static let visibleResetItems = 2

  static func resetListHeight(for itemCount: Int) -> CGFloat {
    let visibleCount = min(max(itemCount, 1), visibleResetItems)
    return CGFloat(visibleCount) * resetItemHeight
      + CGFloat(max(visibleCount - 1, 0)) * resetItemSpacing
  }
}

extension NSColor {
  static let monitorWindowBackground = dynamicMonitorColor(
    light: rgb(244, 246, 248),
    dark: rgb(11, 17, 21)
  )

  fileprivate static func dynamicMonitorColor(light: NSColor, dark: NSColor) -> NSColor {
    NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
    }
  }

  fileprivate static func rgb(
    _ red: CGFloat,
    _ green: CGFloat,
    _ blue: CGFloat,
    alpha: CGFloat = 1
  ) -> NSColor {
    NSColor(
      srgbRed: red / 255,
      green: green / 255,
      blue: blue / 255,
      alpha: alpha
    )
  }
}

extension Color {
  static let monitorBackground = Color(nsColor: .monitorWindowBackground)
  static let monitorPanel = adaptive(
    light: .rgb(255, 255, 255),
    dark: .rgb(21, 28, 34)
  )
  static let monitorCard = adaptive(
    light: .rgb(250, 251, 252),
    dark: .rgb(19, 26, 32)
  )
  static let monitorCardHover = adaptive(
    light: .rgb(246, 248, 249),
    dark: .rgb(21, 29, 36)
  )

  static let monitorBorder = adaptive(
    light: NSColor.black.withAlphaComponent(0.09),
    dark: NSColor.white.withAlphaComponent(0.07)
  )
  static let monitorTextPrimary = adaptive(
    light: NSColor.black.withAlphaComponent(0.88),
    dark: NSColor.white.withAlphaComponent(0.90)
  )
  static let monitorTextSecondary = adaptive(
    light: NSColor.black.withAlphaComponent(0.62),
    dark: NSColor.white.withAlphaComponent(0.62)
  )
  static let monitorTextMuted = adaptive(
    light: NSColor.black.withAlphaComponent(0.44),
    dark: NSColor.white.withAlphaComponent(0.42)
  )

  static let monitorTrack = adaptive(
    light: NSColor.black.withAlphaComponent(0.09),
    dark: NSColor.white.withAlphaComponent(0.08)
  )
  static let monitorGreen = Color(red: 46 / 255, green: 219 / 255, blue: 98 / 255)
  static let monitorGreenText = adaptive(
    light: .rgb(14, 137, 58),
    dark: .rgb(53, 227, 111)
  )
  static let monitorGreenSoft = monitorGreen.opacity(0.14)
  static let monitorYellow = Color(red: 244 / 255, green: 190 / 255, blue: 67 / 255)
  static let monitorYellowText = adaptive(
    light: .rgb(143, 95, 0),
    dark: .rgb(250, 202, 86)
  )
  static let monitorYellowSoft = monitorYellow.opacity(0.14)
  static let monitorRed = Color(red: 244 / 255, green: 86 / 255, blue: 91 / 255)
  static let monitorRedText = adaptive(
    light: .rgb(190, 45, 52),
    dark: .rgb(255, 107, 112)
  )
  static let monitorRedSoft = monitorRed.opacity(0.14)

  static let monitorButtonBackground = adaptive(
    light: NSColor.black.withAlphaComponent(0.05),
    dark: NSColor.white.withAlphaComponent(0.06)
  )
  static let monitorButtonHover = adaptive(
    light: NSColor.black.withAlphaComponent(0.09),
    dark: NSColor.white.withAlphaComponent(0.10)
  )
  static let monitorSelectionBackground = adaptive(
    light: NSColor.black.withAlphaComponent(0.08),
    dark: NSColor.white.withAlphaComponent(0.16)
  )
  static let monitorErrorText = adaptive(
    light: .rgb(176, 43, 49, alpha: 0.88),
    dark: .rgb(255, 140, 140, alpha: 0.82)
  )
  static let monitorErrorSoft = adaptive(
    light: .rgb(218, 67, 72, alpha: 0.10),
    dark: .rgb(122, 31, 31, alpha: 0.20)
  )

  private static func adaptive(light: NSColor, dark: NSColor) -> Color {
    Color(nsColor: .dynamicMonitorColor(light: light, dark: dark))
  }
}

extension TrafficLightLevel {
  var fillColor: Color {
    switch self {
    case .red: .monitorRed
    case .yellow: .monitorYellow
    case .green: .monitorGreen
    }
  }

  var textColor: Color {
    switch self {
    case .red: .monitorRedText
    case .yellow: .monitorYellowText
    case .green: .monitorGreenText
    }
  }

  var softColor: Color {
    switch self {
    case .red: .monitorRedSoft
    case .yellow: .monitorYellowSoft
    case .green: .monitorGreenSoft
    }
  }
}

struct PopoverIconButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    IconButtonBody(configuration: configuration)
  }

  private struct IconButtonBody: View {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    let configuration: ButtonStyle.Configuration

    var body: some View {
      configuration.label
        .foregroundStyle(isEnabled ? Color.monitorTextSecondary : Color.monitorTextMuted)
        .background(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
              isHovering && isEnabled
                ? Color.monitorButtonHover : Color.monitorButtonBackground
            )
        )
        .scaleEffect(configuration.isPressed ? 0.96 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
  }
}

struct PopoverQuietButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    QuietButtonBody(configuration: configuration)
  }

  private struct QuietButtonBody: View {
    @State private var isHovering = false

    let configuration: ButtonStyle.Configuration

    var body: some View {
      configuration.label
        .foregroundStyle(isHovering ? Color.monitorTextPrimary : Color.monitorTextSecondary)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isHovering ? Color.monitorButtonBackground : Color.clear)
        )
        .scaleEffect(configuration.isPressed ? 0.96 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
  }
}
