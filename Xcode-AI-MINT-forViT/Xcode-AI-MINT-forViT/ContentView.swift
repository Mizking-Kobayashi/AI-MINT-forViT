//
//  ContentView.swift
//  AI-MINT-forViT
//
//  Created by Mizking-Kobayashi on 2024/12/19.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var images: [NSImage] = []
    @State private var isCapturing: Bool = false // 撮影開始/停止のフラグ

    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                CameraView(isCapturing: $isCapturing, onCapture: { capturedImage in
                    print("Captured image received")
                    if images.count < 98 {
                        images.append(capturedImage)
                        print("Current image count: \(images.count)")
                    }
                }, onCaptureComplete: {
                    print("撮影完了 - ContentView 側")
                    isCapturing = false // 明示的に更新
                })
                .frame(width: 640, height: 480)

                // 赤枠の描画
                Rectangle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
            }
            .padding()

            // 撮影開始ボタン
            Button(action: {
                if !isCapturing {
                    images.removeAll() // 新しい撮影を開始する前に画像をリセット
                    isCapturing = true
                }
            }) {
                Text(isCapturing ? "撮影中..." : "撮影開始")
                    .font(.title)
                    .padding()
                    .background(isCapturing ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
