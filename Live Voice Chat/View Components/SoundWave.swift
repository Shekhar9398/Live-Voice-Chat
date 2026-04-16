//
//  SoundWave.swift
//  Live Voice Chat
//
//  Created by Mac on 16/04/26.
//

import SwiftUI

// MARK: - Sound Wave
struct SoundWave: View {
    let isActive: Bool
    private let barCount = 5

    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(AppTheme.labelDark)
                    .frame(width: 3, height: height(for: index))
            }
        }
        .frame(width: 28, height: 22)
        .onAppear { if isActive { animate() } }
        .onChange(of: isActive) { newValue in
            if newValue { animate() }
        }
    }

    private func height(for index: Int) -> CGFloat {
        guard isActive else { return 4 }
        let offset = CGFloat(index) * 0.6
        let wave = sin(phase + offset)
        return 6 + abs(wave) * 14
    }

    private func animate() {
        phase = 0
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }
}
