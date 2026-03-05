import SwiftUI

struct ConfirmExecuteSheet: View {
    let card: ScheduleCard
    let persona: AgentPersona
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                Spacer()

                // Sheet panel
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 38, height: 5)
                        .padding(.top, 14)
                        .padding(.bottom, 28)

                    // Platform icon circle
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: card.platform.gradientColors,
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 68, height: 68)
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: card.platform.primaryColor.opacity(0.55), radius: 18, y: 6)
                    .padding(.bottom, 18)

                    // Title
                    Text("确认执行任务")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    // Task name badge
                    HStack(spacing: 6) {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(card.platform.rawValue) · \(card.title)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(colors: card.platform.gradientColors,
                                       startPoint: .leading, endPoint: .trailing)
                            .clipShape(Capsule())
                    )
                    .padding(.bottom, 22)

                    // What will happen
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.45))
                            Text("代理人将全自动执行以下步骤")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.45))
                        }

                        VStack(alignment: .leading, spacing: 9) {
                            AutoStepRow(
                                icon: "wand.and.stars.inverse",
                                text: "以「\(persona.name)」人设自动生成\(card.platform.rawValue)内容")
                            AutoStepRow(
                                icon: "checkmark.shield.fill",
                                text: "自动完成内容审核与风格优化")
                            AutoStepRow(
                                icon: card.platform.icon,
                                text: "发布至 \(card.platform.rawValue)")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Confirm button
                    Button(action: onConfirm) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("确认执行")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: card.platform.gradientColors,
                                           startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedRectangle(cornerRadius: 17))
                        )
                        .shadow(color: card.platform.primaryColor.opacity(0.5), radius: 16, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                    // Cancel
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.bottom, 40)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(r: 0.063, g: 0.048, b: 0.150))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .ignoresSafeArea()
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct AutoStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.55))
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.78))
        }
    }
}
