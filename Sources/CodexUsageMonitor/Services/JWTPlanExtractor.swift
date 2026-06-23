import Foundation

enum JWTPlanExtractor {
  static func planType(idToken: String?, accessToken: String) -> String? {
    if let idToken, let plan = planType(from: idToken) {
      return plan
    }
    return planType(from: accessToken)
  }

  static func planType(from token: String) -> String? {
    let segments = token.split(separator: ".", omittingEmptySubsequences: false)
    guard segments.count >= 2,
      let payload = decodeBase64URL(String(segments[1])),
      let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
    else {
      return nil
    }

    let directKeys = ["chatgpt_plan_type", "plan_type", "plan"]
    if let plan = firstString(in: object, keys: directKeys) {
      return normalize(plan)
    }

    let namespaceKeys = [
      "https://api.openai.com/auth",
      "https://api.openai.com/profile",
      "auth",
    ]
    for namespace in namespaceKeys {
      guard let nested = object[namespace] as? [String: Any] else { continue }
      if let plan = firstString(in: nested, keys: directKeys) {
        return normalize(plan)
      }
    }
    return nil
  }

  private static func firstString(in object: [String: Any], keys: [String]) -> String? {
    for key in keys {
      if let value = object[key] as? String, !value.isEmpty {
        return value
      }
    }
    return nil
  }

  private static func normalize(_ plan: String) -> String {
    plan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private static func decodeBase64URL(_ value: String) -> Data? {
    var base64 =
      value
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let remainder = base64.count % 4
    if remainder != 0 {
      base64.append(String(repeating: "=", count: 4 - remainder))
    }
    return Data(base64Encoded: base64)
  }
}
