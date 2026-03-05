import SwiftUI

struct CardView: View {
    let card: ScheduleCard
    let action: () -> Void

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale    = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Top row ──────────────────────────────────────────
                HStack(spacing: 8) {
                    // Platform badge
                    HStack(spacing: 5) {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(card.platform.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(colors: card.platform.gradientColors,
                                       startPoint: .leading, endPoint: .trailing)
                            .clipShape(Capsule())
                    )

                    if card.isManualTrigger {
                        Text("手动")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(r: 1.0, g: 0.6, b: 0.0)))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.38))
                        Text(timeString)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.55))
                    }

                    Image(systemName: card.isPosted ? "checkmark.circle.fill" : "clock.badge.fill")
                        .font(.system(size: 15))
                        .foregroundColor(card.isPosted
                            ? Color(r: 0.027, g: 0.757, b: 0.376)
                            : Color.white.opacity(0.22))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // ── Content ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(card.content)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(2)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

                // ── Action hint ───────────────────────────────────────
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 10))
                        Text("点击执行任务")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(card.platform.primaryColor.opacity(0.7))
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))

                    RoundedRectangle(cornerRadius: 20)
                        .fill(RadialGradient(
                            colors: [card.platform.primaryColor.opacity(0.10), .clear],
                            center: .topLeading, startRadius: 0, endRadius: 160))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [card.platform.primaryColor.opacity(0.4),
                                         Color.white.opacity(0.07)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
                }
            )
            .shadow(color: card.platform.primaryColor.opacity(0.18), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(CardViewPressStyle())
    }
}

// MARK: - Press feedback style
private struct CardViewPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
