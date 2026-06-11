//
//  MainWindowController.swift
//  mywallpaper
//

import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSObject {
    static let shared = MainWindowController()

    private var window: NSWindow?
    private let windowDelegate = MainWindowDelegate()

    func show() {
        // Defer until after the menu bar menu closes, otherwise the previously
        // frontmost app reclaims activation.
        DispatchQueue.main.async { [self] in
            presentMainWindow()
        }
    }

    private func presentMainWindow() {
        NSApp.setActivationPolicy(.regular)

        if window == nil {
            let hostingController = NSHostingController(
                rootView: ContentView()
                    .environment(WallpaperManager.shared)
                    .frame(minWidth: 900, minHeight: 640)
            )

            let window = NSWindow(contentViewController: hostingController)
            window.identifier = NSUserInterfaceItemIdentifier("mywallpaper.main")
            window.setContentSize(NSSize(width: 1100, height: 760))
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = windowDelegate
            self.window = window
        }

        guard let window else { return }

        applyWindowChrome(to: window)
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func applyWindowChrome(to window: NSWindow) {
        window.title = "MyWallpaper"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.toolbar?.displayMode = .iconOnly
    }
}

private final class MainWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
