//
//  OpenSourceScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import PlatformSwiftUI
import SwiftUI
#if os(iOS)
import WebKit
#endif

/// 오픈소스 이용내역 화면
struct OpenSourceUsageScreen: View {
    let openSourceList = OpenSourceItem.items

    var body: some View {
        List {
            ForEach(openSourceList) { item in
                #if os(iOS)
                NavigationLink {
                    SafariView(url: item.url)
                        .navigationTitle(item.name)
                        .inlineNavigationTitle()
                } label: {
                    rowContent(for: item)
                }
                #else
                Link(destination: item.url) {
                    rowContent(for: item)
                }
                .buttonStyle(.plain)
                #endif
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        .listStyle(.plain)
        #endif
        .navigationTitle("오픈소스 라이선스")
        .inlineNavigationTitle()
    }

    private func rowContent(for item: OpenSourceItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(item.license)
                .font(.caption)
                .foregroundStyle(Color.tertiaryLabelColor)

            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#if os(iOS)
struct SafariView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(.init(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        OpenSourceUsageScreen()
    }
}
