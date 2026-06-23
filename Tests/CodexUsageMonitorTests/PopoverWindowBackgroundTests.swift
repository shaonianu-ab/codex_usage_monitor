import AppKit
import XCTest

@testable import CodexUsageMonitor

@MainActor
final class PopoverWindowBackgroundTests: XCTestCase {
  func testEachPresentationNotifiesPopoverOpenExactlyOnce() {
    var openCount = 0
    let view = WindowBackgroundView(theme: .dark) {
      openCount += 1
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.contentView = view

    NotificationCenter.default.post(
      name: NSWindow.didBecomeKeyNotification,
      object: window
    )
    NotificationCenter.default.post(
      name: NSWindow.didBecomeKeyNotification,
      object: window
    )

    XCTAssertEqual(openCount, 1)

    NotificationCenter.default.post(
      name: NSWindow.didResignKeyNotification,
      object: window
    )
    NotificationCenter.default.post(
      name: NSWindow.didBecomeKeyNotification,
      object: window
    )

    XCTAssertEqual(openCount, 2)
    window.contentView = nil
  }
}
