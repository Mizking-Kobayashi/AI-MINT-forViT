import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var images: [NSImage] = []
    @State private var isCapturing: Bool = false // 撮影開始/停止のフラグ
    @State private var predictionResult: String? = nil // 予測結果を表示するための状態

    // AIモデルのハンドラーをインスタンス化
    private let modelHandler = AIModelHandler()
    private let imagePreprocessor = ImagePreprocessor() // ImagePreprocessor のインスタンスを追加

    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                CameraView(isCapturing: $isCapturing, onCapture: { capturedImage in
                    print("Captured image received")
                    if images.count < 98 {
                        images.append(capturedImage)
                        print("Current image count: \(images.count)")
                    }

                    // 98枚の画像が揃ったら予測を実行
                    if images.count == 98 {
                        isCapturing = false
                        predictFromImages()
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
                    predictionResult = nil // 結果もリセット
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

            // 予測結果を表示
            if let result = predictionResult {
                Text("予測結果: \(result)")
                    .font(.headline)
                    .padding()
            }
        }
    }

    private func predictFromImages() {
        print("画像をAIモデルに送信します...")

        // ImagePreprocessor を使って画像を前処理する
        guard let preprocessedMultiArray = imagePreprocessor.preprocessImages(images: images) else {
            print("画像の前処理に失敗しました")
            predictionResult = "画像の前処理に失敗しました"
            return
        }
        
        print(preprocessedMultiArray.shape)

        // モデルの予測を呼び出す
        if let result = modelHandler.predict(images: preprocessedMultiArray) { // 修正: 引数ラベルを `images:` に変更
            predictionResult = result
            print("予測結果: \(result)")
        } else {
            print("予測に失敗しました")
            predictionResult = "予測に失敗しました"
        }
    }

}

#Preview {
    ContentView()
}
