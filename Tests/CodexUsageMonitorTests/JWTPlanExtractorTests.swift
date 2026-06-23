import Foundation
import XCTest

@testable import CodexUsageMonitor

final class JWTPlanExtractorTests: XCTestCase {
  func testReadsNestedChatGPTPlanClaim() throws {
    let payload: [String: Any] = [
      "https://api.openai.com/auth": [
        "chatgpt_plan_type": "Pro"
      ]
    ]
    let token = try makeJWT(payload: payload)

    XCTAssertEqual(JWTPlanExtractor.planType(from: token), "pro")
  }

  func testUsesAccessTokenWhenIDTokenHasNoPlan() throws {
    let idToken = try makeJWT(payload: ["sub": "user"])
    let accessToken = try makeJWT(payload: ["plan_type": "Plus"])

    XCTAssertEqual(
      JWTPlanExtractor.planType(idToken: idToken, accessToken: accessToken),
      "plus"
    )
  }

  private func makeJWT(payload: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: payload)
    let value = data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return "header.\(value).signature"
  }
}
