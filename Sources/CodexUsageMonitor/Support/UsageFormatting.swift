import Foundation

enum UsageFormatting {
  static func plan(_ value: String) -> String {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty || normalized == "unknown" ? "unknown" : normalized.lowercased()
  }

  static func clock(
    _ date: Date,
    calendar: Calendar = .current,
    language: AppLanguage = .english
  ) -> String {
    formatter("HH:mm", calendar: calendar, language: language).string(from: date)
  }

  static func reset(
    _ date: Date,
    relativeTo referenceDate: Date = .now,
    calendar: Calendar = .current,
    language: AppLanguage = .english
  ) -> String {
    compactTimestamp(
      date,
      relativeTo: referenceDate,
      calendar: calendar,
      language: language
    )
  }

  static func compactTimestamp(
    _ date: Date,
    relativeTo referenceDate: Date = .now,
    calendar: Calendar = .current,
    language: AppLanguage = .english
  ) -> String {
    let includesYear =
      calendar.component(.year, from: date)
      != calendar.component(.year, from: referenceDate)
    let format: String
    switch language {
    case .english:
      format = includesYear ? "MMM d, yyyy, HH:mm" : "MMM d, HH:mm"
    case .simplifiedChinese:
      format = includesYear ? "yyyy年M月d日 HH:mm" : "M月d日 HH:mm"
    }
    return formatter(format, calendar: calendar, language: language).string(from: date)
  }

  static func fullTimestamp(
    _ date: Date,
    calendar: Calendar = .current,
    language: AppLanguage = .english
  ) -> String {
    formatter("yyyy-MM-dd HH:mm:ss", calendar: calendar, language: language).string(from: date)
  }

  static func remainingDays(
    until expiration: Date,
    relativeTo referenceDate: Date,
    calendar: Calendar = .current
  ) -> Int {
    let start = calendar.startOfDay(for: referenceDate)
    let end = calendar.startOfDay(for: expiration)
    return calendar.dateComponents([.day], from: start, to: end).day ?? 0
  }

  private static func formatter(
    _ format: String,
    calendar: Calendar,
    language: AppLanguage
  ) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale =
      language == .english
      ? Locale(identifier: "en_US_POSIX") : language.locale
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = format
    return formatter
  }
}
