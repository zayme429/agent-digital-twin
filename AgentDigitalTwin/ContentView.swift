import SwiftUI

// MARK: - Light theme palette
private enum T {
    static let bg       = Color(r: 0.960, g: 0.958, b: 0.972)
    static let card     = Color.white
    static let agentBub = Color(r: 0.925, g: 0.922, b: 0.938)
    static let accent   = Color(r: 0.330, g: 0.180, b: 0.780)
    static let border   = Color(r: 0.882, g: 0.878, b: 0.900)
    static let divider  = Color(r: 0.900, g: 0.896, b: 0.912)
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var personaManager:  PersonaManager

    @State private var showDrawer   = false
    @State private var inputText    = ""
    @State private var isThinking   = false
    @State private var isRecording  = false
    @State private var confirmCard: ScheduleCard?
    @State private var progressCard: ScheduleCard?
    @State private var showProgress = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                Divider().background(T.divider)
                chatScrollView
                if isRecording { recordingBar }
                Divider().background(T.divider)
                chatInputBar
            }

            // Left drawer
            if showDrawer {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) { showDrawer = false }
                    }
                    .zIndex(20)
                SideDrawerView(isPresented: $showDrawer)
                    .environmentObject(personaManager)
                    .environmentObject(scheduleManager)
                    .transition(.move(edge: .leading))
                    .zIndex(21)
            }

            // Confirm sheet
            if let card = confirmCard {
                ConfirmExecuteSheet(
                    card: card,
                    persona: personaManager.selectedPersona,
                    onConfirm: {
                        progressCard = card
                        confirmCard  = nil
                        withAnimation(.easeInOut(duration: 0.28)) { showProgress = true }
                    },
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.22)) { confirmCard = nil }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            // Progress overlay
            if showProgress, let card = progressCard {
                TaskProgressOverlay(
                    card: card,
                    isPresented: $showProgress,
                    onComplete: { scheduleManager.execute(card) }
                )
                .transition(.opacity)
                .zIndex(11)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showProgress)
        .animation(.easeOut(duration: 0.25), value: showDrawer)
        .onTapGesture { inputFocused = false }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 10) {
            // Gear / settings button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showDrawer.toggle()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(showDrawer ? T.accent : Color(r: 0.52, g: 0.50, b: 0.58))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(showDrawer ? T.accent.opacity(0.10) : T.agentBub))
            }
            .padding(.leading, 14)

            // Agent avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [T.accent, Color(r: 0.18, g: 0.35, b: 0.85)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                Text(personaManager.selectedPersona.emoji)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(personaManager.selectedPersona.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text(sessionDateString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            let done  = scheduleManager.completedCards.count
            let total = scheduleManager.cards.count
            Text("\(done)/\(total) 完成")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(T.accent)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(T.accent.opacity(0.10)))
                .padding(.trailing, 16)
        }
        .frame(height: 54)
        .background(T.card)
    }

    private var sessionDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    // MARK: - Chat scroll

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(scheduleManager.timeline) { item in
                        TimelineItemView(item: item) { card in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                confirmCard = card
                            }
                        }
                    }
                    if isThinking { ThinkingBubble() }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }
            .onChange(of: scheduleManager.timeline.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isThinking) { _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }

    // MARK: - Recording bar

    private var recordingBar: some View {
        HStack(spacing: 10) {
            RecordingPulse()
            Text("正在录音…  松开发送，向左滑动取消")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Button("取消") {
                withAnimation { isRecording = false }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(T.accent)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(T.accent.opacity(0.06))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Input bar

    private var chatInputBar: some View {
        HStack(spacing: 8) {
            // Voice button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isRecording {
                        isRecording = false
                        sendVoiceMessage()
                    } else {
                        inputFocused = false
                        isRecording = true
                    }
                }
            } label: {
                Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isRecording ? .red : T.accent)
            }

            if !isRecording {
                TextField("发送指令给代理人…", text: $inputText)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(T.bg)
                            .overlay(RoundedRectangle(cornerRadius: 22)
                                .stroke(T.border, lineWidth: 1))
                    )
                    .focused($inputFocused)
                    .onSubmit { sendMessage() }

                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(inputText.isEmpty || isThinking
                            ? T.border : T.accent)
                }
                .disabled(inputText.isEmpty || isThinking)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(T.card)
    }

    // MARK: - Send

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        inputText = ""; inputFocused = false
        scheduleManager.appendUser(trimmed)
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.9...1.5)) {
            isThinking = false
            let resp = agentResponse(for: trimmed)
            scheduleManager.appendAgent(resp.text)
            if let platform = resp.platform { scheduleManager.queueManual(platform: platform) }
        }
    }

    private func sendVoiceMessage() {
        scheduleManager.appendUser("🎤 语音指令")
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isThinking = false
            scheduleManager.appendAgent("收到语音指令 🎤\n已解析完成，如需发布内容请告诉我平台名称（如：发朋友圈）。")
        }
    }

    // MARK: - Agent response logic

    private struct AgentResp { let text: String; var platform: Platform? = nil }

    private func agentResponse(for input: String) -> AgentResp {
        let s       = input.lowercased()
        let persona = personaManager.selectedPersona
        let done    = scheduleManager.completedCards.count
        let total   = scheduleManager.cards.count

        if s.contains("今天") || s.contains("计划") || s.contains("行程") || s.contains("什么") {
            let lines = scheduleManager.cards.prefix(5).enumerated().map { i, c -> String in
                "\(i+1). [\(c.platform.rawValue)] \(c.title) \(c.isPosted ? "✅" : "⏳")"
            }
            return AgentResp(text: "📋 今日发布计划（\(total) 条）：\n\n"
                + lines.joined(separator: "\n")
                + "\n\n已完成 \(done)/\(total)，人设：\(persona.emoji) \(persona.name)")
        }
        if s.contains("朋友圈") {
            return AgentResp(text: "✅ 朋友圈任务已加入待执行队列，请在下方卡片确认执行。", platform: .wechatMoments)
        }
        if s.contains("小红书") || s.contains("红书") {
            return AgentResp(text: "✅ 小红书推送任务已加入待执行队列，请在下方卡片确认执行。", platform: .xiaohongshu)
        }
        if s.contains("公众号") || s.contains("推文") {
            return AgentResp(text: "✅ 公众号推文任务已加入待执行队列，请在下方卡片确认执行。", platform: .wechatOA)
        }
        if s.contains("互动") || s.contains("私聊") || s.contains("卡片") {
            return AgentResp(text: "✅ 微信互动卡片任务已加入待执行队列，请在下方卡片确认执行。", platform: .wechatPrivate)
        }
        if s.contains("报告") || s.contains("总结") {
            let manual = scheduleManager.cards.filter { $0.isManualTrigger }.count
            return AgentResp(text: "📊 今日运营报告\n─────\n计划：\(total) · 完成：\(done) · 手动：\(manual)\n人设：\(persona.emoji) \(persona.name) · \(persona.tone.rawValue)\n─────\n系统正常 ✅")
        }
        if s.contains("人设") || s.contains("切换") {
            return AgentResp(text: "当前人设：\(persona.emoji) \(persona.name)\n\(persona.tone.rawValue) · \(persona.description)\n\n切换请点击左上角齿轮菜单。")
        }
        return AgentResp(text: ["指令已接收 ✅  正在以「\(persona.name)」人设处理。",
                                "明白！将按 \(persona.tone.rawValue) 风格执行。如需发布，告诉我平台名称即可。",
                                "好的，处理中 ⚡  如需发布内容，告诉我平台名称即可。"].randomElement()!)
    }
}

// MARK: - Timeline item dispatcher

struct TimelineItemView: View {
    let item:         TimelineItem
    let onTapPending: (ScheduleCard) -> Void
    var body: some View { itemContent }

    @ViewBuilder
    private var itemContent: some View {
        switch item {
        case .agentText(_, let text, let time):
            AgentBubble(text: text, time: time)
        case .userText(_, let text, let time):
            UserBubble(text: text, time: time)
        case .overviewCard(_, let time):
            OverviewCardBubble(time: time)
        case .pendingAction(_, let card):
            PendingCardBubble(card: card, onTap: { onTapPending(card) })
        case .completedAction(_, let card):
            CompletedCardBubble(card: card)
        }
    }
}

// MARK: - Agent text bubble

struct AgentBubble: View {
    let text: String
    let time: Date

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(T.agentBub)
                    )
                    .frame(maxWidth: 280, alignment: .leading)
                Text(shortTime(time))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - User text bubble

struct UserBubble: View {
    let text: String
    let time: Date

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(
                                colors: [T.accent, Color(r: 0.18, g: 0.35, b: 0.85)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .frame(maxWidth: 260, alignment: .trailing)
                Text(shortTime(time))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
        }
    }
}

// MARK: - Typing indicator

struct ThinkingBubble: View {
    @State private var phase = 0
    private let ticker = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            agentAvatar
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(phase == i ? 0.8 : 0.3))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.25 : 0.85)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16).fill(T.agentBub))
            Spacer()
        }
        .onReceive(ticker) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - Recording pulse animation

private struct RecordingPulse: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle().fill(Color.red.opacity(0.20)).frame(width: 20, height: 20)
                .scaleEffect(pulsing ? 1.6 : 1.0).opacity(pulsing ? 0 : 0.8)
            Circle().fill(Color.red).frame(width: 10, height: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Overview card bubble (vertical layout)

struct OverviewCardBubble: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    let time: Date

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar

            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(T.accent)
                    Text("今日总览 · \(dateString)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    let done = scheduleManager.completedCards.count
                    let total = scheduleManager.cards.count
                    Text("\(done)/\(total)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(T.accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(T.accent.opacity(0.10)))
                }
                .padding(.bottom, 10)

                Divider().background(T.divider)

                // Vertical list of schedule items
                ForEach(scheduleManager.timelineCards) { card in
                    OverviewItemRow(card: card)
                    if card.id != scheduleManager.timelineCards.last?.id {
                        Divider().background(T.divider).padding(.leading, 38)
                    }
                }

                // Timestamp
                Text(shortTime(time))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(T.card)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
            )
            .frame(maxWidth: 320)

            Spacer(minLength: 0)
        }
    }
}

private struct OverviewItemRow: View {
    let card: ScheduleCard

    private var timeStr: String {
        let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Status circle
            ZStack {
                Circle()
                    .fill(card.isPosted
                        ? Color(r: 0.027, g: 0.757, b: 0.376).opacity(0.12)
                        : T.agentBub)
                    .frame(width: 28, height: 28)
                if card.isPosted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                } else {
                    Image(systemName: card.platform.icon)
                        .font(.system(size: 11))
                        .foregroundColor(card.platform.primaryColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(timeStr)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(card.platform.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(card.platform.primaryColor)
                    if card.isPosted {
                        Text("已发布")
                            .font(.system(size: 10))
                            .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                    }
                }
                Text(card.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(card.content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Pending action card bubble

struct PendingCardBubble: View {
    let card:  ScheduleCard
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar

            VStack(alignment: .leading, spacing: 4) {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 10) {
                        // Platform row
                        HStack(spacing: 6) {
                            Image(systemName: card.platform.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(card.platform.primaryColor)
                            Text(card.platform.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(card.platform.primaryColor)

                            if card.isManualTrigger {
                                Text("手动")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(T.accent)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(T.accent.opacity(0.10)))
                            }

                            Spacer()

                            Text(shortTime(card.scheduledTime))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Text(card.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(card.content)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        // Execute button
                        HStack {
                            Spacer()
                            Label("点击确认执行", systemImage: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(card.platform.primaryColor)
                                )
                        }
                    }
                    .padding(13)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(T.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(card.platform.primaryColor.opacity(0.25), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                    )
                }
                .buttonStyle(CardPressStyle())
                .frame(maxWidth: 300)

                Text(shortTime(card.scheduledTime))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Completed action card bubble

struct CompletedCardBubble: View {
    let card: ScheduleCard

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(r: 0.027, g: 0.757, b: 0.376).opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        HStack(spacing: 5) {
                            Text(card.platform.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(card.platform.primaryColor)
                            Text("· 已发布")
                                .font(.system(size: 11))
                                .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(T.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(T.border, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                )

                Text(shortTime(card.scheduledTime))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Shared helpers

private var agentAvatar: some View {
    Circle()
        .fill(LinearGradient(
            colors: [T.accent, Color(r: 0.18, g: 0.35, b: 0.85)],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: 28, height: 28)
        .overlay(Text("🤖").font(.system(size: 13)))
}

func shortTime(_ date: Date) -> String {
    let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
    return f.string(from: date)
}

// MARK: - Card press style

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
