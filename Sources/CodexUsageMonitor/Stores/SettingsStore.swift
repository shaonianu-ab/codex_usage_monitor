import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
  static let defaultFiveHour = ColorThresholds(redUpperBound: 20, yellowUpperBound: 50)
  static let defaultWeekly = ColorThresholds(redUpperBound: 20, yellowUpperBound: 50)
  static let defaultCredits = ColorThresholds(redUpperBound: 3, yellowUpperBound: 7)
  static let defaultRefreshIntervalMinutes = 15
  static let refreshIntervalRange = 1...1_440

  private(set) var language: AppLanguage
  private(set) var theme: AppearanceTheme
  private(set) var refreshIntervalMinutes: Int
  private(set) var fiveHourThresholds: ColorThresholds
  private(set) var weeklyThresholds: ColorThresholds
  private(set) var creditDayThresholds: ColorThresholds

  private let defaults: UserDefaults?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    self.language = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .english
    self.theme =
      AppearanceTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
    self.refreshIntervalMinutes = Self.loadRefreshInterval(defaults: defaults)
    self.fiveHourThresholds = Self.loadThresholds(
      defaults: defaults,
      redKey: Key.fiveHourRed,
      yellowKey: Key.fiveHourYellow,
      fallback: Self.defaultFiveHour,
      maximum: 100
    )
    self.weeklyThresholds = Self.loadThresholds(
      defaults: defaults,
      redKey: Key.weeklyRed,
      yellowKey: Key.weeklyYellow,
      fallback: Self.defaultWeekly,
      maximum: 100
    )
    self.creditDayThresholds = Self.loadThresholds(
      defaults: defaults,
      redKey: Key.creditDaysRed,
      yellowKey: Key.creditDaysYellow,
      fallback: Self.defaultCredits,
      maximum: 365
    )
  }

  init(
    previewLanguage: AppLanguage,
    theme: AppearanceTheme = .dark,
    refreshIntervalMinutes: Int = SettingsStore.defaultRefreshIntervalMinutes
  ) {
    self.defaults = nil
    self.language = previewLanguage
    self.theme = theme
    self.refreshIntervalMinutes = Self.validatedRefreshInterval(refreshIntervalMinutes)
    self.fiveHourThresholds = Self.defaultFiveHour
    self.weeklyThresholds = Self.defaultWeekly
    self.creditDayThresholds = Self.defaultCredits
  }

  func setLanguage(_ language: AppLanguage) {
    self.language = language
    defaults?.set(language.rawValue, forKey: Key.language)
  }

  func setTheme(_ theme: AppearanceTheme) {
    self.theme = theme
    defaults?.set(theme.rawValue, forKey: Key.theme)
  }

  var refreshInterval: TimeInterval {
    TimeInterval(refreshIntervalMinutes * 60)
  }

  func setRefreshIntervalMinutes(_ value: Int) {
    refreshIntervalMinutes = Self.validatedRefreshInterval(value)
    defaults?.set(refreshIntervalMinutes, forKey: Key.refreshIntervalMinutes)
  }

  func setFiveHourRed(_ value: Int) {
    fiveHourThresholds = thresholds(
      red: value,
      yellow: fiveHourThresholds.yellowUpperBound,
      maximum: 100
    )
    persist(fiveHourThresholds, redKey: Key.fiveHourRed, yellowKey: Key.fiveHourYellow)
  }

  func setFiveHourYellow(_ value: Int) {
    fiveHourThresholds = thresholds(
      red: fiveHourThresholds.redUpperBound,
      yellow: value,
      maximum: 100
    )
    persist(fiveHourThresholds, redKey: Key.fiveHourRed, yellowKey: Key.fiveHourYellow)
  }

  func setWeeklyRed(_ value: Int) {
    weeklyThresholds = thresholds(
      red: value,
      yellow: weeklyThresholds.yellowUpperBound,
      maximum: 100
    )
    persist(weeklyThresholds, redKey: Key.weeklyRed, yellowKey: Key.weeklyYellow)
  }

  func setWeeklyYellow(_ value: Int) {
    weeklyThresholds = thresholds(
      red: weeklyThresholds.redUpperBound,
      yellow: value,
      maximum: 100
    )
    persist(weeklyThresholds, redKey: Key.weeklyRed, yellowKey: Key.weeklyYellow)
  }

  func setCreditDaysRed(_ value: Int) {
    creditDayThresholds = thresholds(
      red: value,
      yellow: creditDayThresholds.yellowUpperBound,
      maximum: 365
    )
    persist(
      creditDayThresholds,
      redKey: Key.creditDaysRed,
      yellowKey: Key.creditDaysYellow
    )
  }

  func setCreditDaysYellow(_ value: Int) {
    creditDayThresholds = thresholds(
      red: creditDayThresholds.redUpperBound,
      yellow: value,
      maximum: 365
    )
    persist(
      creditDayThresholds,
      redKey: Key.creditDaysRed,
      yellowKey: Key.creditDaysYellow
    )
  }

  func resetThresholds() {
    fiveHourThresholds = Self.defaultFiveHour
    weeklyThresholds = Self.defaultWeekly
    creditDayThresholds = Self.defaultCredits
    persist(fiveHourThresholds, redKey: Key.fiveHourRed, yellowKey: Key.fiveHourYellow)
    persist(weeklyThresholds, redKey: Key.weeklyRed, yellowKey: Key.weeklyYellow)
    persist(
      creditDayThresholds,
      redKey: Key.creditDaysRed,
      yellowKey: Key.creditDaysYellow
    )
  }

  private func thresholds(red: Int, yellow: Int, maximum: Int) -> ColorThresholds {
    Self.validatedThresholds(red: red, yellow: yellow, maximum: maximum)
  }

  private func persist(_ value: ColorThresholds, redKey: String, yellowKey: String) {
    defaults?.set(value.redUpperBound, forKey: redKey)
    defaults?.set(value.yellowUpperBound, forKey: yellowKey)
  }

  private static func loadThresholds(
    defaults: UserDefaults,
    redKey: String,
    yellowKey: String,
    fallback: ColorThresholds,
    maximum: Int
  ) -> ColorThresholds {
    let red =
      defaults.object(forKey: redKey) == nil
      ? fallback.redUpperBound : defaults.integer(forKey: redKey)
    let yellow =
      defaults.object(forKey: yellowKey) == nil
      ? fallback.yellowUpperBound : defaults.integer(forKey: yellowKey)
    return validatedThresholds(red: red, yellow: yellow, maximum: maximum)
  }

  private static func validatedThresholds(
    red: Int,
    yellow: Int,
    maximum: Int
  ) -> ColorThresholds {
    let safeYellow = min(max(1, yellow), maximum)
    let safeRed = min(max(0, red), safeYellow - 1)
    return ColorThresholds(redUpperBound: safeRed, yellowUpperBound: safeYellow)
  }

  private static func loadRefreshInterval(defaults: UserDefaults) -> Int {
    guard defaults.object(forKey: Key.refreshIntervalMinutes) != nil else {
      return defaultRefreshIntervalMinutes
    }
    return validatedRefreshInterval(defaults.integer(forKey: Key.refreshIntervalMinutes))
  }

  private static func validatedRefreshInterval(_ value: Int) -> Int {
    min(max(value, refreshIntervalRange.lowerBound), refreshIntervalRange.upperBound)
  }

  private enum Key {
    static let language = "settings.language"
    static let theme = "settings.theme"
    static let refreshIntervalMinutes = "settings.refreshIntervalMinutes"
    static let fiveHourRed = "settings.fiveHour.red"
    static let fiveHourYellow = "settings.fiveHour.yellow"
    static let weeklyRed = "settings.weekly.red"
    static let weeklyYellow = "settings.weekly.yellow"
    static let creditDaysRed = "settings.creditDays.red"
    static let creditDaysYellow = "settings.creditDays.yellow"
  }
}
