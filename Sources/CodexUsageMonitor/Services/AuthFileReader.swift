import Foundation

protocol AuthSessionProviding: Sendable {
  func load() throws -> AuthSession
}

struct AuthFileReader: AuthSessionProviding, Sendable {
  private static let maximumFileSize = 2 * 1_024 * 1_024

  let fileURL: URL

  init(
    fileURL: URL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".codex", isDirectory: true)
      .appendingPathComponent("auth.json", isDirectory: false)
  ) {
    self.fileURL = fileURL
  }

  func load() throws -> AuthSession {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw AuthFileError.notFound(fileURL.path)
    }

    let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
    guard values.isRegularFile == true else {
      throw AuthFileError.notRegularFile
    }
    guard let size = values.fileSize, size <= Self.maximumFileSize else {
      throw AuthFileError.tooLarge
    }

    let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
    let document: CodexAuthDocument
    do {
      document = try JSONDecoder().decode(CodexAuthDocument.self, from: data)
    } catch {
      throw AuthFileError.invalidJSON
    }

    guard !document.tokens.accessToken.isEmpty, !document.tokens.accountID.isEmpty else {
      throw AuthFileError.missingCredentials
    }
    return document.session
  }
}

enum AuthFileError: LocalizedError, Sendable, Equatable {
  case notFound(String)
  case notRegularFile
  case tooLarge
  case invalidJSON
  case missingCredentials

  var errorDescription: String? {
    switch self {
    case .notFound:
      "未找到 ~/.codex/auth.json，请先登录 Codex。"
    case .notRegularFile:
      "Codex 登录文件不是普通文件。"
    case .tooLarge:
      "Codex 登录文件大小异常，已停止读取。"
    case .invalidJSON:
      "Codex 登录文件格式无法解析。"
    case .missingCredentials:
      "Codex 登录文件缺少 access_token 或 account_id。"
    }
  }
}
