import Foundation
import Testing

@testable import CodexUsageMonitor

struct LocalizationAndThresholdTests {
  @Test func thresholdBoundariesUseInclusiveRedAndYellowMaximums() {
    let thresholds = ColorThresholds(redUpperBound: 20, yellowUpperBound: 50)

    #expect(thresholds.level(for: 20) == .red)
    #expect(thresholds.level(for: 20.1) == .yellow)
    #expect(thresholds.level(for: 50) == .yellow)
    #expect(thresholds.level(for: 50.1) == .green)
  }

  @Test func localizesStaticAndDynamicErrors() {
    let english = AppLocalizer(language: .english)
    let chinese = AppLocalizer(language: .simplifiedChinese)
    let warning = UsageMessage.remote([
      RemoteWarning(endpoint: .usage, error: .httpStatus(429))
    ])

    #expect(english.text(.settings) == "Settings")
    #expect(chinese.text(.settings) == "设置")
    #expect(english.text(.themeSystem) == "System")
    #expect(chinese.text(.themeSystem) == "跟随系统")
    #expect(english.text(.launchAtLogin) == "Launch at login")
    #expect(chinese.text(.launchAtLogin) == "开机自启")
    #expect(chinese.text(.openLoginItemsSettings) == "打开登录项设置")
    #expect(english.format(.refreshSchedule, 45) == "Refreshes every 45 min")
    #expect(chinese.format(.refreshSchedule, 45) == "每 45 分钟刷新")
    #expect(english.message(warning) == "Usage endpoint: Request failed (HTTP 429).")
    #expect(chinese.message(warning) == "用量接口: 请求失败（HTTP 429）。")
  }

  @Test func chineseTimestampUsesLocalizedMonthAndDay() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let reference = date(2026, 6, 23, calendar: calendar)
    let value = date(2026, 7, 12, 10, 33, calendar: calendar)

    #expect(
      UsageFormatting.compactTimestamp(
        value,
        relativeTo: reference,
        calendar: calendar,
        language: .simplifiedChinese
      ) == "7月12日 10:33"
    )
  }

  @Test func remainingDaysUsesCalendarDayBoundaries() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let reference = date(2026, 6, 23, 23, 50, calendar: calendar)
    let expiration = date(2026, 6, 26, 0, 5, calendar: calendar)

    #expect(
      UsageFormatting.remainingDays(
        until: expiration,
        relativeTo: reference,
        calendar: calendar
      ) == 3
    )
  }

  private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 0,
    _ minute: Int = 0,
    calendar: Calendar
  ) -> Date {
    var components = DateComponents()
    components.calendar = calendar
    components.timeZone = calendar.timeZone
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return components.date!
  }
}
