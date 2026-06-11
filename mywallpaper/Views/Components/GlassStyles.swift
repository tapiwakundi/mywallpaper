//
//  GlassStyles.swift
//  mywallpaper
//

import SwiftUI

extension View {
    func glassPill(interactive: Bool = false) -> some View {
        let glass: Glass = interactive ? .regular.interactive() : .regular
        return self
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(glass, in: .capsule)
    }

    func glassCircle(interactive: Bool = true) -> some View {
        let glass: Glass = interactive ? .regular.interactive() : .regular
        return self
            .frame(width: 36, height: 36)
            .glassEffect(glass, in: .circle)
    }

    func glassCard(cornerRadius: CGFloat = 16, interactive: Bool = false) -> some View {
        let glass: Glass = interactive ? .regular.interactive() : .regular
        return self
            .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
    }
}
