import Foundation
import XCTest

@testable import CodexUsageMonitor

final class AuthFileReaderTests: XCTestCase {
  func testLoadsExpectedTokenFields() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let fileURL = directory.appendingPathComponent("auth.json")
    let json = """
      {
        "tokens": {
          "access_token": "access-value",
          "account_id": "account-value",
          "id_token": "id-value"
        }
      }
      """
    try Data(json.utf8).write(to: fileURL)

    let result = try AuthFileReader(fileURL: fileURL).load()

    XCTAssertEqual(
      result,
      AuthSession(
        accessToken: "access-value",
        accountID: "account-value",
        idToken: "id-value"
      )
    )
  }

  func testMissingFileReturnsFriendlyError() {
    let missing = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)

    XCTAssertThrowsError(try AuthFileReader(fileURL: missing).load()) { error in
      guard case AuthFileError.notFound = error else {
        return XCTFail("Expected notFound, got \(error)")
      }
    }
  }
}
