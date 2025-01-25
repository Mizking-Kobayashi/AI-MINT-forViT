import Vision
import AVFoundation
import SwiftUI

class FaceLandmarkDetector: ObservableObject {
    @Published var landmarks: [(CGFloat, CGFloat)] = []

    func detectLandmarks(from image: CGImage) {
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.processResults(request.results)
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("顔の検出に失敗しました: \(error)")
            }
        }
    }

    private func processResults(_ results: [Any]?) {
        guard let faceObservations = results as? [VNFaceObservation] else { return }
        
        var newLandmarks: [(CGFloat, CGFloat)] = []
        for face in faceObservations {
            if let landmarks = face.landmarks {
                let allRegions: [VNFaceLandmarkRegion2D?] = [
                    landmarks.faceContour,
                    landmarks.leftEyebrow, landmarks.rightEyebrow,
                    landmarks.leftEye, landmarks.rightEye,
                    landmarks.nose, landmarks.noseCrest,
                    landmarks.outerLips, landmarks.innerLips
                ]
                
                for region in allRegions {
                    if let points = region?.normalizedPoints {
                        newLandmarks.append(contentsOf: self.convertPoints(points, boundingBox: face.boundingBox))
                    }
                }
            }
        }
        self.landmarks = newLandmarks
    }

    private func convertPoints(_ points: [CGPoint], boundingBox: CGRect) -> [(CGFloat, CGFloat)] {
        return points.map { point in
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + point.y * boundingBox.height
            return (x, 1 - y) // SwiftUIの座標系に合わせて Y 軸を反転
        }
    }
}
