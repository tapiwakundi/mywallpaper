//
//  ContentView.swift
//  mywallpaper
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WallpaperGalleryView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .configureAppWindow()
    }
}

#Preview {
    ContentView()
        .environment(WallpaperManager.shared)
        .frame(width: 980, height: 720)
}
