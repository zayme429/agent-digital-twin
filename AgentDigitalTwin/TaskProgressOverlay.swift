import SwiftUI

struct TaskProgressOverlay: View {
    let card: ScheduleCard
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}     // called once when progress reaches 100 %

    @State private var progress: CGFloat = 0.0
    @State private var statusText        = "正在初始化任务..."
    @State private var currentStep: Int  = 0
    @State private var isCompleted       = false
    @State private var showCheckmark     = false
    @State private var didFireComplete   = false

    private let duration: Double = Double.random(in: 20...25)

    private let milestones: [(threshold: Double, text: String)] = [
        (0.00, "正在初始化任务..."),
        (0.15, "连接平台接口..."),
        (0.30, "生成个性化内容..."),
        (0.45, "验证发布权限..."),
        (0.60, "上传媒体资源..."),
        (0.75, "格式化内容..."),
        (0.88, "最终审核中..."),
        (0.95, "正在发布..."),
        (1.00, "发布成功！"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.90)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Platform badge
                HStack(spacing: 7) {
                    Image(systemName: card.platform.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(card.platform.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(colors: card.platform.gradientColors,
                                   startPoint: .leading, endPoint: .trailing)
                        .clipShape(Capsule())
                )
                .padding(.bottom, 36)

                // Circular ring
                ZStack {
                    Circle()
                        .stroke(card.platform.primaryColor.opacity(0.10), lineWidth: 22)
                        .frame(width: 210, height: 210)

                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 13)
                        .frame(width: 186, height: 186)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: card.platform.gradientColors + [card.platform.primaryColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle:   .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 13, lineCap: .round)
                        )
                        .frame(width: 186, height: 186)
                        .rotationEffect(.degrees(-90))

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(card.platform.primaryColor)
                            .scaleEffect(showCheckmark ? 1.0 : 0.4)
                            .opacity(showCheckmark ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.bottom, 32)

                Text(card.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.60))
                    .animation(.easeInOut(duration: 0.3), value: statusText)
                    .padding(.bottom, 28)

                // Step dots
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { i in
                        Capsule()
                            .fill(i < currentStep
                                  ? card.platform.primaryColor
                                  : Color.white.opacity(0.15))
                            .frame(width: i < currentStep ? 22 : 8, height: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                    }
                }
                .padding(.bottom, 36)

                if isCompleted {
                    Button { dismiss() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("完成")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(
                            LinearGradient(colors: card.platform.gradientColors,
                                           startPoint: .leading, endPoint: .trailing)
                                .clipShape(Capsule())
                        )
                        .shadow(color: card.platform.primaryColor.opacity(0.5), radius: 16, y: 6)
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear { startProgress() }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
    }

    private func startProgress() {
        withAnimation(.linear(duration: duration)) { progress = 1.0 }

        for (i, m) in milestones.enumerated() {
            let delay = m.threshold * duration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    statusText  = m.text
                    currentStep = min(i, 7)
                }
                if m.threshold >= 1.0 && !didFireComplete {
                    didFireComplete = true
                    onComplete()                        // notify parent → execute card
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isCompleted = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showCheckmark = true
                    }
                }
            }
        }
    }
}
