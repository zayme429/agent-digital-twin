import SwiftUI

struct StarData: Identifiable {
    let id    = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double

    init() {
        x       = CGFloat.random(in: 0...1)
        y       = CGFloat.random(in: 0...1)
        size    = CGFloat.random(in: 1.0...2.8)
        opacity = Double.random(in: 0.08...0.55)
    }
}

struct StarsView: View {
    private let stars: [StarData] = (0..<100).map { _ in StarData() }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity)
                    .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
            }
        }
    }
}
