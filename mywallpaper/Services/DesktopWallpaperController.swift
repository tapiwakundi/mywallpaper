//
//  DesktopWallpaperController.swift
//  mywallpaper
//

import AppKit
import AVFoundation

@MainActor
final class DesktopWallpaperController {
    private var windows: [NSScreen: NSWindow] = [:]

    func apply(_ wallpaper: WallpaperItem) {
        stop()
        refreshWindows(for: wallpaper)
        observeScreenChanges(for: wallpaper)
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        for window in windows.values {
            window.orderOut(nil)
            window.contentView = nil
        }
        windows.removeAll()
    }

    private func refreshWindows(for wallpaper: WallpaperItem) {
        for window in windows.values {
            window.orderOut(nil)
            window.contentView = nil
        }
        windows.removeAll()

        for screen in NSScreen.screens {
            let window = makeWindow(on: screen, wallpaper: wallpaper)
            windows[screen] = window
            window.orderFront(nil)
        }
    }

    private func makeWindow(on screen: NSScreen, wallpaper: WallpaperItem) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = true
        window.backgroundColor = .black
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.setFrame(screen.frame, display: true)

        guard let url = wallpaper.playbackURL() else { return window }

        let playerView = LoopingVideoNSView(frame: window.contentView?.bounds ?? screen.frame)
        playerView.autoresizingMask = [.width, .height]
        playerView.configure(url: url, muted: true)
        window.contentView = playerView
        window.orderFront(nil)

        return window
    }

    private func observeScreenChanges(for wallpaper: WallpaperItem) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshWindows(for: wallpaper)
            }
        }
    }
}
