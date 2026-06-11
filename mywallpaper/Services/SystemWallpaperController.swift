//
//  SystemWallpaperController.swift
//  mywallpaper
//

import AppKit

@MainActor
final class SystemWallpaperController {
    private var frameGenerator: VideoFrameGenerator?
    private var syncTimer: Timer?
    private var savedWallpapers: [ObjectIdentifier: URL] = [:]
    private var isScreenLocked = false
    private var workspaceObservers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []
    private var appObservers: [NSObjectProtocol] = []

    private static let frameURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("mywallpaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("lock-screen-frame.jpg")
    }()

    private static let desktopOptions: [NSWorkspace.DesktopImageOptionKey: Any] = [
        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
        .allowClipping: true,
    ]

    func start(url: URL) {
        stop(restoreSaved: false)

        guard let generator = VideoFrameGenerator(url: url) else { return }

        saveCurrentWallpapers()
        frameGenerator = generator
        frameGenerator?.resetPlaybackClock()
        registerObservers()
        syncFrameToSystemWallpaper()
        restartTimer()
    }

    func stop(restoreSaved: Bool = true) {
        syncTimer?.invalidate()
        syncTimer = nil
        unregisterObservers()
        frameGenerator = nil
        isScreenLocked = false

        if restoreSaved {
            restoreSavedWallpapers()
        }
        savedWallpapers.removeAll()
    }

    private func saveCurrentWallpapers() {
        savedWallpapers.removeAll()
        for screen in NSScreen.screens {
            if let url = NSWorkspace.shared.desktopImageURL(for: screen) {
                savedWallpapers[ObjectIdentifier(screen)] = url
            }
        }
    }

    private func restoreSavedWallpapers() {
        for screen in NSScreen.screens {
            guard let savedURL = savedWallpapers[ObjectIdentifier(screen)] else { continue }
            try? NSWorkspace.shared.setDesktopImageURL(savedURL, for: screen, options: Self.desktopOptions)
        }
    }

    private func syncFrameToSystemWallpaper() {
        guard
            let image = frameGenerator?.currentFrameImage(),
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88])
        else {
            return
        }

        do {
            try jpeg.write(to: Self.frameURL, options: .atomic)
        } catch {
            return
        }

        for screen in NSScreen.screens {
            try? NSWorkspace.shared.setDesktopImageURL(Self.frameURL, for: screen, options: Self.desktopOptions)
        }
    }

    private func restartTimer() {
        syncTimer?.invalidate()
        let interval = isScreenLocked ? 0.5 : 1.0
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncFrameToSystemWallpaper()
            }
        }
    }

    private func registerObservers() {
        unregisterObservers()

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()

        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.syncFrameToSystemWallpaper()
                }
            }
        )

        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.frameGenerator?.resetPlaybackClock()
                    self?.syncFrameToSystemWallpaper()
                }
            }
        )

        distributedObservers.append(
            distributedCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.isScreenLocked = true
                    self?.syncFrameToSystemWallpaper()
                    self?.restartTimer()
                }
            }
        )

        distributedObservers.append(
            distributedCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.isScreenLocked = false
                    self?.syncFrameToSystemWallpaper()
                    self?.restartTimer()
                }
            }
        )

        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.syncFrameToSystemWallpaper()
                }
            }
        )
    }

    private func unregisterObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()

        for observer in workspaceObservers {
            workspaceCenter.removeObserver(observer)
        }
        for observer in distributedObservers {
            distributedCenter.removeObserver(observer)
        }
        for observer in appObservers {
            NotificationCenter.default.removeObserver(observer)
        }

        workspaceObservers.removeAll()
        distributedObservers.removeAll()
        appObservers.removeAll()
    }
}
