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
                               content: recommendedContent(platform: card.platform, persona: persona),
                               mediaFiles: card.mediaFiles)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Content Preview Sheet

struct ContentPreviewView: View {
    let card: ScheduleCard
    let persona: AgentPersona
    let content: String
    var mediaFiles: [String] = []

    // Always fetch fresh from backend when preview opens so we get the latest uploaded images
    @State private var liveMediaFiles: [String] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                platformMockup
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
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
        .onAppear { fetchLatestMediaFiles() }
    }

    // Pull the freshest media_files for this card from the backend each time the preview opens.
    private func fetchLatestMediaFiles() {
        // Start with whatever we already have
        liveMediaFiles = mediaFiles
        guard let url = URL(string: "http://localhost:8765/api/config") else { return }
        var req = URLRequest(url: url, timeoutInterval: 3)
        req.httpMethod = "GET"
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let schedule = json["schedule"] as? [[String: Any]] else { return }
            let match = schedule.first {
                ($0["platform"] as? String) == card.platform.rawValue &&
                ($0["title"]    as? String) == card.title
            }
            let files: [String]
            if let arr = match?["media_files"] as? [String] {
                files = arr.filter { !$0.isEmpty }
            } else if let single = match?["media_file"] as? String, !single.isEmpty {
                files = [single]
            } else {
                files = []
            }
            DispatchQueue.main.async { liveMediaFiles = files }
        }.resume()
    }

    @ViewBuilder
    private var platformMockup: some View {
        let parsed = parseContent(content)
        switch card.platform {
        case .wechatMoments:
            MomentsMockup(persona: persona, content: parsed, accentColor: card.platform.primaryColor, mediaFile: liveMediaFiles.first ?? "")
        case .xiaohongshu:
            XhsMockup(persona: persona, content: parsed, title: card.title, primaryColor: card.platform.primaryColor, mediaFiles: liveMediaFiles)
        case .wechatOA:
            OAMockup(persona: persona, content: parsed, title: card.title, mediaFile: liveMediaFiles.first ?? "")
        case .wechatPrivate:
            PrivateMsgMockup(persona: persona, content: parsed)
        case .clientMgmt:
            ClientMgmtMockup(text: content, primaryColor: card.platform.primaryColor)
        case .meeting:
            MeetingMockup(text: content, title: card.title, primaryColor: card.platform.primaryColor)
        }
    }
}

// MARK: - Parsed Content

private struct PostContent {
    let body: String
    let attachment: String
}

private func parseContent(_ raw: String) -> PostContent {
    let lines = raw.components(separatedBy: "\n")

    // Extract attachment from line starting with "+ "
    var attachment = ""
    for line in lines {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("+ ") {
            attachment = String(t.dropFirst(2))
            break
        }
    }

    // Build body: text inside 「」 + any extra lines between 」 and the "+ " attachment
    var bodyParts: [String] = []
    if let open = raw.range(of: "「"),
       let close = raw.range(of: "」", options: .backwards) {
        // Text inside the outermost brackets
        bodyParts.append(String(raw[open.upperBound..<close.lowerBound]))
        // Any lines after 」 that aren't the attachment or style tag
        let after = String(raw[close.upperBound...])
        for line in after.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("+ ") || t.hasPrefix("风格：") { continue }
            bodyParts.append(t)
        }
    } else {
        // Fallback: drop 风格 and attachment lines
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("风格：") || t.hasPrefix("+ ") { continue }
            bodyParts.append(t)
        }
    }

    let body = bodyParts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    return PostContent(body: body, attachment: attachment)
}

// MARK: - Attachment Card

private struct AttachmentCardView: View {
    let description: String
    let accentColor: Color
    var mediaFile: String = ""

    private var backendImageURL: URL? {
        guard !mediaFile.isEmpty else { return nil }
        return URL(string: "http://localhost:8765/media/\(mediaFile)")
    }

    var body: some View {
        Group {
            if let url = backendImageURL {
                // Real uploaded image from backend
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderCard
                    case .empty:
                        ZStack {
                            Color(r: 0.92, g: 0.92, b: 0.94)
                            ProgressView()
                        }
                    @unknown default:
                        placeholderCard
                    }
                }
            } else {
                placeholderCard
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var placeholderCard: some View {
        if description.contains("职场问候") {
            ProfessionalGreetingCard()
        } else if description.contains("温馨") {
            WarmMorningCard()
        } else if description.contains("创意") {
            CreativeCard(accentColor: accentColor)
        } else if description.contains("简约") || description.contains("知识卡") {
            MinimalKnowledgeCard(accentColor: accentColor)
        } else if description.contains("Vlog") {
            VlogCoverCard(accentColor: accentColor)
        } else if description.contains("对比信息图") {
            ComparisonInfoCard(accentColor: accentColor)
        } else if description.contains("信息图") {
            SimpleInfoCard(accentColor: accentColor)
        } else if description.contains("图文卡片") {
            CardGridView(accentColor: accentColor)
        } else if description.contains("封面") {
            CoverCard(accentColor: accentColor, label: description)
        } else if description.contains("故事封面") || description.contains("故事") {
            StoryCoverCard()
        } else {
            GenericImageCard(accentColor: accentColor, label: description)
        }
    }
}

// 职场问候帖 — dark navy professional greeting
private struct ProfessionalGreetingCard: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(r: 0.10, g: 0.13, b: 0.22), Color(r: 0.18, g: 0.22, b: 0.36)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 10) {
                Text("早安")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 48, height: 1.5)
                Text("Good Morning")
                    .font(.system(size: 13, weight: .light))
                    .tracking(3)
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .frame(height: 180)
    }
}

// 温馨早安图 — warm peach gradient
private struct WarmMorningCard: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(r: 1.0, g: 0.82, b: 0.64), Color(r: 0.99, g: 0.65, b: 0.45)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "sun.and.horizon.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.white.opacity(0.85))
                Text("早安，新的一天")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.9))
            }
        }
        .frame(height: 180)
    }
}

// 创意排版问候卡 — colorful bold
private struct CreativeCard: View {
    let accentColor: Color
    var body: some View {
        ZStack {
            Color(r: 0.97, g: 0.97, b: 0.99)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    accentColor.opacity(0.7).frame(height: 80)
                    Color(r: 0.98, g: 0.55, b: 0.22).opacity(0.7).frame(height: 80)
                }
                HStack(spacing: 0) {
                    Color(r: 0.25, g: 0.72, b: 0.58).opacity(0.7).frame(height: 80)
                    Color(r: 0.97, g: 0.85, b: 0.24).opacity(0.7).frame(height: 80)
                }
            }
            Text("创意问候")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .frame(height: 160)
    }
}

// 简约知识卡 — minimal white card
private struct MinimalKnowledgeCard: View {
    let accentColor: Color
    var body: some View {
        ZStack {
            Color.white
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 32, height: 3)
                Text("今日洞察")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
                    .tracking(2)
                Text("复利的本质\n不只是财富")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.12))
                    .lineSpacing(4)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(["#规划", "#保障", "#财富"], id: \.self) { t in
                        Text(t).font(.system(size: 10)).foregroundColor(accentColor.opacity(0.8))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 160)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(r: 0.90, g: 0.90, b: 0.93), lineWidth: 1))
    }
}

// Vlog封面图 — video-style cover
private struct VlogCoverCard: View {
    let accentColor: Color
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(r: 1.0, g: 0.55, b: 0.55), accentColor.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 56, height: 56)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
                Text("真实故事")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Vlog")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
            }
        }
        .frame(height: 180)
    }
}

// 对比信息图 — two-column comparison
private struct ComparisonInfoCard: View {
    let accentColor: Color
    private let rows = [("保障范围", "100种重疾", "住院费用"), ("保额", "50万", "按实报销"), ("缴费", "20年", "年缴")]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("重疾险")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(accentColor)
                Text("医疗险")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(accentColor.opacity(0.65))
            }
            ForEach(rows, id: \.0) { row in
                HStack(spacing: 0) {
                    Text(row.1)
                        .font(.system(size: 12)).foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(accentColor.opacity(0.05))
                    Divider()
                    Text(row.2)
                        .font(.system(size: 12)).foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                    Divider()
                }
            }
            HStack {
                Text("一图读懂：重疾险 vs 医疗险")
                    .font(.system(size: 10)).foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color(r: 0.96, g: 0.96, b: 0.98))
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(r: 0.90, g: 0.90, b: 0.93), lineWidth: 1))
    }
}

// 信息图 — simple bar chart
private struct SimpleInfoCard: View {
    let accentColor: Color
    private let bars: [(String, CGFloat)] = [("保障", 0.9), ("收益", 0.6), ("流动", 0.4), ("省税", 0.7)]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("规划维度评分")
                .font(.system(size: 12, weight: .bold)).foregroundColor(Color(r: 0.10, g: 0.10, b: 0.12))
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(bars, id: \.0) { item in
                    VStack(spacing: 4) {
                        Text(Int(item.1 * 100).description)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(accentColor)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor.opacity(0.15 + item.1 * 0.55))
                            .frame(width: 32, height: item.1 * 80)
                        Text(item.0)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(r: 0.90, g: 0.90, b: 0.93), lineWidth: 1))
    }
}

// 图文卡片 — 2x2 grid
private struct CardGridView: View {
    let accentColor: Color
    private let items = ["误区一", "误区二", "误区三", "总结"]
    private let subtitles = ["保额越高越好", "买医保够了", "年纪大再买", "综合规划更稳"]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 4) {
                    Text(items[i])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitles[i])
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 8).fill(accentColor.opacity(0.6 + Double(i) * 0.1)))
            }
        }
        .padding(8)
        .background(Color(r: 0.97, g: 0.97, b: 0.99))
    }
}

// 封面 — large gradient cover
private struct CoverCard: View {
    let accentColor: Color
    let label: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [accentColor, accentColor.opacity(0.5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.7))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: 180)
    }
}

// 故事封面
private struct StoryCoverCard: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(r: 1.0, g: 0.78, b: 0.55), Color(r: 0.95, g: 0.55, b: 0.40)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.8))
                Text("真实故事")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(height: 180)
    }
}

// Generic fallback card
private struct GenericImageCard: View {
    let accentColor: Color
    let label: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [accentColor.opacity(0.6), accentColor.opacity(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.75))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: 160)
    }
}

// MARK: - Moments Mockup

private struct MomentsMockup: View {
    let persona: AgentPersona
    let content: PostContent
    let accentColor: Color
    var mediaFile: String = ""

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

                    Text(content.body)
                        .font(.system(size: 14))
                        .foregroundColor(Color(r: 0.12, g: 0.12, b: 0.12))
                        .lineSpacing(3)

                    if !content.attachment.isEmpty || !mediaFile.isEmpty {
                        AttachmentCardView(description: content.attachment, accentColor: accentColor, mediaFile: mediaFile)
                            .frame(width: 180)
                    }

                    // Time
                    HStack {
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
    let content: PostContent
    let title: String
    let primaryColor: Color
    var mediaFiles: [String] = []

    private let xhsRed  = Color(r: 1.0,  g: 0.141, b: 0.259)
    private let tagBlue = Color(r: 0.18,  g: 0.50,  b: 0.96)
    private let metaGray = Color(r: 0.56, g: 0.56,  b: 0.58)

    var body: some View {
        VStack(spacing: 0) {

            // ── 顶部导航（白底，独立于图片）──
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))

                Circle()
                    .fill(LinearGradient(colors: persona.tone.gradientColors,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay(Text(persona.emoji).font(.system(size: 17)))

                Text(persona.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))

                Spacer()

                Text("关注")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(xhsRed)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .overlay(Capsule().stroke(xhsRed, lineWidth: 1.5))

                Image(systemName: "arrowshape.turn.up.right")
                    .font(.system(size: 16))
                    .foregroundColor(Color(r: 0.35, g: 0.35, b: 0.35))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white)

            // ── 封面图区域 ──
            xhsImageArea
                .clipped()

            // ── 正文内容区 ──
            VStack(alignment: .leading, spacing: 10) {
                // 大标题
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(r: 0.08, g: 0.08, b: 0.08))
                    .lineSpacing(3)

                // 正文
                Text(content.body)
                    .font(.system(size: 15))
                    .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                    .lineSpacing(5)

                // Hashtags（蓝色行内文字，和真实 XHS 一致）
                Text("#黄金投资 #保险避险 #资产配置 #理财干货 #家庭理财 #稳稳的安全感")
                    .font(.system(size: 14))
                    .foregroundColor(tagBlue)

                // 时间 + 地点 + 不喜欢
                HStack {
                    Text("刚刚 · 广东")
                        .font(.system(size: 12))
                        .foregroundColor(metaGray)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsdown")
                            .font(.system(size: 12))
                        Text("不喜欢")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(metaGray)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.white)

            // ── 评论区（新帖，暂无评论）──
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("共 0 条评论")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(r: 0.10, g: 0.10, b: 0.10))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

                // 评论输入框
                HStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: persona.tone.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay(Text(persona.emoji).font(.system(size: 15)))
                    HStack {
                        Text("说点什么…")
                            .font(.system(size: 13))
                            .foregroundColor(Color(r: 0.68, g: 0.68, b: 0.70))
                        Spacer()
                        Image(systemName: "mic").font(.system(size: 14)).foregroundColor(metaGray)
                        Image(systemName: "photo").font(.system(size: 14)).foregroundColor(metaGray)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(r: 0.93, g: 0.93, b: 0.94)))
                }
                .padding(.horizontal, 16).padding(.bottom, 16)

                // 空评论占位
                VStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 28))
                        .foregroundColor(Color(r: 0.82, g: 0.82, b: 0.84))
                    Text("还没有评论，快来抢沙发")
                        .font(.system(size: 13))
                        .foregroundColor(metaGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .background(Color.white)

            // ── 底部固定栏 ──
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil").font(.system(size: 13))
                    Text("发评论").font(.system(size: 13))
                }
                .foregroundColor(Color(r: 0.50, g: 0.50, b: 0.52))
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(r: 0.93, g: 0.93, b: 0.94)))

                Spacer()

                HStack(spacing: 18) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart").font(.system(size: 18))
                        Text("0").font(.system(size: 13))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "star").font(.system(size: 18))
                        Text("0").font(.system(size: 13))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right").font(.system(size: 18))
                        Text("0").font(.system(size: 13))
                    }
                }
                .foregroundColor(Color(r: 0.22, g: 0.22, b: 0.24))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }

    // ── Image area: single full-width OR multi-image grid ──
    @ViewBuilder
    private var xhsImageArea: some View {
        let hasMedia = !mediaFiles.isEmpty
        let hasAttachment = !content.attachment.isEmpty

        if mediaFiles.count == 1 {
            // Single image — full width tall banner
            AttachmentCardView(description: content.attachment, accentColor: primaryColor, mediaFile: mediaFiles[0])
                .frame(height: 260)
        } else if mediaFiles.count >= 2 {
            // Multi-image grid (3-column, square cells)
            let cols = min(mediaFiles.count, 3)
            let gap: CGFloat = 3
            GeometryReader { geo in
                let cellSize = (geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols)
                let rows = Int(ceil(Double(mediaFiles.count) / Double(cols)))
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<cols, id: \.self) { col in
                                let idx = row * cols + col
                                if idx < mediaFiles.count {
                                    AsyncImage(url: URL(string: "http://localhost:8765/media/\(mediaFiles[idx])")) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                        default:
                                            Color(r: 0.90, g: 0.90, b: 0.92)
                                        }
                                    }
                                    .frame(width: cellSize, height: cellSize)
                                    .clipped()
                                } else {
                                    Color.clear.frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: {
                let gap: CGFloat = 3
                let cols = CGFloat(min(mediaFiles.count, 3))
                // Approximate cell size based on 390pt wide device
                let approxCell = (390 - gap * (cols - 1)) / cols
                let rows = CGFloat(Int(ceil(Double(mediaFiles.count) / Double(cols))))
                return approxCell * rows + gap * (rows - 1)
            }())
        } else if hasAttachment {
            // No real images but has attachment description — show placeholder
            AttachmentCardView(description: content.attachment, accentColor: primaryColor, mediaFile: "")
                .frame(height: 260)
        } else {
            // No images at all — gradient banner
            LinearGradient(colors: [primaryColor, primaryColor.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 260)
        }
    }
}

// MARK: - WeChat OA Mockup

private struct OAMockup: View {
    let persona: AgentPersona
    let content: PostContent
    let title: String
    var mediaFile: String = ""

    private let oaColor = Color(r: 0.471, g: 0.549, b: 0.714)

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
                    if !content.attachment.isEmpty || !mediaFile.isEmpty {
                        AttachmentCardView(description: content.attachment, accentColor: oaColor, mediaFile: mediaFile)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(Rectangle())
                    } else {
                        LinearGradient(colors: [oaColor, Color(r: 0.263, g: 0.337, b: 0.502)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 180)
                    }

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

                        Text(content.body)
                            .font(.system(size: 15))
                            .foregroundColor(Color(r: 0.15, g: 0.15, b: 0.15))
                            .lineSpacing(6)
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
    let content: PostContent

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
                        Text(content.body)
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
        return "「别再把黄金当成\"稳稳的幸福\"了⚠️\n我真的花了3天把近40年数据翻了个底朝天📚\n结论：黄金的\"腰斩名场面\"比电视剧还抓马……💥\n看完这篇，你会比90%的炒金人更清醒🧠✨\n\n🪙黄金=乱世护身符，但不是\"稳赚神器\"\n黄金更像是极端情况下的保值工具：\n✅ 对抗货币贬值\n✅ 风险事件爆发时有机会顶一顶\n但它也有很现实的一面👇\n\n😵黄金风险暴露：跌起来真的不讲武德\n📉 历史上出现过单日跌超12%的情况\n⚡ 波动强到很多人根本扛不住\n🧨 而且政策/利率/预期一变，行情可能说崩就崩\n\n🛡️我更想要的是\"能睡得着\"的确定性\n这也是为什么很多家庭会用储蓄险做底仓：\n✅ 确定性收益（按合同走）\n✅ 时间规划（孩子教育/养老/家庭备用金）\n✅ \"隔离人性弱点\"（不追涨杀跌、不被情绪带着跑）\n\n📌避险逻辑：保险更像\"家庭理财的稳定基石\"\n📜 《保险法》框架下，合同权益更刚性\n🧱 还能做到一定程度的资产隔离（更适合做家庭底盘）\n（当然：具体以产品条款与个人情况为准～）\n\n🔁复利感受一下（仅供参考）\n假设：年缴10万×10年\n到第20年现金价值大概能到 151万+📈\n重点不是\"赚多快\"，而是确定增长 + 可规划🗓️\n\n🧩配置思路：别押单一资产，稳才是王道\n我更认可这种\"分层配置\"👇\n🛡️ 60%：保险打底（家庭底盘/确定性）\n🌿 30%：稳健资产（固收/高等级债/等）\n🚀 10%：进取资产（股票/权益/高波动）\n这样不管行情怎么折腾，都不至于慌到手抖😮‍💨\n\n💬你们觉得：\n保险算不算靠谱的避险工具？\n你会把\"家庭底仓\"放在哪里？评论区聊聊👇✨」"
    case (.xiaohongshu, .friendly):
        return "风格：生活达人\n「闺蜜问我：买保险真的有用吗？我用亲身经历告诉她」\n两年前，我妈查出乳腺结节，当时全家人都慌了。还好她五年前买了重疾险，整个治疗过程没让家里背债。那一刻我才真正理解：保险不是为了坏事发生，是让坏事发生时你还有选择权。\n#真实故事 #重疾险 #家庭保障\n+ 暖色系 Vlog 封面图"
    case (.xiaohongshu, .creative):
        return "风格：创意博主\n「如果人生是一款游戏，你给自己加了什么「护甲」？｜创意测评」\n我给自己配了一套：医疗险（基础防御）+ 重疾险（大招抵挡）+ 年金险（续航能量条）。你的角色卡是什么配置？评论区说说看！\n#保险测评 #人生RPG #家庭保障\n+ 游戏风格封面设计"
    case (.xiaohongshu, .concise):
        return "风格：知识领袖\n「一张图读懂：重疾险 vs 医疗险，到底差在哪？」\n重疾险：确诊即赔，钱归你支配，补偿收入损失；医疗险：实报实销，只报医疗费用。两者解决不同问题，缺一不可。\n#重疾险科普 #医疗险 #保险知识\n+ 极简对比信息图"

    case (.wechatOA, .professional):
        return "风格：专业顾问\n标题：《2025 年家庭财务规划白皮书：保障篇》\n在不确定的时代，专业规划是最稳定的护城河。今天我们从三个维度拆解家庭保障逻辑：第一，保额如何与家庭负债精准匹配；第二，重疾险与医疗险如何搭配才不浪费；第三，不同收入段的保障优先级排序。点击阅读全文，带走一份可执行的家庭保障清单。\n+ 深度长图文"
    case (.wechatOA, .friendly):
        return "风格：生活达人\n标题：《那一年，一张保单改变了我们家的走向》\n这不是一篇卖保险的文章。这是一个真实的故事：一个普通家庭，因为一场大病，两条截然不同的走向。有保单的那条路，孩子的学费、老人的赡养、房贷的月供，都还在正常运转。没有的那条，不敢细说。守护，是最朴素的爱。\n+ 暖色故事封面"
    case (.wechatOA, .creative):
        return "风格：创意博主\n标题：《如果把保险设计成 RPG 游戏，你的角色卡是什么？》\n想象一下：医疗险是「护甲」，减伤但不免疫；重疾险是「复活石」，关键时刻让你不出局；年金险是「永动能量条」，退休后持续续航。你现在的角色，装备齐了吗？点进来测一测你的保障缺口。\n+ 创意互动封面"
    case (.wechatOA, .concise):
        return "风格：知识领袖\n标题：《3 分钟读懂：为什么聪明人都在 30 岁前做规划？》\n数据说话：30岁投保 vs 40岁投保，同等保额保费相差约40%；30岁前健康核保通过率超过95%，40岁后含除外条款的概率超过60%；重疾险最佳购买窗口：25–35岁。时间是保费最好的杠杆，早一天就省一分钱。\n+ 简洁信息图"

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
