import Foundation

struct AuthSession: Sendable, Equatable {
  let accessToken: String
  let accountID: String
  let idToken: String?
}

struct CodexAuthDocument: Decodable, Sendable {
  let tokens: Tokens

  struct Tokens: Decodable, Sendable {
    let accessToken: String
    let accountID: String
    let idToken: String?

    enum CodingKeys: String, CodingKey {
      case accessToken = "access_token"
      case accountID = "account_id"
      case idToken = "id_token"
    }
  }

  var session: AuthSession {
    AuthSession(
      accessToken: tokens.accessToken,
      accountID: tokens.accountID,
      idToken: tokens.idToken
    )
  }
}
