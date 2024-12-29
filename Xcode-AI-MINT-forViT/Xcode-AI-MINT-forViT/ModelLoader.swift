//
//  ModelLoader.swift
//  Xcode-AI-MINT-forViT
//
//  Created by Mizking-Kobayashi on 2024/12/24.
//

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
    func predict(images multiArray: MLMultiArray) -> String? {
        guard let model = self.model else {
            print("モデルが初期化されていません")
            return nil
        }

        // モデルに入力するためにAI_MINT_ViT1Inputを作成
        let input = AI_MINT_ViT1Input(input_1: multiArray)

        // モデルを使って予測する処理
        do {
            // 予測メソッドを呼び出し、AI_MINT_ViT1Inputを入力として渡す
            let prediction = try model.prediction(input: input)
            print(prediction)

            // 出力型を確認
            if let output = prediction.featureValue(for: "Identity") {
                // 出力が MultiArray 形式の場合、型にキャストして取り出す
                if let multiArray = output.multiArrayValue {
                    // 最大確率のインデックスを取得
                    var maxIndex = 0
                    var maxValue: Float = -Float.greatestFiniteMagnitude

                    // 最大確率を持つインデックスを検索
                    for i in 0..<multiArray.count {
                        let value = multiArray[i].floatValue
                        if value > maxValue {
                            maxValue = value
                            maxIndex = i
                        }
                    }

                    // 最大インデックスに対応するラベルを返す
                    let predictedLabel = labelMap.first { $0.value == maxIndex }?.key
                    if let label = predictedLabel {
                        print("予測結果: \(label)")
                        return label
                    } else {
                        print("無効なインデックスです")
                    }
                } else {
                    print("MultiArray に変換できませんでした")
                }
            } else {
                print("出力値が見つかりません")
            }
        } catch {
            print("予測に失敗しました: \(error)")
            return nil
        }

        // 結果が得られなかった場合
        return nil
    }

}
