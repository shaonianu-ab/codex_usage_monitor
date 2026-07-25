import UserNotifications

@MainActor
protocol QuotaResetNotificationSending: AnyObject {
  func requestAuthorization()
  func sendQuotaResetNotification()
}

@MainActor
final class QuotaResetNotificationService: QuotaResetNotificationSending {
  private let notificationCenter: UNUserNotificationCenter

  init(notificationCenter: UNUserNotificationCenter = .current()) {
    self.notificationCenter = notificationCenter
  }

  func requestAuthorization() {
    notificationCenter.requestAuthorization(
      options: [.alert, .sound],
      completionHandler: Self.ignoreAuthorizationResult
    )
  }

  func sendQuotaResetNotification() {
    let content = UNMutableNotificationContent()
    content.title = "检测到额度重置！"
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    notificationCenter.add(request, withCompletionHandler: Self.ignoreNotificationResult)
  }

  private nonisolated static func ignoreAuthorizationResult(_ granted: Bool, _ error: Error?) {}

  private nonisolated static func ignoreNotificationResult(_ error: Error?) {}
}

@MainActor
final class NoopQuotaResetNotificationSender: QuotaResetNotificationSending {
  func requestAuthorization() {}

  func sendQuotaResetNotification() {}
}
