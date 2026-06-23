import Foundation
import Testing

@testable import CodexUsageMonitor

struct UsageFormattingTests {
  private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  @Test func compactTimestampOmitsYearAndSecondsWithinSameYear() {
    let reference = date(2026, 6, 23, 0, 0)
    let value = date(2026, 7, 12, 10, 33, 49)

    #expect(
      UsageFormatting.compactTimestamp(value, relativeTo: reference, calendar: utcCalendar)
        == "Jul 12, 10:33"
    )
  }

  @Test func compactTimestampIncludesYearAcrossCalendarYears() {
    let reference = date(2026, 12, 31, 23, 59)
    let value = date(2027, 1, 1, 0, 8)

    #expect(
      UsageFormatting.compactTimestamp(value, relativeTo: reference, calendar: utcCalendar)
        == "Jan 1, 2027, 00:08"
    )
  }

  @Test func fullTimestampKeepsYearAndSecondsForTooltips() {
    let value = date(2026, 7, 12, 10, 33, 49)

    #expect(UsageFormatting.fullTimestamp(value, calendar: utcCalendar) == "2026-07-12 10:33:49")
  }

  private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int,
    _ minute: Int,
    _ second: Int = 0
  ) -> Date {
    var components = DateComponents()
    components.calendar = utcCalendar
    components.timeZone = utcCalendar.timeZone
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return components.date!
  }
}
