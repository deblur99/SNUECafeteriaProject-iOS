//
//  CGImagePNGEncoder.swift
//  Shared
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// `ImageRenderer.cgImage` 결과를 플랫폼 공통 PNG Data로 인코딩한다.
nonisolated enum CGImagePNGEncoder {
    static func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
