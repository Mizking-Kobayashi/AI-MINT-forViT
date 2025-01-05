import SwiftUI

struct ScrollingTextView: View {
    let text: String
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer() // テキストを上に配置するためのスペース
                Text(text)
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(.white) // テキストの色を白に変更
                    .offset(x: offset)
                    .shadow(color: .black, radius: 3, x: 2, y: 2) // テキストに影を追加
                    .onAppear {
                        offset = geometry.size.width
                        withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                            offset = -geometry.size.width
                        }
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top) // 上寄せ
        }
        .frame(height: 50) // テキストの高さに合わせて調整
    }
}
