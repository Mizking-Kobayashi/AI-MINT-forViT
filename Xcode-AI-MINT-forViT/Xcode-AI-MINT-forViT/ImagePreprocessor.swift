//
//  ImagePreprocessor.swift
//  Xcode-AI-MINT-forViT
//
//  Created by Mizking-Kobayashi on 2024/12/25.
//

import Foundation
import CoreML
import Vision
import AppKit

class ImagePreprocessor {
    // 画像を指定された形状に変換する関数
    func preprocessImages(images: [NSImage]) -> MLMultiArray? {
        let batchSize = 1
        let numFrames = 98
        let patchSize = 16
        let vectorSize = patchSize * patchSize * 1 // グレースケール（チャンネル数 1 を想定）

        guard images.count == numFrames else {
            print("画像数が 98 枚ではありません")
            return nil
        }

        // MultiArray の初期化
        guard let multiArray = try? MLMultiArray(shape: [batchSize, numFrames, 16, 256] as [NSNumber], dataType: .float32) else {
            print("MLMultiArray の初期化に失敗しました")
            return nil
        }


        for (frameIndex, image) in images.enumerated() {
            // NSImage をリサイズ
            guard let resizedImage = resizeImage(image, size: CGSize(width: 64, height: 64)) else {
                print("画像のリサイズに失敗しました")
                return nil
            }

            // NSImage を 16×16 のパッチに分割
            let patches = extractPatches(from: resizedImage, patchSize: patchSize)

            for (patchIndex, patch) in patches.enumerated() {
                let flattenedPatch = patch.compactMap { $0 } // 16×16 をフラット化
                for (valueIndex, value) in flattenedPatch.enumerated() {
                    let arrayIndex = [0, frameIndex, patchIndex, valueIndex] as [NSNumber]
                    multiArray[arrayIndex] = NSNumber(value: Float32(value) / 255.0) // 正規化
                }
            }
        }
        return multiArray
    }

    // NSImage をリサイズする関数
    func resizeImage(_ image: NSImage, size: CGSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    // 画像をパッチに分割する関数
    func extractPatches(from image: NSImage, patchSize: Int) -> [[UInt8]] {
        guard let bitmap = imageToBitmap(image) else { return [] }

        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let patchCount = width / patchSize

        var patches: [[UInt8]] = []
        for row in 0..<patchCount {
            for col in 0..<patchCount {
                var patch: [UInt8] = []
                for y in 0..<patchSize {
                    for x in 0..<patchSize {
                        let pixelIndex = (row * patchSize + y) * width + (col * patchSize + x)
                        patch.append(bitmap[pixelIndex])
                    }
                }
                patches.append(patch)
            }
        }
        return patches
    }

    // NSImage を UInt8 のビットマップデータに変換
    func imageToBitmap(_ image: NSImage) -> [UInt8]? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let width = Int(bitmap.size.width)
        let height = Int(bitmap.size.height)
        var pixels: [UInt8] = Array(repeating: 0, count: width * height)
        for x in 0..<width {
            for y in 0..<height {
                let color = bitmap.colorAt(x: x, y: y) ?? NSColor.black
                let grayscale = (color.redComponent + color.greenComponent + color.blueComponent) / 3.0
                pixels[y * width + x] = UInt8(grayscale * 255)
            }
        }
        return pixels
    }
}
