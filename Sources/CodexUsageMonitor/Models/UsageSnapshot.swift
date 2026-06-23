import Foundation

struct RateLimitWindow: Sendable, Equatable {
  let usedPercent: Double
  let resetAt: Date?
  let windowSeconds: Int?

  var remainingPercent: Double {
    min(100, max(0, 100 - usedPercent))
  }
}

struct RateLimitCredit: Identifiable, Sendable, Equatable {
  let id: String
  let resetType: String
  let status: String
  let grantedAt: Date
  let expiresAt: Date
  let redeemStartedAt: Date?
  let redeemedAt: Date?

  var isAvailable: Bool {
    status.caseInsensitiveCompare("available") == .orderedSame
  }
}

struct UsageSnapshot: Sendable, Equatable {
  let planType: String
  let primaryWindow: RateLimitWindow?
  let secondaryWindow: RateLimitWindow?
  let credits: [RateLimitCredit]
  let availableCount: Int
  let updatedAt: Date

  static let preview: UsageSnapshot = {
    let calendar = Calendar(identifier: .gregorian)
    let zone = TimeZone(identifier: "Asia/Shanghai") ?? .current

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0)
      -> Date
    {
      var components = DateComponents()
      components.calendar = calendar
      components.timeZone = zone
      components.year = year
      components.month = month
      components.day = day
      components.hour = hour
      components.minute = minute
      components.second = second
      return components.date ?? .now
    }

    let credits = [
      ("credit-1", date(2026, 6, 12, 10, 33, 49), date(2026, 7, 12, 10, 33, 49)),
      ("credit-2", date(2026, 6, 18, 8, 7, 14), date(2026, 7, 18, 8, 7, 14)),
    ].map {
      RateLimitCredit(
        id: $0.0,
        resetType: "codex_rate_limits",
        status: "available",
        grantedAt: $0.1,
        expiresAt: $0.2,
        redeemStartedAt: nil,
        redeemedAt: nil
      )
    }

    return UsageSnapshot(
      planType: "plus",
      primaryWindow: RateLimitWindow(
        usedPercent: 44,
        resetAt: date(2026, 6, 23, 4, 39),
        windowSeconds: 18_000
      ),
      secondaryWindow: RateLimitWindow(
        usedPercent: 23,
        resetAt: date(2026, 6, 29, 18, 38),
        windowSeconds: 604_800
      ),
      credits: credits,
      availableCount: 2,
      updatedAt: date(2026, 6, 23, 0, 23)
    )
  }()
}
