import SwiftUI

// MARK: - Models

struct CompanionClient {
    let name: String
    let age: Int
    let occupation: String
    let income: String
    let children: String
    let tags: [String]
    let avatar: String
    let healthNotes: String
    let productFocus: String
    let meetingGoal: String

    static let wangJie = CompanionClient(
        name: "王姐",
        age: 36,
        occupation: "互联网运营主管",
        income: "45–60万/年",
        children: "1孩（6岁）",
        tags: ["#健康焦虑", "#怕被坑", "#爱对比", "#理性决策"],
        avatar: "👩‍💼",
        healthNotes: "乳腺囊肿 · 桥本氏甲状腺炎",
        productFocus: "重疾险为主",
        meetingGoal: "当场确定保额与预算范围"
    )
}

enum Speaker { case agent, client }

struct TranscriptEntry: Identifiable {
    let id = UUID()
    let speaker: Speaker
    let text: String
    let elapsed: Int   // seconds from recording start
}

enum SuggestionPriority { case urgent, medium, info }

struct SuggestionCard: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let content: String
    let priority: SuggestionPriority
    let elapsed: Int   // seconds from recording start

    var priorityColor: Color {
        switch priority {
        case .urgent: return Color(r: 1.0, g: 0.23, b: 0.19)
        case .medium: return Color(r: 1.0, g: 0.58, b: 0.0)
        case .info:   return Color(r: 0.20, g: 0.52, b: 0.98)
        }
    }
    var priorityLabel: String {
        switch priority {
        case .urgent: return "立即关注"
        case .medium: return "建议跟进"
        case .info:   return "参考信息"
        }
    }
}

// MARK: - Event type for unified timeline

private enum TimelineEvent {
    case transcriptLine(Speaker, String)
    case suggestionCard(String, String, String, SuggestionPriority)  // category, icon, content, priority
}

// MARK: - Manager

class CompanionManager: ObservableObject {
    @Published var transcript: [TranscriptEntry] = []
    @Published var suggestions: [SuggestionCard] = []
    @Published var isRecording = false
    @Published var elapsedSeconds = 0

    private var clockTimer: Timer?
    private var workItems: [DispatchWorkItem] = []

    // Unified absolute-time event list.
    // t = seconds from the moment recording starts.
    // Suggestions appear after the transcript line that triggers them.
    private let events: [(Int, TimelineEvent)] = [
        (0,  .transcriptLine(.agent,  "王姐您好！今天主要聊一下家庭健康保障规划，咱们大概40分钟，您看可以吗？")),
        (4,  .suggestionCard("开场话术", "quote.bubble.fill",
                             """
可以说：「王姐，我今天特意帮您准备了3套方案，覆盖经济型到全面型，咱们先看哪套最贴合您家情况——不用急着做决定，看完再说。」

→ 把「卖保险」变成「帮她选」，降低她的防御感。
""", .info)),
        (9,  .transcriptLine(.client, "可以。我主要想了解重疾险，但感觉保险都挺贵的，不知道值不值。")),
        (12, .suggestionCard("价格异议 ⚡", "bolt.fill",
                             """
立即回应：「王姐，您说的「贵」我完全理解。我算给您看——这款50万保额，一年保费大概2000出头，折下来每天不到6块钱，一杯奶茶的价格。但万一真的生病，重疾平均花费40–50万，这6块钱买的是您家不被一场病拖垮的选择权。」

→ 用具体数字锚定，不要只说「值」。
""", .urgent)),
        (17, .transcriptLine(.agent,  "完全理解！今天我带了3套方案，经济型、均衡型、全面型都有，我们先看哪个最适合您家庭情况，再谈值不值。")),
        (25, .transcriptLine(.client, "好。另外我有乳腺囊肿，还有桥本氏甲状腺炎，这样能买保险吗？")),
        (28, .suggestionCard("健康核保 ⚡", "heart.text.square.fill",
                             """
她主动提健康问题，是好信号！可以说：「王姐您问到点上了。乳腺囊肿是良性的，多数公司可以正常承保；最多是乳腺相关病变做「除外处理」——但其他30几种重疾，比如心梗、脑梗、尿毒症，全部正常理赔。桥本氏甲状腺炎同理。除外≠不保，影响的只是那一个部位。我帮您做个预核保，10分钟出结果。」

→ 先打消顾虑，再推进预核保，不要只停在解释。
""", .urgent)),
        (35, .transcriptLine(.agent,  "这个问题问得特别好。乳腺囊肿多数是良性，可以正常承保，乳腺相关做除外处理。除外的意思是——其他重疾全部都保，整体保障不受影响。")),
        (44, .transcriptLine(.client, "哦，那就是说其他病还是保的？那保额大概要多少比较合适？")),
        (47, .suggestionCard("促成话术 ⚡", "checkmark.seal.fill",
                             """
她在问保额 = 进入决策阶段！可以说：「以您年收入45–60万，我建议您重点看B方案：保额80万，相当于保了您约2年的家庭收入。万一出险，房贷、孩子教育、日常开销全都有底。您先看看这张对比表，我就在旁边，有任何问题随时问我。」

→ 把方案放到桌上，让她主动看，不要替她做决定。
""", .urgent)),
        (53, .transcriptLine(.agent,  "通常建议重疾保额 = 3至5年家庭收入替代，加上房贷缓冲。以您的情况，建议50万到100万之间，我给您算一下具体数字。")),
        (60, .transcriptLine(.client, "好，那我先看看方案吧。")),
    ]

    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            startClock()
            scheduleAllEvents()
        } else {
            pauseEverything()
        }
    }

    private func startClock() {
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func scheduleAllEvents() {
        for (absoluteSeconds, event) in events {
            let item = DispatchWorkItem { [weak self] in
                guard let self, self.isRecording else { return }
                switch event {
                case .transcriptLine(let speaker, let text):
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        self.transcript.append(TranscriptEntry(
                            speaker: speaker,
                            text: text,
                            elapsed: absoluteSeconds
                        ))
                    }
                case .suggestionCard(let category, let icon, let content, let priority):
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
                        self.suggestions.append(SuggestionCard(
                            category: category,
                            icon: icon,
                            content: content,
                            priority: priority,
                            elapsed: absoluteSeconds
                        ))
                    }
                }
            }
            workItems.append(item)
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(absoluteSeconds),
                execute: item
            )
        }
    }

    private func pauseEverything() {
        clockTimer?.invalidate()
        clockTimer = nil
        workItems.forEach { $0.cancel() }
        workItems.removeAll()
    }

    var elapsedFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    deinit { clockTimer?.invalidate() }
}

// MARK: - Helpers

private func formatElapsed(_ seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

// MARK: - Main View

struct CompanionChatView: View {
    let client: CompanionClient
    @StateObject private var manager = CompanionManager()
    @Environment(\.dismiss) private var dismiss

    private let accentPurple = Color(r: 0.33, g: 0.18, b: 0.78)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ClientProfileHeader(client: client)

                // Suggestions timeline (main area)
                SuggestionsTimeline(suggestions: manager.suggestions)

                // Compact streaming transcript (bottom strip)
                CompactTranscript(transcript: manager.transcript, client: client)

                // Control bar
                CompanionControlBar(
                    isRecording: manager.isRecording,
                    elapsed: manager.elapsedFormatted,
                    onToggle: { manager.toggleRecording() }
                )
            }
            .background(Color(r: 0.96, g: 0.96, b: 0.97))
            .navigationTitle("智能伴聊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(accentPurple)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Client Profile Header

private struct ClientProfileHeader: View {
    let client: CompanionClient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(client.avatar)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color(r: 0.93, g: 0.91, b: 0.98)))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(client.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(r: 0.10, g: 0.08, b: 0.15))
                        Text("\(client.age)岁")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(client.occupation)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        Label(client.income, systemImage: "banknote")
                        Label(client.children, systemImage: "figure.and.child.holdinghands")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("今日面谈")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(client.productFocus)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(r: 0.33, g: 0.18, b: 0.78))
                }
            }

            HStack(spacing: 6) {
                ForEach(client.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(r: 0.33, g: 0.18, b: 0.78))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(r: 0.33, g: 0.18, b: 0.78).opacity(0.09)))
                }
                Spacer()
            }

            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 1.0, g: 0.23, b: 0.19))
                    Text(client.healthNotes)
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 0.50, g: 0.50, b: 0.52))
                }
                HStack(spacing: 5) {
                    Image(systemName: "target")
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 0.20, g: 0.65, b: 0.32))
                    Text(client.meetingGoal)
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 0.50, g: 0.50, b: 0.52))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Suggestions Timeline (top main area)

private struct SuggestionsTimeline: View {
    let suggestions: [SuggestionCard]

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(r: 1.0, g: 0.75, b: 0.0))
                Text("智能沟通建议")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(r: 0.40, g: 0.38, b: 0.50))
                Spacer()
                if !suggestions.isEmpty {
                    Text("\(suggestions.count) 条")
                        .font(.system(size: 11))
                        .foregroundColor(Color(r: 0.60, g: 0.58, b: 0.70))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(r: 0.97, g: 0.97, b: 0.985))
            .overlay(Divider(), alignment: .bottom)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if suggestions.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(r: 0.82, g: 0.82, b: 0.86))
                                Text("开始录音后\n建议将按时间顺序出现")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(r: 0.70, g: 0.68, b: 0.76))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        }
                        ForEach(suggestions) { card in
                            SuggestionCardRow(card: card)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        // Fixed bottom anchor — always scroll here when new card arrives
                        Color.clear.frame(height: 1).id("suggestions_bottom")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.80), value: suggestions.map(\.id))
                }
                .onChange(of: suggestions.count) { _ in
                    // Small delay lets the new card finish its insertion layout pass
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo("suggestions_bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(r: 0.965, g: 0.963, b: 0.978))
    }
}

private struct SuggestionCardRow: View {
    let card: SuggestionCard

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time badge (left)
            Text(formatElapsed(card.elapsed))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(r: 0.60, g: 0.58, b: 0.70))
                .padding(.top, 12)
                .frame(width: 38)

            // Card body
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Image(systemName: card.icon)
                        .font(.system(size: 11))
                        .foregroundColor(card.priorityColor)
                    Text(card.category)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(card.priorityColor)
                    Spacer()
                    Text(card.priorityLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(card.priorityColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(card.priorityColor.opacity(0.10)))
                }
                Text(card.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color(r: 0.18, g: 0.16, b: 0.24))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(card.priorityColor.opacity(0.20), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        }
    }
}

// MARK: - Compact Streaming Transcript (bottom strip)

private struct CompactTranscript: View {
    let transcript: [TranscriptEntry]
    let client: CompanionClient

    var body: some View {
        VStack(spacing: 0) {
            // Strip header
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                Text("实时对话记录")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(r: 0.55, g: 0.53, b: 0.62))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(r: 0.93, g: 0.93, b: 0.95))
            .overlay(Divider(), alignment: .top)
            .overlay(Divider(), alignment: .bottom)

            // Log scroll
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if transcript.isEmpty {
                            Text("录音开始后，对话内容将在此流式显示...")
                                .font(.system(size: 11))
                                .foregroundColor(Color(r: 0.72, g: 0.70, b: 0.78))
                                .padding(.horizontal, 14)
                                .padding(.top, 8)
                        }
                        ForEach(transcript) { entry in
                            TranscriptLogLine(entry: entry, clientName: client.name)
                                .id(entry.id)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(height: 120)
                .background(Color(r: 0.97, g: 0.97, b: 0.985))
                .onChange(of: transcript.count) { _ in
                    if let last = transcript.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

private struct TranscriptLogLine: View {
    let entry: TranscriptEntry
    let clientName: String

    private var speakerLabel: String {
        entry.speaker == .agent ? "我" : clientName
    }
    private var speakerColor: Color {
        entry.speaker == .agent
            ? Color(r: 0.33, g: 0.18, b: 0.78)
            : Color(r: 0.20, g: 0.55, b: 0.30)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Text(formatElapsed(entry.elapsed))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Color(r: 0.68, g: 0.66, b: 0.74))
                .frame(width: 38, alignment: .leading)
                .padding(.leading, 14)

            Text(speakerLabel + "：")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(speakerColor)

            Text(entry.text)
                .font(.system(size: 11))
                .foregroundColor(Color(r: 0.22, g: 0.20, b: 0.30))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 14)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Control Bar

private struct CompanionControlBar: View {
    let isRecording: Bool
    let elapsed: String
    let onToggle: () -> Void

    private let accent = Color(r: 0.33, g: 0.18, b: 0.78)

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isRecording ? Color(r: 1.0, g: 0.23, b: 0.19) : Color(r: 0.80, g: 0.80, b: 0.82))
                    .frame(width: 7, height: 7)
                    .opacity(isRecording ? 1 : 0.5)
                Text(elapsed)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isRecording ? Color(r: 1.0, g: 0.23, b: 0.19) : .secondary)
            }

            Spacer()

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color(r: 1.0, g: 0.23, b: 0.19) : accent)
                        .frame(width: 56, height: 56)
                        .shadow(color: (isRecording ? Color.red : accent).opacity(0.35),
                                radius: isRecording ? 12 : 6, y: 3)
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isRecording ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)

            Spacer()

            Text(isRecording ? "录音中" : "点击开始")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .top)
    }
}
