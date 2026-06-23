import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
  case english
  case simplifiedChinese

  var id: String { rawValue }

  var locale: Locale {
    switch self {
    case .english:
      Locale(identifier: "en_US")
    case .simplifiedChinese:
      Locale(identifier: "zh_Hans_CN")
    }
  }
}

enum AppearanceTheme: String, CaseIterable, Identifiable, Sendable {
  case system
  case light
  case dark

  var id: String { rawValue }
}

enum TrafficLightLevel: Sendable, Equatable {
  case red
  case yellow
  case green
}

struct ColorThresholds: Sendable, Equatable {
  let redUpperBound: Int
  let yellowUpperBound: Int

  func level(for value: Double) -> TrafficLightLevel {
    if value <= Double(redUpperBound) {
      return .red
    }
    if value <= Double(yellowUpperBound) {
      return .yellow
    }
    return .green
  }
}
