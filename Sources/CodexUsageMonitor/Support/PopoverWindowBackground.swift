import AppKit
import SwiftUI

/// Keeps the native MenuBarExtra window background opaque and colour-matched
/// to the SwiftUI content so the window feels seamless.
struct PopoverWindowBackground: NSViewRepresentable {
  let theme: AppearanceTheme
  let onOpen: () -> Void

  func makeNSView(context: Context) -> WindowBackgroundView {
    WindowBackgroundView(theme: theme, onOpen: onOpen)
  }

  func updateNSView(_ nsView: WindowBackgroundView, context: Context) {
    nsView.apply(theme: theme, onOpen: onOpen)
  }
}

final class WindowBackgroundView: NSView {
  private var theme: AppearanceTheme
  private var onOpen: () -> Void
  private var isPresented = false

  init(theme: AppearanceTheme, onOpen: @escaping () -> Void) {
    self.theme = theme
    self.onOpen = onOpen
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func viewWillMove(toWindow newWindow: NSWindow?) {
    if let window {
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.didBecomeKeyNotification,
        object: window
      )
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.didResignKeyNotification,
        object: window
      )
    }
    isPresented = false
    super.viewWillMove(toWindow: newWindow)
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    apply(theme: theme, onOpen: onOpen)
    if let window {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidBecomeKey(_:)),
        name: NSWindow.didBecomeKeyNotification,
        object: window
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidResignKey(_:)),
        name: NSWindow.didResignKeyNotification,
        object: window
      )
      if window.isKeyWindow {
        notifyOpenIfNeeded()
      }
    }
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    guard theme == .system else { return }
    window?.backgroundColor = .monitorWindowBackground
  }

  func apply(theme: AppearanceTheme, onOpen: @escaping () -> Void) {
    self.theme = theme
    self.onOpen = onOpen
    guard let window else { return }
    window.isOpaque = false
    window.appearance = theme.appKitAppearance
    window.backgroundColor = .monitorWindowBackground
  }

  @objc private func windowDidBecomeKey(_ notification: Notification) {
    notifyOpenIfNeeded()
  }

  @objc private func windowDidResignKey(_ notification: Notification) {
    isPresented = false
  }

  private func notifyOpenIfNeeded() {
    guard !isPresented else { return }
    isPresented = true
    onOpen()
  }
}
