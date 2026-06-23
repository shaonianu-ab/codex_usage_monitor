import Foundation

protocol CodexUsageFetching: Sendable {
  func fetch(auth: AuthSession) async -> RemoteUsageResult
}

struct RemoteUsageResult: Sendable, Equatable {
  let planType: String?
  let primaryWindow: RateLimitWindow?
  let secondaryWindow: RateLimitWindow?
  let credits: [RateLimitCredit]
  let availableCount: Int
  let usageSucceeded: Bool
  let creditsSucceeded: Bool
  let warnings: [RemoteWarning]
}

enum RemoteEndpoint: Sendable, Equatable {
  case usage
  case credits
}

struct RemoteWarning: Sendable, Equatable {
  let endpoint: RemoteEndpoint
  let error: CodexAPIError
}

actor CodexAPIClient: CodexUsageFetching {
  private let session: URLSession
  private let baseURL: URL

  init(
    session: URLSession? = nil,
    baseURL: URL = URL(string: "https://chatgpt.com")!
  ) {
    self.baseURL = baseURL
    if let session {
      self.session = session
    } else {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.httpShouldSetCookies = false
      configuration.urlCache = nil
      configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
      self.session = URLSession(
        configuration: configuration,
        delegate: SameHostRedirectDelegate(allowedHost: baseURL.host),
        delegateQueue: nil
      )
    }
  }

  func fetch(auth: AuthSession) async -> RemoteUsageResult {
    async let usageAttempt = captureUsage(auth: auth)
    async let creditsAttempt = captureCredits(auth: auth)

    let usageResult = await usageAttempt
    let creditsResult = await creditsAttempt

    var warnings: [RemoteWarning] = []
    var usage: UsageResponse?
    var credits: CreditsResponse?

    switch usageResult {
    case .success(let response):
      usage = response
    case .failure(let error):
      warnings.append(RemoteWarning(endpoint: .usage, error: error))
    }

    switch creditsResult {
    case .success(let response):
      credits = response
    case .failure(let error):
      warnings.append(RemoteWarning(endpoint: .credits, error: error))
    }

    let mappedCredits = (credits?.credits ?? []).map(\.model)
      .sorted { $0.expiresAt < $1.expiresAt }

    return RemoteUsageResult(
      planType: usage?.planType,
      primaryWindow: usage?.rateLimit?.primaryWindow?.model,
      secondaryWindow: usage?.rateLimit?.secondaryWindow?.model,
      credits: mappedCredits,
      availableCount: credits?.availableCount ?? mappedCredits.filter(\.isAvailable).count,
      usageSucceeded: usage != nil,
      creditsSucceeded: credits != nil,
      warnings: warnings
    )
  }

  private func captureUsage(auth: AuthSession) async -> Result<UsageResponse, CodexAPIError> {
    do {
      let data = try await request(path: "/backend-api/wham/usage", auth: auth)
      return .success(try CodexResponseDecoder.decodeUsage(data))
    } catch {
      return .failure(error as? CodexAPIError ?? .requestFailed)
    }
  }

  private func captureCredits(auth: AuthSession) async -> Result<CreditsResponse, CodexAPIError> {
    do {
      let data = try await request(
        path: "/backend-api/wham/rate-limit-reset-credits",
        auth: auth
      )
      return .success(try CodexResponseDecoder.decodeCredits(data))
    } catch {
      return .failure(error as? CodexAPIError ?? .requestFailed)
    }
  }

  private func request(path: String, auth: AuthSession) async throws -> Data {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 15
    request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue(auth.accountID, forHTTPHeaderField: "ChatGPT-Account-ID")
    request.setValue("codex-1", forHTTPHeaderField: "OpenAI-Beta")
    request.setValue("Codex Desktop", forHTTPHeaderField: "Originator")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CodexAPIError.invalidResponse
    }
    guard httpResponse.url?.host == baseURL.host else {
      throw CodexAPIError.invalidResponse
    }
    guard (200..<300).contains(httpResponse.statusCode) else {
      throw CodexAPIError.httpStatus(httpResponse.statusCode)
    }
    guard data.count <= 2 * 1_024 * 1_024 else {
      throw CodexAPIError.responseTooLarge
    }
    return data
  }
}

private final class SameHostRedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable
{
  private let allowedHost: String?

  init(allowedHost: String?) {
    self.allowedHost = allowedHost
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(request.url?.host == allowedHost ? request : nil)
  }
}

enum CodexAPIError: LocalizedError, Sendable, Equatable {
  case invalidResponse
  case httpStatus(Int)
  case responseTooLarge
  case requestFailed

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "服务器返回了无效响应。"
    case .httpStatus(let code):
      "请求失败（HTTP \(code)）。"
    case .responseTooLarge:
      "响应数据异常过大，已停止解析。"
    case .requestFailed:
      "请求无法完成。"
    }
  }
}

enum CodexResponseDecoder {
  static func decodeUsage(_ data: Data) throws -> UsageResponse {
    try JSONDecoder().decode(UsageResponse.self, from: data)
  }

  static func decodeCredits(_ data: Data) throws -> CreditsResponse {
    try JSONDecoder().decode(CreditsResponse.self, from: data)
  }
}

struct UsageResponse: Decodable, Sendable, Equatable {
  let planType: String?
  let rateLimit: RateLimitPayload?

  enum CodingKeys: String, CodingKey {
    case planType = "plan_type"
    case rateLimit = "rate_limit"
  }
}

struct RateLimitPayload: Decodable, Sendable, Equatable {
  let primaryWindow: RateLimitWindowPayload?
  let secondaryWindow: RateLimitWindowPayload?

  enum CodingKeys: String, CodingKey {
    case primaryWindow = "primary_window"
    case secondaryWindow = "secondary_window"
  }
}

struct RateLimitWindowPayload: Decodable, Sendable, Equatable {
  let usedPercent: Double
  let resetAt: FlexibleDate?
  let windowSeconds: Int?

  enum CodingKeys: String, CodingKey {
    case usedPercent = "used_percent"
    case resetAt = "reset_at"
    case windowSeconds = "limit_window_seconds"
  }

  var model: RateLimitWindow {
    RateLimitWindow(
      usedPercent: usedPercent,
      resetAt: resetAt?.value,
      windowSeconds: windowSeconds
    )
  }
}

struct CreditsResponse: Decodable, Sendable, Equatable {
  let credits: [CreditPayload]
  let availableCount: Int

  enum CodingKeys: String, CodingKey {
    case credits
    case availableCount = "available_count"
  }
}

struct CreditPayload: Decodable, Sendable, Equatable {
  let id: String
  let resetType: String
  let status: String
  let grantedAt: FlexibleDate
  let expiresAt: FlexibleDate
  let redeemStartedAt: FlexibleDate?
  let redeemedAt: FlexibleDate?

  enum CodingKeys: String, CodingKey {
    case id
    case resetType = "reset_type"
    case status
    case grantedAt = "granted_at"
    case expiresAt = "expires_at"
    case redeemStartedAt = "redeem_started_at"
    case redeemedAt = "redeemed_at"
  }

  var model: RateLimitCredit {
    RateLimitCredit(
      id: id,
      resetType: resetType,
      status: status,
      grantedAt: grantedAt.value,
      expiresAt: expiresAt.value,
      redeemStartedAt: redeemStartedAt?.value,
      redeemedAt: redeemedAt?.value
    )
  }
}

struct FlexibleDate: Decodable, Sendable, Equatable {
  let value: Date

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let number = try? container.decode(Double.self) {
      let seconds = number > 10_000_000_000 ? number / 1_000 : number
      value = Date(timeIntervalSince1970: seconds)
      return
    }

    let string = try container.decode(String.self)
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: string) {
      value = date
      return
    }

    let standard = ISO8601DateFormatter()
    standard.formatOptions = [.withInternetDateTime]
    if let date = standard.date(from: string) {
      value = date
      return
    }

    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Unsupported date format"
    )
  }
}
