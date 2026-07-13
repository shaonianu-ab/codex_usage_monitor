import Foundation
import XCTest

@testable import CodexUsageMonitor

final class ResponseDecoderTests: XCTestCase {
  func testDecodesUsageWindows() throws {
    let json = """
      {
        "plan_type": "pro",
        "rate_limit": {
          "primary_window": {
            "used_percent": 48,
            "reset_at": 1781941800,
            "limit_window_seconds": 18000
          },
          "secondary_window": {
            "used_percent": 39.25,
            "reset_at": "2026-06-24T23:39:00Z",
            "limit_window_seconds": 604800
          }
        }
      }
      """

    let decoded = try CodexResponseDecoder.decodeUsage(Data(json.utf8))

    XCTAssertEqual(decoded.planType, "pro")
    XCTAssertEqual(decoded.rateLimit?.normalizedWindows.fiveHour?.remainingPercent, 52)
    XCTAssertEqual(decoded.rateLimit?.normalizedWindows.fiveHour?.windowSeconds, 18_000)
    XCTAssertEqual(decoded.rateLimit?.normalizedWindows.weekly?.remainingPercent, 60.75)
  }

  func testClassifiesSingleWeeklyWindowFromPrimarySlot() throws {
    let json = """
      {
        "plan_type": "plus",
        "rate_limit": {
          "primary_window": {
            "used_percent": 81,
            "reset_at": 1784515500,
            "limit_window_seconds": 604800
          }
        }
      }
      """

    let windows = try CodexResponseDecoder.decodeUsage(Data(json.utf8))
      .rateLimit?.normalizedWindows

    XCTAssertNil(windows?.fiveHour)
    XCTAssertEqual(windows?.weekly?.remainingPercent, 19)
    XCTAssertEqual(windows?.weekly?.windowSeconds, 604_800)
  }

  func testDurationMetadataWinsWhenWindowSlotsAreReversed() throws {
    let json = """
      {
        "rate_limit": {
          "primary_window": {
            "used_percent": 30,
            "limit_window_seconds": 604800
          },
          "secondary_window": {
            "used_percent": 40,
            "limit_window_seconds": 18000
          }
        }
      }
      """

    let windows = try CodexResponseDecoder.decodeUsage(Data(json.utf8))
      .rateLimit?.normalizedWindows

    XCTAssertEqual(windows?.fiveHour?.remainingPercent, 60)
    XCTAssertEqual(windows?.weekly?.remainingPercent, 70)
  }

  func testFallsBackToTraditionalSlotsWithoutDurationMetadata() throws {
    let json = """
      {
        "rate_limit": {
          "primary_window": { "used_percent": 10 },
          "secondary_window": { "used_percent": 20 }
        }
      }
      """

    let windows = try CodexResponseDecoder.decodeUsage(Data(json.utf8))
      .rateLimit?.normalizedWindows

    XCTAssertEqual(windows?.fiveHour?.remainingPercent, 90)
    XCTAssertEqual(windows?.weekly?.remainingPercent, 80)
  }

  func testDecodesCreditsWithFractionalDatesAndNullRedemption() throws {
    let json = """
      {
        "credits": [
          {
            "id": "credit-1",
            "reset_type": "codex_rate_limits",
            "status": "available",
            "granted_at": "2026-06-12T01:28:49.818157Z",
            "expires_at": "2026-07-12T01:28:49.818157Z",
            "redeem_started_at": null,
            "redeemed_at": null
          }
        ],
        "available_count": 4
      }
      """

    let decoded = try CodexResponseDecoder.decodeCredits(Data(json.utf8))

    XCTAssertEqual(decoded.availableCount, 4)
    XCTAssertEqual(decoded.credits.first?.model.id, "credit-1")
    XCTAssertEqual(decoded.credits.first?.model.isAvailable, true)
    XCTAssertNil(decoded.credits.first?.model.redeemedAt)
  }
}
