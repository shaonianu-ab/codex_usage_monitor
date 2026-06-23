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
    XCTAssertEqual(decoded.rateLimit?.primaryWindow?.model.remainingPercent, 52)
    XCTAssertEqual(decoded.rateLimit?.primaryWindow?.windowSeconds, 18_000)
    XCTAssertEqual(decoded.rateLimit?.secondaryWindow?.model.remainingPercent, 60.75)
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
