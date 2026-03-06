import SwiftUI

struct ConfirmExecuteSheet: View {
    let card: ScheduleCard
    let persona: AgentPersona
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var showPreview = false

    private var accent: Color { Color(r: 0.330, g: 0.180, b: 0.780) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(r: 0.85, g: 0.84, b: 0.88))
                        .frame(width: 38, height: 5)
                        .padding(.top, 14)
                        .padding(.bottom, 22)

                    // Platform icon
                    ZStack {
                        Circle()
                            .fill(card.platform.primaryColor.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(card.platform.primaryColor)
                    }
                    .padding(.bottom, 14)

                    // Title
                    Text("确认执行任务")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(r: 0.12, g: 0.10, b: 0.18))
                        .padding(.bottom, 8)

                    // Task badge
                    HStack(spacing: 6) {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(card.platform.rawValue) · \(card.title)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(card.platform.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(card.platform.primaryColor.opacity(0.10)))
                    .padding(.bottom, 20)

                    // Recommended content block
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(accent)
                            Text("推荐发布内容")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(accent)
                            Spacer()
                            // Preview button
                            Button {
                                showPreview = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 10))
                                    Text("预览")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(card.platform.primaryColor)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(card.platform.primaryColor.opacity(0.10)))
                            }
                        }

                        Text(recommendedContent(platform: card.platform, persona: persona))
                            .font(.system(size: 13))
                            .foregroundColor(Color(r: 0.25, g: 0.22, b: 0.35))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accent.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Auto-steps
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                            Text("代理人将全自动执行以下步骤")
                                .font(.system(size: 12))
                                .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            AutoStepRow(icon: "wand.and.stars.inverse",
                                        text: "以「\(persona.name)」人设自动生成\(card.platform.rawValue)内容")
                            AutoStepRow(icon: "checkmark.shield.fill",
                                        text: "自动完成内容审核与风格优化")
                            AutoStepRow(icon: card.platform.icon,
                                        text: "发布至 \(card.platform.rawValue)")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(r: 0.960, g: 0.958, b: 0.972)))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // Confirm button
                    Button(action: onConfirm) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("确认执行")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16).fill(accent))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Cancel
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                    }
                    .padding(.bottom, 40)
                }
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.white).ignoresSafeArea())
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPreview) {
            ContentPreviewView(card: card, persona: persona,
                               content: recommendedContent(platform: card.platform, persona: persona))
                .presentationDetents([.large])
        }
    }
}

// MARK: - Content Preview Sheet

struct ContentPreviewView: View {
    let card: ScheduleCard
    let persona: AgentPersona
    let content: String
    @Environment(\.dismiss) private var dismiss

    // Full quoted body (keeps all lines inside 「」)
    private var bodyText: String {
        if let start = content.range(of: "「"),
           let end   = content.range(of: "」", range: start.upperBound..<content.endIndex) {
            return String(content[start.upperBound..<end.lowerBound])
        }
        return content
    }

    private var styleTag: String {
        if let r = content.range(of: "风格："),
           let nl = content[r.upperBound...].range(of: "\n") {
            return String(content[r.upperBound..<nl.lowerBound])
        }
        return persona.name
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Platform mockup
                    platformMockup
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Full content card — always show everything
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.plaintext.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("完整推荐内容")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Text(content)
                            .font(.system(size: 14))
                            .foregroundColor(Color(r: 0.15, g: 0.13, b: 0.22))
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(r: 0.94, g: 0.94, b: 0.96))
            .navigationTitle("\(card.platform.rawValue) · 内容预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var platformMockup: some View {
        switch card.platform {
        case .wechatMoments:  MomentsMockup(persona: persona, text: bodyText, style: styleTag)
        case .xiaohongshu:    XhsMockup(persona: persona, text: bodyText, title: card.title, style: styleTag, primaryColor: card.platform.primaryColor)
        case .wechatOA:       OAMockup(persona: persona, text: bodyText, title: card.title, style: styleTag)
        case .wechatPrivate:  PrivateMsgMockup(persona: persona, text: bodyText, style: styleTag)
        case .clientMgmt:     ClientMgmtMockup(text: content, primaryColor: card.platform.primaryColor)
        case .meeting:        MeetingMockup(text: content, title: card.title, primaryColor: card.platform.primaryColor)
        }
    }
}

// MARK: - Moments Mockup

private struct MomentsMockup: View {
    let persona: AgentPersona
    let text: String
    let style: String

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                Text("朋友圈")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "camera.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(r: 0.07, g: 0.07, b: 0.07))

            // Post item
            HStack(alignment: .top, spacing: 10) {
                // Avatar
                Circle()
                    .fill(LinearGradient(colors: persona.tone.gradientColors,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Text(persona.emoji).font(.system(size: 20)))

                VStack(alignment: .leading, spacing: 8) {
                    Text(persona.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(r: 0.32, g: 0.45, b: 0.68))

                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(Color(r: 0.12, g: 0.12, b: 0.12))
                        .lineSpacing(3)

                    // Image placeholder
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: persona.tone.gradientColors.map { $0.opacity(0.55) },
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("问候贴图")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        )

                    // Style tag + time
                    HStack {
                        Text("风格：\(style)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("刚刚")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Engagement row
                    HStack(spacing: 20) {
                        Label("赞", systemImage: "hand.thumbsup").font(.system(size: 12)).foregroundColor(.secondary)
                        Label("评论", systemImage: "bubble.right").font(.system(size: 12)).foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Xiaohongshu Mockup

private struct XhsMockup: View {
    let persona: AgentPersona
    let text: String
    let title: String
    let style: String
    let primaryColor: Color

    var body: some View {
        VStack(spacing: 0) {
            // Cover image
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [primaryColor, primaryColor.opacity(0.5)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 240)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                            Text("封面图")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )

                // Gradient overlay at bottom
                LinearGradient(colors: [.clear, .black.opacity(0.4)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 240)
            }

            // Content area
            VStack(alignment: .leading, spacing: 12) {
                // Author row
                HStack(spacing: 8) {
                    Circle()
                        .fill(LinearGradient(colors: persona.tone.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay(Text(persona.emoji).font(.system(size: 16)))
                    Text(persona.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                    Spacer()
                    Text("+关注")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .overlay(Capsule().stroke(primaryColor, lineWidth: 1))
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(r: 0.25, g: 0.25, b: 0.25))
                    .lineSpacing(4)

                // Tags
                HStack(spacing: 6) {
                    ForEach(["#理财规划", "#黄金市场", "#家庭保障"], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12))
                            .foregroundColor(primaryColor)
                    }
                }

                Divider()

                // Engagement bar
                HStack(spacing: 24) {
                    Label("3.2k", systemImage: "heart.fill")
                    Label("128", systemImage: "bubble.right.fill")
                    Label("收藏", systemImage: "star.fill")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - WeChat OA Mockup

private struct OAMockup: View {
    let persona: AgentPersona
    let text: String
    let title: String
    let style: String

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Text("公众号文章")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "ellipsis")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header image
                    LinearGradient(
                        colors: [Color(r: 0.471, g: 0.549, b: 0.714), Color(r: 0.263, g: 0.337, b: 0.502)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.7))
                            Text("推文封面")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))

                        // Author meta
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(colors: persona.tone.gradientColors,
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 28, height: 28)
                                .overlay(Text(persona.emoji).font(.system(size: 14)))
                            Text(persona.name)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text("·")
                                .foregroundColor(.secondary)
                            Text("刚刚")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        Text(text)
                            .font(.system(size: 15))
                            .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                            .lineSpacing(6)

                        // Image placeholder in article
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(r: 0.92, g: 0.92, b: 0.95))
                            .frame(height: 120)
                            .overlay(
                                HStack(spacing: 6) {
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.secondary)
                                    Text("配图")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .padding(16)
                }
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Private Message Mockup

private struct PrivateMsgMockup: View {
    let persona: AgentPersona
    let text: String
    let style: String

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                VStack(spacing: 1) {
                    Text("张总")
                        .font(.system(size: 15, weight: .semibold))
                    Text("在线")
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                }
                Spacer()
                Image(systemName: "ellipsis")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
            .background(Color.white)

            Divider()

            // Chat area
            VStack(spacing: 16) {
                Text("今天 09:00")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                // Sent message (right side)
                HStack(alignment: .top, spacing: 0) {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(r: 0.000, g: 0.690, b: 0.941))
                            )
                            .frame(maxWidth: 240, alignment: .trailing)
                        Text("已发送")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Circle()
                        .fill(LinearGradient(colors: persona.tone.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay(Text(persona.emoji).font(.system(size: 15)))
                        .padding(.leading, 8)
                }

                // Read receipt
                HStack {
                    Spacer()
                    Text("对方已读")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(r: 0.94, g: 0.94, b: 0.96))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Client Management Mockup

private struct ClientMgmtMockup: View {
    let text: String
    let primaryColor: Color

    private let clients: [(name: String, tag: String, action: String, icon: String)] = [
        ("陈**", "潜力跟进", "开门红年金险活动邀约", "arrow.right.circle.fill"),
        ("赵**", "生日祝福", "今日生日 → 发送祝福", "gift.fill"),
        ("王**", "潜力跟进", "发送「开学季支出清单」", "doc.text.fill"),
        ("张**", "老客维系", "体检权益到期提醒", "bell.fill"),
        ("李**", "沉默唤醒", "30天未互动 → 新年关怀", "heart.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(primaryColor)
                Text("客户互动经营 · 今日名单")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))
                Spacer()
                Text("10人")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(primaryColor.opacity(0.10)))
            }
            .padding(16)
            .background(Color.white)

            Divider()

            // Group tags
            HStack(spacing: 8) {
                ForEach(["老客 4", "潜力 3", "生日 2", "唤醒 1"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(primaryColor.opacity(0.08)))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(r: 0.97, g: 0.97, b: 0.98))

            // Client rows
            VStack(spacing: 0) {
                ForEach(clients, id: \.name) { client in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(primaryColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(client.name.prefix(1)))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(primaryColor)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(client.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))
                                Text(client.tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(primaryColor)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Capsule().fill(primaryColor.opacity(0.08)))
                            }
                            Text(client.action)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: client.icon)
                            .font(.system(size: 16))
                            .foregroundColor(primaryColor)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.white)

                    if client.name != clients.last?.name {
                        Divider().padding(.leading, 64)
                    }
                }
            }

            // Send button
            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                    Text("批量发送（10人）")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(primaryColor))
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Meeting Mockup

private struct MeetingMockup: View {
    let text: String
    let title: String
    let primaryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("今日 15:00 · 星巴克福田中心城")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(18)
            .background(
                LinearGradient(colors: [primaryColor, primaryColor.opacity(0.7)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            // Client info card
            VStack(alignment: .leading, spacing: 10) {
                Text("客户速览")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(primaryColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay(Text("王").font(.system(size: 18, weight: .bold)).foregroundColor(primaryColor))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("王姐，36岁 · 互联网运营主管")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))
                        Text("家庭年收入 45-60万 · 1孩（6岁）")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            ForEach(["#健康焦虑", "#怕坑", "#要对比"], id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10))
                                    .foregroundColor(primaryColor)
                            }
                        }
                    }
                }

                Divider()

                // Today's goals
                Text("今日目标")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                VStack(alignment: .leading, spacing: 6) {
                    BriefRow(icon: "target", text: "确定预算 & 保障优先级")
                    BriefRow(icon: "doc.on.doc.fill", text: "3套方案对比 · 现场填数字")
                    BriefRow(icon: "checkmark.shield.fill", text: "解答「体检异常能买吗」顾虑")
                }

                Divider()

                // Materials ready
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                    Text("客户专属资料包已备好（会中视情况展开）")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

private struct BriefRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(r: 0.520, g: 0.200, b: 0.820))
                .frame(width: 16)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
        }
    }
}

// MARK: - Content templates

private func recommendedContent(platform: Platform, persona: AgentPersona) -> String {
    switch (platform, persona.tone) {
    case (.wechatMoments, .professional):
        return "风格：专业顾问\n「早安。好的保障不是「等风险来了才想起」，而是在平静日常里把底盘打稳。愿你今天忙而不乱，稳而有底。」\n+ 一张职场问候帖"
    case (.wechatMoments, .friendly):
        return "风格：生活达人\n「早安呀～今天也是元气满满的一天！记得喝水、好好吃饭，把自己照顾好，才有能量照顾身边的人。」\n+ 一张温馨早安图"
    case (.wechatMoments, .creative):
        return "风格：创意博主\n「用一杯咖啡的时间思考：你有没有一个计划，在五年后还在保护现在的你？」\n+ 一张创意排版问候卡"
    case (.wechatMoments, .concise):
        return "风格：知识领袖\n「早安。复利的本质，不只是财富，也是健康与关系。今天的小积累，都在为未来铺路。」\n+ 一张简约知识卡"

    case (.xiaohongshu, .professional):
        return "风格：专业顾问\n「保险规划的 3 个误区，很多人第一条就踩了｜干货分享」\n正文：误区一：保额越高越好；误区二…\n+ 3 张图文卡片"
    case (.xiaohongshu, .friendly):
        return "风格：生活达人\n「闺蜜问我：买保险真的有用吗？我用亲身经历告诉她…」\n+ 暖色系 Vlog 封面图"
    case (.xiaohongshu, .creative):
        return "风格：创意博主\n「如果人生是一款游戏，你给自己加了什么「护甲」？｜创意测评」\n+ 游戏风格封面设计"
    case (.xiaohongshu, .concise):
        return "风格：知识领袖\n「一张图读懂：重疾险 vs 医疗险，到底差在哪？」\n+ 极简对比信息图"

    case (.wechatOA, .professional):
        return "风格：专业顾问\n标题：《2025 年家庭财务规划白皮书：保障篇》\n导语：在不确定的时代，专业规划是最稳定的护城河…\n+ 深度长图文"
    case (.wechatOA, .friendly):
        return "风格：生活达人\n标题：《那一年，一张保单改变了我们家的走向》\n导语：真实故事，温暖分享。不是在卖保险，是在讲人…\n+ 暖色故事封面"
    case (.wechatOA, .creative):
        return "风格：创意博主\n标题：《如果把保险设计成 RPG 游戏，你的角色卡是什么？》\n导语：用游戏思维理解保障…\n+ 创意互动封面"
    case (.wechatOA, .concise):
        return "风格：知识领袖\n标题：《3 分钟读懂：为什么聪明人都在 30 岁前做规划？》\n导语：数据说话，逻辑先行…\n+ 简洁信息图"

    case (.wechatPrivate, .professional):
        return "风格：专业顾问\n「张总，核保结果出来了：可以正常承保，肝癌项做除外责任。我用大白话解释一下这意味着什么，其余重疾保障不受影响。确认后我发您签约链接，让保障尽快生效。」"
    case (.wechatPrivate, .friendly):
        return "风格：生活达人\n「张总你好～核保结果刚出来，整体没问题，有一个小细节我来帮你解释清楚，您放心！」"
    case (.wechatPrivate, .creative):
        return "风格：创意博主\n「好消息！核保通过了。有一个细节我画了张图帮你秒懂——除外≠不保，其他全覆盖！」"
    case (.wechatPrivate, .concise):
        return "风格：知识领袖\n「核保完成：标准体承保，肝癌除外。其余重疾责任完整。建议尽快签约，保障即刻生效。」"

    case (.clientMgmt, .professional):
        return "风格：专业顾问\n【老客维系】臻享家医体检权益还有3个月到期，已发送预约提醒链接\n【潜力跟进】昨天点赞朋友圈的客户→开门红年金险活动邀约\n【生日触达】今日生日客户→专属问候卡\n【沉默唤醒】30天未互动→新年关怀祝福"
    case (.clientMgmt, .friendly):
        return "风格：生活达人\n给每位客户发一条暖心的个性化消息～\n生日的送祝福、好久不见的问问近况、有新资讯的分享一下，自然不硬推！"
    case (.clientMgmt, .creative):
        return "风格：创意博主\n用有趣的方式触达10位客户：一个测试链接、一条有料的内容、一句让人想回复的问候"
    case (.clientMgmt, .concise):
        return "风格：知识领袖\n10人分4组，精准触达：\n① 权益提醒 × 1  ② 活动邀约 × 3  ③ 生日祝福 × 2  ④ 关怀唤醒 × 4"

    case (.meeting, .professional):
        return "风格：专业顾问\n【会前 brief】王姐，36岁，乳腺囊肿+桥本氏甲状腺炎，关注重疾险\n目标：当场确定保额与预算\n已备：3套方案对比表 + 《重疾险3分钟看懂卡》"
    case (.meeting, .friendly):
        return "风格：生活达人\n见王姐前整理好思路～她最在意的是「别让一场病拖垮家里」，用真实案例说话，不要背条款！"
    case (.meeting, .creative):
        return "风格：创意博主\n会谈 brief：把「买保险」变成「给家庭打底盘」的对话，用可视化工具让她自己算出答案"
    case (.meeting, .concise):
        return "风格：知识领袖\n核心议题：重疾险保额 = 3-5年收入替代 + 房贷缓冲\n3套方案，15分钟讲清，30分钟促成决策"
    }
}

// MARK: - Step row

private struct AutoStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(r: 0.35, g: 0.33, b: 0.45))
        }
    }
}
