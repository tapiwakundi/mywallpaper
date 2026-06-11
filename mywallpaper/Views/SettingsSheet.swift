//
//  SettingsSheet.swift
//  mywallpaper
//

import SwiftUI

struct SettingsSheet: View {
    @Environment(WallpaperManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    @State private var showStopConfirmation = false

    var body: some View {
        @Bindable var manager = manager

        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $manager.showOnLockScreen) {
                        Label("Show on Lock Screen", systemImage: "lock.display")
                    }
                    .onChange(of: manager.showOnLockScreen) { _, newValue in
                        manager.setShowOnLockScreen(newValue)
                    }

                    Toggle(isOn: $manager.launchAtLogin) {
                        Label("Launch at Login", systemImage: "power")
                    }
                    .onChange(of: manager.launchAtLogin) { _, newValue in
                        manager.setLaunchAtLogin(newValue)
                    }
                }
                .padding(4)
            }

            if manager.isWallpaperActive {
                Button("Stop Wallpaper", role: .destructive) {
                    showStopConfirmation = true
                }
            }

            if let error = manager.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 360, height: 280)
        .confirmationDialog(
            "Stop live wallpaper?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Stop Wallpaper", role: .destructive) {
                manager.stopWallpaper()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your desktop will return to its previous static wallpaper.")
        }
    }
}
