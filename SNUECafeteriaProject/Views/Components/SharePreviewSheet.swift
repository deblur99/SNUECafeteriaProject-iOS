//
//  SharePreviewSheet.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// 공유할 이미지를 미리보기로 제공하는 시트
struct SharePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 이미지 미리보기
                ScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 120) // 플로팅 버튼과 겹치지 않는 여백
                }

                // 파티클 + 공유 버튼
                ZStack {
                    ParticleEmitter()
                    ShareLink(
                        item: TransferableImage(uiImage: image),
                        preview: SharePreview(
                            "서울교대 학식 메뉴",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Label("공유하기", systemImage: "square.and.arrow.up")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glassProminent)
                }
                .shadow(radius: 4, y: 2)
                .padding(.bottom, 48)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("공유 미리보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// ShareLink에서 UIImage를 전달하기 위한 Transferable 래퍼
private struct TransferableImage: Transferable {
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.uiImage.pngData() else {
                throw TransferError.conversionFailed
            }
            return data
        }
    }

    private enum TransferError: Error {
        case conversionFailed
    }
}

// MARK: - Particle animation

/// 라이트/다크 모드 모두에서 인식되는 따뜻한 스파클 색상 팔레트
private let sparkleColors: [Color] = [
    Color(hue: 0.12, saturation: 0.90, brightness: 1.00),  // 황금 amber
    Color(hue: 0.07, saturation: 0.80, brightness: 1.00),  // 오렌지
    Color(hue: 0.00, saturation: 0.65, brightness: 1.00),  // 로즈 레드
    Color(hue: 0.83, saturation: 0.55, brightness: 0.95),  // 라벤더
    Color(hue: 0.55, saturation: 0.70, brightness: 1.00),  // 스카이 블루
]

private struct Particle: Identifiable {
    let id = UUID()
    let xOffset: CGFloat
    let yStart: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let baseOpacity: Double
    let color: Color
}

private struct FloatingParticleView: View {
    let particle: Particle
    @State private var risen = false

    var body: some View {
        Circle()
            .fill(particle.color.opacity(risen ? 0 : particle.baseOpacity))
            .frame(width: particle.size, height: particle.size)
            // 글로우 섀도우: 라이트모드에서도 파티클이 도드라지게
            .shadow(color: particle.color.opacity(risen ? 0 : 0.9), radius: 4, x: 0, y: 0)
            .offset(
                x: particle.xOffset,
                y: risen ? particle.yStart - 95 : particle.yStart
            )
            .animation(
                .easeOut(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                    .delay(particle.delay),
                value: risen
            )
            .onAppear { risen = true }
    }
}

/// 버튼 뒤에서 천천히 맥동하는 헤일로(halo) 링
private struct PulsingHalo: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: sparkleColors + [sparkleColors[0]],
                    center: .center
                ),
                lineWidth: 1.5
            )
            .frame(width: pulsing ? 140 : 100, height: pulsing ? 140 : 100)
            .opacity(pulsing ? 0 : 0.55)
            .animation(
                .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                value: pulsing
            )
            .onAppear { pulsing = true }
    }
}

private struct ParticleEmitter: View {
    @State private var particles: [Particle] = (0..<22).map { _ in
        Particle(
            xOffset:     .random(in: -80...80),
            yStart:      .random(in: -4...6),
            size:        .random(in: 3...7),
            duration:    .random(in: 1.1...2.3),
            delay:       .random(in: 0...2.2),
            baseOpacity: .random(in: 0.75...1.0),
            color:       sparkleColors.randomElement()!
        )
    }

    var body: some View {
        ZStack {
            PulsingHalo()
            ForEach(particles) { particle in
                FloatingParticleView(particle: particle)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    SharePreviewSheet(image: UIImage(named: "today_meal_sample")!)
}
