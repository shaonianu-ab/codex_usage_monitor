import Foundation
import Observation

@MainActor
@Observable
final class UsageStore {
  private(set) var snapshot: UsageSnapshot?
  private(set) var isRefreshing = false
  private(set) var message: UsageMessage?
  private(set) var lastRefreshAt: Date?
  private(set) var nextRefreshAt: Date?
  private(set) var automaticRefreshInterval: TimeInterval

  private let authProvider: (any AuthSessionProviding)?
  private let apiClient: (any CodexUsageFetching)?
  private let nowProvider: () -> Date
  private let sleepProvider: @Sendable (TimeInterval) async throws -> Void

  private var isRunning = false
  private var scheduledRefreshTask: Task<Void, Never>?

  init(
    authProvider: any AuthSessionProviding = AuthFileReader(),
    apiClient: any CodexUsageFetching = CodexAPIClient(),
    refreshInterval: TimeInterval = 15 * 60,
    now: @escaping () -> Date = { Date() },
    sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { interval in
      try await Task.sleep(for: .seconds(interval))
    }
  ) {
    self.authProvider = authProvider
    self.apiClient = apiClient
    self.automaticRefreshInterval = max(0, refreshInterval)
    self.nowProvider = now
    self.sleepProvider = sleep
  }

  init(preview snapshot: UsageSnapshot) {
    self.snapshot = snapshot
    self.authProvider = nil
    self.apiClient = nil
    self.automaticRefreshInterval = 15 * 60
    self.nowProvider = { Date() }
    self.sleepProvider = { _ in }
  }

  func start() {
    guard authProvider != nil, !isRunning else { return }
    isRunning = true
    scheduledRefreshTask = Task { [weak self] in
      await self?.refresh()
    }
  }

  func stop() {
    isRunning = false
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
      snapshot = UsageSnapshot(
        planType: remote.planType ?? localPlan ?? "unknown",
        primaryWindow: remote.primaryWindow,
        secondaryWindow: remote.secondaryWindow,
        credits: remote.credits,
        availableCount: remote.availableCount,
        updatedAt: now
      )

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
