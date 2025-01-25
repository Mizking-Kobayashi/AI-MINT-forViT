import CoreML
import SwiftUI

class AIModelHandler {
    private var model: AI_MINT_ViT1?

    init() {
        // CoreML モデルを初期化
        if let modelURL = Bundle.main.url(forResource: "AI-MINT-ViT1", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                print("MLModel が正常にロードされました: \(mlModel)")
                    
                self.model = try AI_MINT_ViT1(model: mlModel)
                print("モデルが正常に初期化されました: \(String(describing: self.model))")
            } catch {
                print("モデルの初期化中にエラーが発生しました: \(error)")
            }
        } else {
            print("モデルファイルが見つかりません")
        }
    }

    // ラベルマップ
    let labelMap: [String: Int] = [
        "ぜろ": 0, "いち": 1, "に": 2, "さん": 3, "よん": 4, "ご": 5,
        "ろく": 6, "なな": 7, "はち": 8, "きゅう": 9, "ありがとう": 10,
        "いいえ": 11, "おはよう": 12, "おめでとう": 13, "おやすみ": 14,
        "ごめんなさい": 15, "こんにちわ": 16, "こんばんわ": 17, "さようなら": 18,
        "すみません": 19, "どういたしまして": 20, "はい": 21, "はじめまして": 22,
        "またね": 23, "もしもし": 24
    ]

    // 前処理済みの画像を予測する関数
    func predict(images multiArray: MLMultiArray, completion: @escaping (String?) -> Void) {
        guard let model = self.model else {
            print("モデルが初期化されていません")
            completion(nil)
            return
        }

        // バックグラウンドで非同期処理を実行
        DispatchQueue.global(qos: .userInitiated).async {
            let input = AI_MINT_ViT1Input(input_1: multiArray)

            do {
                let prediction = try model.prediction(input: input)

                if let output = prediction.featureValue(for: "Identity"),
                   let multiArray = output.multiArrayValue {
                    var maxIndex = 0
                    var maxValue: Float = -Float.greatestFiniteMagnitude

                    // 最大値を求めるループ
                    for i in 0..<multiArray.count {
                        let value = multiArray[i].floatValue
                        if value > maxValue {
                            maxValue = value
                            maxIndex = i
                        }
                    }

                    // ラベルを取得
                    let predictedLabel = self.labelMap.first { $0.value == maxIndex }?.key

                    // メインスレッドに結果を返す
                    DispatchQueue.main.async {
                        print("予測結果: \(predictedLabel ?? "不明")")
                        completion(predictedLabel)
                    }
                } else {
                    print("出力値が見つかりません")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("予測に失敗しました: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
