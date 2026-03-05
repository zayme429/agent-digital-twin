import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager

    private var completedCount: Int { scheduleManager.cards.filter { $0.isPosted }.count }
    private var totalCount:     Int { scheduleManager.cards.count }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // App title + status
            VStack(alignment: .leading, spacing: 5) {
                Text("代理人数字孪生")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(r: 0.0, g: 0.9, b: 0.4).opacity(0.28))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(Color(r: 0.0, g: 0.9, b: 0.4))
                            .frame(width: 7, height: 7)
                    }
                    Text("系统运行中")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }

            Spacer()

            // Progress ring + count
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                    .frame(width: 54, height: 54)

                Circle()
                    .trim(from: 0, to: totalCount > 0
                          ? CGFloat(completedCount) / CGFloat(totalCount) : 0)
                    .stroke(
                        LinearGradient(colors: [Color(r: 0.0, g: 0.8, b: 0.5),
                                                Color(r: 0.0, g: 0.6, b: 0.9)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: completedCount)

                VStack(spacing: 0) {
                    Text("\(completedCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/\(totalCount)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }
}
