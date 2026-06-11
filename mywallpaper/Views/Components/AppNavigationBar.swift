//
//  AppNavigationBar.swift
//  mywallpaper
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case explore
    case myMedia

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .explore: "Explore"
        case .myMedia: "My Media"
        }
    }
}

struct ToolbarSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 88)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }
}

struct ToolbarTabPicker: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.title)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(
                                selectedTab == tab ? .regular.tint(.primary.opacity(0.08)).interactive() : .clear,
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .glassEffect(.regular, in: .capsule)
        }
    }
}

struct ToolbarActionButtons: View {
    var onUpload: () -> Void
    var onSettings: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onUpload) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .glassCircle()

                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .glassCircle()
            }
        }
    }
}
