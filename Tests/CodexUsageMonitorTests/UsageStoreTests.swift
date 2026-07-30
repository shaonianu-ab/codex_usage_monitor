import Foundation
import XCTest

@testable import CodexUsageMonitor

@MainActor
final class UsageStoreTests: XCTestCase {
  func testRefreshCombinesLocalPlanAndRemoteCredits() async {
    let credit = UsageSnapshot.preview.credits[0]
    let result = RemoteUsageResult(
      planType: nil,
      fiveHourWindow: nil,
      weeklyWindow: nil,
      credits: [credit],
      availableCount: 1,
      usageSucceeded: false,
      creditsSucceeded: true,
      warnings: [
        RemoteWarning(endpoint: .usage, error: .httpStatus(404))
      ]
    )
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: StubAPIClient(result: result),
      refreshInterval: 60
    )

    await store.refresh()

    XCTAssertEqual(store.snapshot?.planType, "plus")
    XCTAssertEqual(store.snapshot?.credits, [credit])
    XCTAssertEqual(store.snapshot?.fiveHourQuota, .unavailable)
    XCTAssertEqual(store.snapshot?.weeklyQuota, .unavailable)
    XCTAssertEqual(
      store.message,
      UsageMessage.remote([
        RemoteWarning(endpoint: .usage, error: .httpStatus(404))
      ])
    )
  }

  func testMissingWindowFromSuccessfulUsageIsAnInactiveLimit() async {
    let weeklyWindow = UsageSnapshot.preview.weeklyWindow
    let result = RemoteUsageResult(
      planType: "plus",
      fiveHourWindow: nil,
      weeklyWindow: weeklyWindow,
      credits: [],
      availableCount: 0,
      usageSucceeded: true,
      creditsSucceeded: true,
      warnings: []
    )
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: StubAPIClient(result: result)
    )

    await store.refresh()

    XCTAssertEqual(store.snapshot?.fiveHourQuota, .unlimited)
    XCTAssertEqual(store.snapshot?.weeklyQuota, weeklyWindow.map(UsageQuotaState.limited))
  }

  func testManualRefreshAndIntervalChangesResetScheduleFromLatestCompletion() async {
    let clock = MutableDate(Date(timeIntervalSince1970: 1_000))
    let client = StubAPIClient(result: successfulResult)
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: client,
      refreshInterval: 600,
      now: { clock.value },
      sleep: { _ in
        try await Task.sleep(for: .seconds(60))
      }
    )

    store.start()
    let completedInitialRefresh = await waitUntil {
      await client.count() == 1 && !store.isRefreshing
    }
    XCTAssertTrue(completedInitialRefresh)
    XCTAssertEqual(store.lastRefreshAt, clock.value)
    XCTAssertEqual(store.nextRefreshAt, clock.value.addingTimeInterval(600))

    clock.value = Date(timeIntervalSince1970: 2_000)
    await store.refresh()
    let manualRefreshCount = await client.count()
    XCTAssertEqual(manualRefreshCount, 2)
    XCTAssertEqual(store.lastRefreshAt, clock.value)
    XCTAssertEqual(store.nextRefreshAt, clock.value.addingTimeInterval(600))

    store.setAutomaticRefreshInterval(1_800)
    XCTAssertEqual(store.automaticRefreshInterval, 1_800)
    XCTAssertEqual(store.nextRefreshAt, clock.value.addingTimeInterval(1_800))

    store.stop()
    XCTAssertNil(store.nextRefreshAt)
  }

  func testAutomaticRefreshRunsWhenScheduledIntervalElapses() async {
    let client = StubAPIClient(result: successfulResult)
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: client,
      refreshInterval: 0.02
    )

    store.start()

    let completedAutomaticRefresh = await waitUntil { await client.count() >= 2 }
    XCTAssertTrue(completedAutomaticRefresh)
    XCTAssertNotNil(store.lastRefreshAt)
    XCTAssertNotNil(store.nextRefreshAt)
    store.stop()
  }

  func testNotifiesWhenWeeklyQuotaIncreasesWithoutUsingAResetCredit() async {
    let notificationSender = RecordingQuotaResetNotificationSender()
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: SequencedAPIClient(results: [
        result(weeklyRemainingPercent: 30, availableCount: 2),
        result(weeklyRemainingPercent: 32, availableCount: 2),
      ]),
      notificationSender: notificationSender
    )

    await store.refresh()
    await store.refresh()

    XCTAssertEqual(notificationSender.sentNotificationCount, 1)
  }

  func testDoesNotNotifyWhenWeeklyQuotaIncreaseIsBelowTwoPercentagePoints() async {
    let notificationSender = RecordingQuotaResetNotificationSender()
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: SequencedAPIClient(results: [
        result(weeklyRemainingPercent: 30, availableCount: 2),
        result(weeklyRemainingPercent: 31.99, availableCount: 2),
      ]),
      notificationSender: notificationSender
    )

    await store.refresh()
    await store.refresh()

    XCTAssertEqual(notificationSender.sentNotificationCount, 0)
  }

  func testDoesNotNotifyWhenWeeklyQuotaIncreasesAfterUsingAResetCredit() async {
    let notificationSender = RecordingQuotaResetNotificationSender()
    let store = UsageStore(
      authProvider: StubAuthProvider(session: authSession),
      apiClient: SequencedAPIClient(results: [
        result(weeklyRemainingPercent: 30, availableCount: 2),
        result(weeklyRemainingPercent: 65, availableCount: 1),
      ]),
      notificationSender: notificationSender
    )

    await store.refresh()
    await store.refresh()

    XCTAssertEqual(notificationSender.sentNotificationCount, 0)
  }

  private var authSession: AuthSession {
    AuthSession(
      accessToken: "header.eyJwbGFuX3R5cGUiOiJwbHVzIn0.signature",
      accountID: "account",
      idToken: nil
    )
  }

  private var successfulResult: RemoteUsageResult {
    RemoteUsageResult(
      planType: "plus",
      fiveHourWindow: UsageSnapshot.preview.fiveHourWindow,
      weeklyWindow: UsageSnapshot.preview.weeklyWindow,
      credits: UsageSnapshot.preview.credits,
      availableCount: UsageSnapshot.preview.availableCount,
      usageSucceeded: true,
      creditsSucceeded: true,
      warnings: []
    )
  }

  private func result(
    weeklyRemainingPercent: Double,
    availableCount: Int
  ) -> RemoteUsageResult {
    RemoteUsageResult(
      planType: "plus",
      fiveHourWindow: nil,
      weeklyWindow: RateLimitWindow(
        usedPercent: 100 - weeklyRemainingPercent,
        resetAt: nil,
        windowSeconds: 604_800
      ),
      credits: [],
      availableCount: availableCount,
      usageSucceeded: true,
      creditsSucceeded: true,
      warnings: []
    )
  }

  private func waitUntil(
    timeout: Duration = .seconds(1),
    condition: @MainActor @escaping () async -> Bool
  ) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
      if await condition() {
        return true
      }
      try? await Task.sleep(for: .milliseconds(5))
    }
    return await condition()
  }
}

private final class MutableDate {
  var value: Date

  init(_ value: Date) {
    self.value = value
  }
}

private struct StubAuthProvider: AuthSessionProviding {
  let session: AuthSession

  func load() throws -> AuthSession {
    session
  }
}

private actor StubAPIClient: CodexUsageFetching {
  let result: RemoteUsageResult
  private(set) var callCount = 0

  init(result: RemoteUsageResult) {
    self.result = result
  }

  func fetch(auth: AuthSession) async -> RemoteUsageResult {
    callCount += 1
    return result
  }

  func count() -> Int {
    callCount
  }
}

private actor SequencedAPIClient: CodexUsageFetching {
  private var results: [RemoteUsageResult]

  init(results: [RemoteUsageResult]) {
    self.results = results
  }

  func fetch(auth: AuthSession) async -> RemoteUsageResult {
    results.removeFirst()
  }
}

@MainActor
private final class RecordingQuotaResetNotificationSender: QuotaResetNotificationSending {
  private(set) var sentNotificationCount = 0

  func requestAuthorization() {}

  func sendQuotaResetNotification() {
    sentNotificationCount += 1
  }
}
