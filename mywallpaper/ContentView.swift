//
//  ContentView.swift
//  mywallpaper
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WallpaperGalleryView()
            .frame(minWidth: 820, minHeight: 580)
    }
}

#Preview {
    ContentView()
        .environment(WallpaperManager.shared)
}
