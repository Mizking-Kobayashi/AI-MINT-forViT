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
            ZStack(alignment: .top) { // ZStackを使ってカメラの上にテキストを重ねる
                CameraView(isCapturing: $isCapturing) { capturedImage in
                    if images.count < 98 {
                        images.append(capturedImage) // 画像を配列に追加
                    }
                }
                .frame(width: 640, height: 480)
                
                // 赤枠を描画（もし必要なら）
                Rectangle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .position(x: 640 / 2, y: 480 / 2) // カメラフレームの中央に配置

                .frame(width: 640, height: 480, alignment: .top) // カメラサイズに合わせて上に揃える
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
                    .cornerRadius(10)
            }
            .padding()
        }
}

#Preview {
    ContentView()
}
