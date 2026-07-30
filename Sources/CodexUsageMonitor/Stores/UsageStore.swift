import Foundation
import Observation

@MainActor
@Observable
final class UsageStore {
  private static let minimumWeeklyQuotaIncreaseForNotification = 2.0

  private(set) var snapshot: UsageSnapshot?
  private(set) var isRefreshing = false
  private(set) var message: UsageMessage?
  private(set) var lastRefreshAt: Date?
  private(set) var nextRefreshAt: Date?
  private(set) var automaticRefreshInterval: TimeInterval

  private let authProvider: (any AuthSessionProviding)?
  private let apiClient: (any CodexUsageFetching)?
  private let notificationSender: any QuotaResetNotificationSending
  private let nowProvider: () -> Date
  private let sleepProvider: @Sendable (TimeInterval) async throws -> Void

  private var isRunning = false
  private var hasRequestedNotificationAuthorization = false
  private var notificationAuthorizationTask: Task<Void, Never>?
  private var scheduledRefreshTask: Task<Void, Never>?

  init(
    authProvider: any AuthSessionProviding = AuthFileReader(),
    apiClient: any CodexUsageFetching = CodexAPIClient(),
    refreshInterval: TimeInterval = 15 * 60,
    notificationSender: any QuotaResetNotificationSending = NoopQuotaResetNotificationSender(),
    now: @escaping () -> Date = { Date() },
    sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { interval in
      try await Task.sleep(for: .seconds(interval))
    }
  ) {
    self.authProvider = authProvider
    self.apiClient = apiClient
    self.notificationSender = notificationSender
    self.automaticRefreshInterval = max(0, refreshInterval)
    self.nowProvider = now
    self.sleepProvider = sleep
  }

  init(preview snapshot: UsageSnapshot) {
    self.snapshot = snapshot
    self.authProvider = nil
    self.apiClient = nil
    self.notificationSender = NoopQuotaResetNotificationSender()
    self.automaticRefreshInterval = 15 * 60
    self.nowProvider = { Date() }
    self.sleepProvider = { _ in }
  }

  func start() {
    guard authProvider != nil, !isRunning else { return }
    isRunning = true
    requestNotificationAuthorizationIfNeeded()
    scheduledRefreshTask = Task { [weak self] in
      await self?.refresh()
    }
  }

  func stop() {
    isRunning = false
    notificationAuthorizationTask?.cancel()
    notificationAuthorizationTask = nil
    scheduledRefreshTask?.cancel()
    scheduledRefreshTask = nil
    nextRefreshAt = nil
  }

  func setAutomaticRefreshInterval(_ interval: TimeInterval) {
    automaticRefreshInterval = max(0, interval)
    guard let lastRefreshAt else { return }
    scheduleNextRefresh(from: lastRefreshAt)
  }

  func refresh() async {
    guard !isRefreshing,
      let authProvider,
      let apiClient
    else { return }

    isRefreshing = true
    defer {
      isRefreshing = false
      recordRefreshCompletion(at: nowProvider())
    }

    do {
      let auth = try authProvider.load()
      let localPlan = JWTPlanExtractor.planType(
        idToken: auth.idToken,
        accessToken: auth.accessToken
      )
      let remote = await apiClient.fetch(auth: auth)

      let now = nowProvider()
      let refreshedSnapshot = UsageSnapshot(
        planType: remote.planType ?? localPlan ?? "unknown",
        fiveHourWindow: remote.fiveHourWindow,
        weeklyWindow: remote.weeklyWindow,
        usageSucceeded: remote.usageSucceeded,
        creditsSucceeded: remote.creditsSucceeded,
        credits: remote.credits,
        availableCount: remote.availableCount,
        updatedAt: now
      )

      let previousSnapshot = snapshot
      snapshot = refreshedSnapshot
      if shouldSendQuotaResetNotification(
        previous: previousSnapshot,
        current: refreshedSnapshot
      ) {
        notificationSender.sendQuotaResetNotification()
      }

      message = remote.warnings.isEmpty ? nil : .remote(remote.warnings)
    } catch let error as AuthFileError {
      message = .auth(error)
    } catch {
      message = .unexpected
    }
  }

  private func recordRefreshCompletion(at date: Date) {
    lastRefreshAt = date
    scheduleNextRefresh(from: date)
  }

  private func requestNotificationAuthorizationIfNeeded() {
    guard !hasRequestedNotificationAuthorization else { return }
    hasRequestedNotificationAuthorization = true

    notificationAuthorizationTask = Task { [notificationSender] in
      await Task.yield()
      guard !Task.isCancelled else { return }
      notificationSender.requestAuthorization()
    }
  }

  private func shouldSendQuotaResetNotification(
    previous: UsageSnapshot?,
    current: UsageSnapshot
  ) -> Bool {
    guard
      let previous,
      previous.usageSucceeded,
      previous.creditsSucceeded,
      current.usageSucceeded,
      current.creditsSucceeded,
      previous.availableCount <= current.availableCount,
      let previousWeeklyWindow = previous.weeklyWindow,
      let currentWeeklyWindow = current.weeklyWindow
    else {
      return false
    }

    return currentWeeklyWindow.remainingPercent - previousWeeklyWindow.remainingPercent
      >= Self.minimumWeeklyQuotaIncreaseForNotification
  }

  private func scheduleNextRefresh(from referenceDate: Date) {
    scheduledRefreshTask?.cancel()
    scheduledRefreshTask = nil

    guard isRunning else {
      nextRefreshAt = nil
      return
    }

    let deadline = referenceDate.addingTimeInterval(automaticRefreshInterval)
    nextRefreshAt = deadline
    let delay = max(0, deadline.timeIntervalSince(nowProvider()))

    scheduledRefreshTask = Task { [weak self] in
      guard let self else { return }
      do {
        try await sleepProvider(delay)
      } catch {
        return
      }
      guard !Task.isCancelled else { return }
      await refresh()
    }
  }
}

enum UsageMessage: Sendable, Equatable {
  case auth(AuthFileError)
  case remote([RemoteWarning])
  case unexpected
}
