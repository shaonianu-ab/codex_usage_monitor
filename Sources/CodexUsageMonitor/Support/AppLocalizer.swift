import Foundation

enum LocalizedKey {
  case settings
  case quit
  case refreshSchedule
  case loadingUsage
  case usageUnavailableYet
  case retry
  case retryRefresh
  case fiveHourRemaining
  case weekRemaining
  case fiveHourLimit
  case weeklyLimit
  case lastUpdated
  case remainingUsage
  case usageDataUnavailable
  case noActiveLimit
  case noActiveLimitDescription
  case reset
  case rateLimitResets
  case nextExpires
  case noUpcomingExpiration
  case noRateLimitResets
  case refreshingUsage
  case refreshNow
  case refresh
  case available
  case unavailable
  case redeemed
  case expired
  case unknown
  case granted
  case expires
  case settingsTitle
  case back
  case resetDefaults
  case language
  case languageDescription
  case appearance
  case appearanceDescription
  case themeSystem
  case themeLight
  case themeDark
  case launchAtLogin
  case launchAtLoginDescription
  case launchAtLoginToggle
  case launchAtLoginRequiresApproval
  case launchAtLoginUnavailable
  case launchAtLoginOperationFailed
  case openLoginItemsSettings
  case automaticRefresh
  case automaticRefreshDescription
  case refreshInterval
  case refreshIntervalValue
  case colorThresholds
  case fiveHourThresholds
  case weeklyThresholds
  case creditDayThresholds
  case quotaThresholdDescription
  case creditThresholdDescription
  case redUpperBound
  case yellowUpperBound
  case red
  case yellow
  case green
  case percent
  case days
  case authNotFound
  case authNotRegular
  case authTooLarge
  case authInvalidJSON
  case authMissingCredentials
  case usageEndpoint
  case creditsEndpoint
  case invalidResponse
  case httpFailure
  case responseTooLarge
  case requestFailed
  case unexpectedError
}

struct AppLocalizer {
  let language: AppLanguage

  func text(_ key: LocalizedKey) -> String {
    switch (language, key) {
    case (.english, .settings): "Settings"
    case (.simplifiedChinese, .settings): "设置"
    case (.english, .quit): "Quit"
    case (.simplifiedChinese, .quit): "退出"
    case (.english, .refreshSchedule): "Refreshes every %d min"
    case (.simplifiedChinese, .refreshSchedule): "每 %d 分钟刷新"
    case (.english, .loadingUsage): "Loading Codex usage…"
    case (.simplifiedChinese, .loadingUsage): "正在加载 Codex 用量…"
    case (.english, .usageUnavailableYet): "Codex usage is not available yet"
    case (.simplifiedChinese, .usageUnavailableYet): "Codex 用量暂不可用"
    case (.english, .retry): "Retry"
    case (.simplifiedChinese, .retry): "重试"
    case (.english, .retryRefresh): "Retry refresh"
    case (.simplifiedChinese, .retryRefresh): "重新刷新"
    case (.english, .fiveHourRemaining): "5h remaining"
    case (.simplifiedChinese, .fiveHourRemaining): "5 小时剩余"
    case (.english, .weekRemaining): "Week remaining"
    case (.simplifiedChinese, .weekRemaining): "本周剩余"
    case (.english, .fiveHourLimit): "5-hour limit"
    case (.simplifiedChinese, .fiveHourLimit): "5 小时限制"
    case (.english, .weeklyLimit): "Weekly limit"
    case (.simplifiedChinese, .weeklyLimit): "每周限制"
    case (.english, .lastUpdated): "Last updated"
    case (.simplifiedChinese, .lastUpdated): "上次更新"
    case (.english, .remainingUsage): "Remaining usage"
    case (.simplifiedChinese, .remainingUsage): "剩余用量"
    case (.english, .usageDataUnavailable): "Usage data unavailable"
    case (.simplifiedChinese, .usageDataUnavailable): "用量数据不可用"
    case (.english, .noActiveLimit): "No active limit"
    case (.simplifiedChinese, .noActiveLimit): "暂无限制"
    case (.english, .noActiveLimitDescription):
      "This usage window is not currently enforced."
    case (.simplifiedChinese, .noActiveLimitDescription): "当前未启用此用量窗口。"
    case (.english, .reset): "Reset"
    case (.simplifiedChinese, .reset): "重置"
    case (.english, .rateLimitResets): "RATE-LIMIT RESETS"
    case (.simplifiedChinese, .rateLimitResets): "速率限制重置"
    case (.english, .nextExpires): "Next expires"
    case (.simplifiedChinese, .nextExpires): "最近到期"
    case (.english, .noUpcomingExpiration): "No upcoming reset expiration"
    case (.simplifiedChinese, .noUpcomingExpiration): "没有即将到期的重置额度"
    case (.english, .noRateLimitResets): "No rate-limit resets available"
    case (.simplifiedChinese, .noRateLimitResets): "没有可用的速率限制重置额度"
    case (.english, .refreshingUsage): "Refreshing usage"
    case (.simplifiedChinese, .refreshingUsage): "正在刷新用量"
    case (.english, .refreshNow): "Refresh now"
    case (.simplifiedChinese, .refreshNow): "立即刷新"
    case (.english, .refresh): "Refresh"
    case (.simplifiedChinese, .refresh): "刷新"
    case (.english, .available): "Available"
    case (.simplifiedChinese, .available): "可用"
    case (.english, .unavailable): "Unavailable"
    case (.simplifiedChinese, .unavailable): "不可用"
    case (.english, .redeemed): "Redeemed"
    case (.simplifiedChinese, .redeemed): "已兑换"
    case (.english, .expired): "Expired"
    case (.simplifiedChinese, .expired): "已过期"
    case (.english, .unknown): "unknown"
    case (.simplifiedChinese, .unknown): "未知"
    case (.english, .granted): "Granted"
    case (.simplifiedChinese, .granted): "发放时间"
    case (.english, .expires): "Expires"
    case (.simplifiedChinese, .expires): "到期时间"
    case (.english, .settingsTitle): "Settings"
    case (.simplifiedChinese, .settingsTitle): "设置"
    case (.english, .back): "Back"
    case (.simplifiedChinese, .back): "返回"
    case (.english, .resetDefaults): "Reset"
    case (.simplifiedChinese, .resetDefaults): "恢复默认"
    case (.english, .language): "Language"
    case (.simplifiedChinese, .language): "语言"
    case (.english, .languageDescription): "Changes apply immediately across the menu."
    case (.simplifiedChinese, .languageDescription): "语言切换会立即应用到整个菜单。"
    case (.english, .appearance): "Appearance"
    case (.simplifiedChinese, .appearance): "外观"
    case (.english, .appearanceDescription): "Choose how the popover follows macOS appearance."
    case (.simplifiedChinese, .appearanceDescription): "选择浮窗如何跟随 macOS 外观。"
    case (.english, .themeSystem): "System"
    case (.simplifiedChinese, .themeSystem): "跟随系统"
    case (.english, .themeLight): "Light"
    case (.simplifiedChinese, .themeLight): "浅色"
    case (.english, .themeDark): "Dark"
    case (.simplifiedChinese, .themeDark): "深色"
    case (.english, .launchAtLogin): "Launch at login"
    case (.simplifiedChinese, .launchAtLogin): "开机自启"
    case (.english, .launchAtLoginDescription):
      "Start Codex Usage Monitor automatically after you sign in."
    case (.simplifiedChinese, .launchAtLoginDescription):
      "登录 macOS 后自动启动 Codex Usage Monitor。"
    case (.english, .launchAtLoginToggle): "Open at login"
    case (.simplifiedChinese, .launchAtLoginToggle): "登录时启动"
    case (.english, .launchAtLoginRequiresApproval):
      "Approval is required in System Settings."
    case (.simplifiedChinese, .launchAtLoginRequiresApproval):
      "需要在“系统设置”的“登录项”中批准。"
    case (.english, .launchAtLoginUnavailable):
      "macOS could not find a valid login item for this app."
    case (.simplifiedChinese, .launchAtLoginUnavailable):
      "macOS 无法为当前应用找到有效的登录项。"
    case (.english, .launchAtLoginOperationFailed):
      "The login item could not be updated."
    case (.simplifiedChinese, .launchAtLoginOperationFailed):
      "无法更新登录项，请稍后重试。"
    case (.english, .openLoginItemsSettings): "Open Login Items"
    case (.simplifiedChinese, .openLoginItemsSettings): "打开登录项设置"
    case (.english, .automaticRefresh): "Automatic refresh"
    case (.simplifiedChinese, .automaticRefresh): "自动刷新"
    case (.english, .automaticRefreshDescription):
      "The next timer starts after any refresh finishes."
    case (.simplifiedChinese, .automaticRefreshDescription):
      "每次刷新完成后，重新开始计算下一次刷新时间。"
    case (.english, .refreshInterval): "Interval"
    case (.simplifiedChinese, .refreshInterval): "刷新间隔"
    case (.english, .refreshIntervalValue): "%d min"
    case (.simplifiedChinese, .refreshIntervalValue): "%d 分钟"
    case (.english, .colorThresholds): "Color thresholds"
    case (.simplifiedChinese, .colorThresholds): "颜色阈值"
    case (.english, .fiveHourThresholds): "5-hour quota"
    case (.simplifiedChinese, .fiveHourThresholds): "5 小时额度"
    case (.english, .weeklyThresholds): "Weekly quota"
    case (.simplifiedChinese, .weeklyThresholds): "每周额度"
    case (.english, .creditDayThresholds): "Reset credit expiry"
    case (.simplifiedChinese, .creditDayThresholds): "重置额度到期"
    case (.english, .quotaThresholdDescription): "Color by the remaining percentage."
    case (.simplifiedChinese, .quotaThresholdDescription): "根据剩余百分比改变颜色。"
    case (.english, .creditThresholdDescription): "Color each Available badge by days remaining."
    case (.simplifiedChinese, .creditThresholdDescription): "根据各额度剩余天数改变“可用”颜色。"
    case (.english, .redUpperBound): "Red up to"
    case (.simplifiedChinese, .redUpperBound): "红色上限"
    case (.english, .yellowUpperBound): "Yellow up to"
    case (.simplifiedChinese, .yellowUpperBound): "黄色上限"
    case (.english, .red): "Red"
    case (.simplifiedChinese, .red): "红"
    case (.english, .yellow): "Yellow"
    case (.simplifiedChinese, .yellow): "黄"
    case (.english, .green): "Green"
    case (.simplifiedChinese, .green): "绿"
    case (.english, .percent): "%"
    case (.simplifiedChinese, .percent): "%"
    case (.english, .days): "days"
    case (.simplifiedChinese, .days): "天"
    case (.english, .authNotFound): "Could not find ~/.codex/auth.json. Sign in to Codex first."
    case (.simplifiedChinese, .authNotFound): "未找到 ~/.codex/auth.json，请先登录 Codex。"
    case (.english, .authNotRegular): "The Codex auth file is not a regular file."
    case (.simplifiedChinese, .authNotRegular): "Codex 登录文件不是普通文件。"
    case (.english, .authTooLarge): "The Codex auth file has an unexpected size."
    case (.simplifiedChinese, .authTooLarge): "Codex 登录文件大小异常，已停止读取。"
    case (.english, .authInvalidJSON): "The Codex auth file could not be parsed."
    case (.simplifiedChinese, .authInvalidJSON): "Codex 登录文件格式无法解析。"
    case (.english, .authMissingCredentials): "The Codex auth file is missing required credentials."
    case (.simplifiedChinese, .authMissingCredentials): "Codex 登录文件缺少 access_token 或 account_id。"
    case (.english, .usageEndpoint): "Usage endpoint"
    case (.simplifiedChinese, .usageEndpoint): "用量接口"
    case (.english, .creditsEndpoint): "Reset credits endpoint"
    case (.simplifiedChinese, .creditsEndpoint): "重置额度接口"
    case (.english, .invalidResponse): "The server returned an invalid response."
    case (.simplifiedChinese, .invalidResponse): "服务器返回了无效响应。"
    case (.english, .httpFailure): "Request failed (HTTP %d)."
    case (.simplifiedChinese, .httpFailure): "请求失败（HTTP %d）。"
    case (.english, .responseTooLarge): "The response was unexpectedly large."
    case (.simplifiedChinese, .responseTooLarge): "响应数据异常过大，已停止解析。"
    case (.english, .requestFailed): "The request could not be completed."
    case (.simplifiedChinese, .requestFailed): "请求无法完成。"
    case (.english, .unexpectedError): "An unexpected error occurred."
    case (.simplifiedChinese, .unexpectedError): "发生了意外错误。"
    }
  }

  func format(_ key: LocalizedKey, _ arguments: CVarArg...) -> String {
    String(format: text(key), locale: language.locale, arguments: arguments)
  }

  func message(_ message: UsageMessage) -> String {
    switch message {
    case .auth(let error):
      return authError(error)
    case .remote(let warnings):
      return warnings.map(remoteWarning).joined(separator: "\n")
    case .unexpected:
      return text(.unexpectedError)
    }
  }

  private func authError(_ error: AuthFileError) -> String {
    switch error {
    case .notFound:
      text(.authNotFound)
    case .notRegularFile:
      text(.authNotRegular)
    case .tooLarge:
      text(.authTooLarge)
    case .invalidJSON:
      text(.authInvalidJSON)
    case .missingCredentials:
      text(.authMissingCredentials)
    }
  }

  private func remoteWarning(_ warning: RemoteWarning) -> String {
    let endpoint = text(warning.endpoint == .usage ? .usageEndpoint : .creditsEndpoint)
    return "\(endpoint): \(apiError(warning.error))"
  }

  private func apiError(_ error: CodexAPIError) -> String {
    switch error {
    case .invalidResponse:
      text(.invalidResponse)
    case .httpStatus(let code):
      format(.httpFailure, code)
    case .responseTooLarge:
      text(.responseTooLarge)
    case .requestFailed:
      text(.requestFailed)
    }
  }
}
