//
//  OpenSourceScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI
import WebKit

/// 오픈소스 이용내역 화면
struct OpenSourceUsageScreen: View {
    let openSourceList = OpenSourceItem.items
    
    var body: some View {
        List {
            ForEach(openSourceList) { item in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink {
                        SafariView(url: item.url)
                            .navigationTitle(item.name)
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(item.license)
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .navigationTitle("오픈소스 라이선스")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SafariView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(.init(url: url))
        return webView
    }
    
    func updateUIView(_ uiViewController: WKWebView, context: Context) {}
}

#Preview {
    OpenSourceUsageScreen()
}
