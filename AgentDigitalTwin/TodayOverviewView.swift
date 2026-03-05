import SwiftUI

// MARK: - Today Overview (full-day timeline strip)
struct TodayOverviewView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日总览")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.45))
                    Text(dateString)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                let done  = scheduleManager.completedCards.count
                let total = scheduleManager.cards.count
                HStack(spacing: 4) {
                    Text("\(done)/\(total)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("已执行")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(scheduleManager.timelineCards.enumerated()), id: \.element.id) { idx, card in
                        TimelineDot(
                            card: card,
                            isLast: idx == scheduleManager.timelineCards.count - 1
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 12)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - Single Timeline Dot
private struct TimelineDot: View {
    let card: ScheduleCard
    let isLast: Bool

    private var isDue: Bool { card.scheduledTime <= Date() && !card.isPosted }

    private var timeStr: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale    = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 5) {
                Text(timeStr)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .frame(width: 52)

                ZStack {
                    Circle()
                        .fill(card.isPosted
                            ? card.platform.primaryColor.opacity(0.20)
                            : isDue
                                ? Color(r: 1.0, g: 0.6, b: 0.1).opacity(0.20)
                                : Color.white.opacity(0.06))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle().stroke(
                                card.isPosted
                                    ? card.platform.primaryColor
                                    : isDue
                                        ? Color(r: 1.0, g: 0.6, b: 0.1)
                                        : Color.white.opacity(0.18),
                                lineWidth: 1.5
                            )
                        )

                    if card.isPosted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(card.platform.primaryColor)
                    } else {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isDue
                                ? Color(r: 1.0, g: 0.6, b: 0.1)
                                : card.platform.primaryColor.opacity(0.6))
                    }
                }

                Text(card.platform.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(card.isPosted
                        ? card.platform.primaryColor
                        : Color.white.opacity(0.38))
                    .frame(width: 52)
                    .multilineTextAlignment(.center)

                if isDue {
                    Text("待执行")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(r: 1.0, g: 0.6, b: 0.1))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color(r: 1.0, g: 0.6, b: 0.1).opacity(0.18))
                        )
                }
            }

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 20, height: 1)
                    .padding(.bottom, 26) // align with circle center
            }
        }
    }
}

// MARK: - Section header helper
struct SectionHeader: View {
    let title: String
    let count: Int
    var accentColor: Color = Color.white.opacity(0.5)

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text("\(count)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(accentColor.opacity(0.15)))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
