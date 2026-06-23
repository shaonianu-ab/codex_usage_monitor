import Foundation
import XCTest

@testable import CodexUsageMonitor

@MainActor
final class SettingsStoreTests: XCTestCase {
  func testUsesDocumentedDefaults() {
    let (defaults, suite) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: suite) }

    let store = SettingsStore(defaults: defaults)

    XCTAssertEqual(store.language, .english)
    XCTAssertEqual(store.theme, .system)
    XCTAssertEqual(store.refreshIntervalMinutes, 15)
    XCTAssertEqual(store.fiveHourThresholds, .init(redUpperBound: 20, yellowUpperBound: 50))
    XCTAssertEqual(store.weeklyThresholds, .init(redUpperBound: 20, yellowUpperBound: 50))
    XCTAssertEqual(store.creditDayThresholds, .init(redUpperBound: 3, yellowUpperBound: 7))
  }

  func testPersistsLanguageThemeRefreshIntervalAndThresholds() {
    let (defaults, suite) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: suite) }

    let first = SettingsStore(defaults: defaults)
    first.setLanguage(.simplifiedChinese)
    first.setTheme(.light)
    first.setRefreshIntervalMinutes(45)
    first.setFiveHourRed(12)
    first.setFiveHourYellow(42)
    first.setWeeklyRed(18)
    first.setWeeklyYellow(60)
    first.setCreditDaysRed(2)
    first.setCreditDaysYellow(9)

    let restored = SettingsStore(defaults: defaults)

    XCTAssertEqual(restored.language, .simplifiedChinese)
    XCTAssertEqual(restored.theme, .light)
    XCTAssertEqual(restored.refreshIntervalMinutes, 45)
    XCTAssertEqual(restored.refreshInterval, 45 * 60)
    XCTAssertEqual(restored.fiveHourThresholds, .init(redUpperBound: 12, yellowUpperBound: 42))
    XCTAssertEqual(restored.weeklyThresholds, .init(redUpperBound: 18, yellowUpperBound: 60))
    XCTAssertEqual(restored.creditDayThresholds, .init(redUpperBound: 2, yellowUpperBound: 9))
  }

  func testMaintainsStrictRedYellowOrdering() {
    let store = SettingsStore(previewLanguage: .english)

    store.setFiveHourRed(80)
    XCTAssertEqual(store.fiveHourThresholds, .init(redUpperBound: 49, yellowUpperBound: 50))

    store.setFiveHourYellow(10)
    XCTAssertEqual(store.fiveHourThresholds, .init(redUpperBound: 9, yellowUpperBound: 10))
  }

  func testResetKeepsLanguageThemeAndRefreshIntervalAndRestoresAllThresholds() {
    let store = SettingsStore(previewLanguage: .simplifiedChinese, theme: .light)
    store.setRefreshIntervalMinutes(45)
    store.setFiveHourRed(5)
    store.setWeeklyYellow(80)
    store.setCreditDaysYellow(30)

    store.resetThresholds()

    XCTAssertEqual(store.language, .simplifiedChinese)
    XCTAssertEqual(store.theme, .light)
    XCTAssertEqual(store.refreshIntervalMinutes, 45)
    XCTAssertEqual(store.fiveHourThresholds, SettingsStore.defaultFiveHour)
    XCTAssertEqual(store.weeklyThresholds, SettingsStore.defaultWeekly)
    XCTAssertEqual(store.creditDayThresholds, SettingsStore.defaultCredits)
  }

  func testClampsRefreshIntervalToDocumentedRange() {
    let store = SettingsStore(previewLanguage: .english)

    store.setRefreshIntervalMinutes(0)
    XCTAssertEqual(store.refreshIntervalMinutes, 1)

    store.setRefreshIntervalMinutes(2_000)
    XCTAssertEqual(store.refreshIntervalMinutes, 1_440)
  }

  private func makeDefaults() -> (UserDefaults, String) {
    let suite = "CodexUsageMonitorTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return (defaults, suite)
  }
}
