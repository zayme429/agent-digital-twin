import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var personaManager:  PersonaManager

    @State private var showDrawer   = false
    @State private var inputText    = ""
    @State private var isThinking   = false
    @State private var confirmCard: ScheduleCard?
    @State private var progressCard: ScheduleCard?
    @State private var showProgress = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            LinearGradient(
                colors: [
                    Color(r: 0.044, g: 0.044, b: 0.115),
                    Color(r: 0.076, g: 0.044, b: 0.172),
                    Color(r: 0.044, g: 0.044, b: 0.115),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            StarsView().ignoresSafeArea()

            // ── Main chat column ─────────────────────────────────────────
            VStack(spacing: 0) {
                chatHeader
                Divider().background(Color.white.opacity(0.08))
                chatScrollView
                Divider().background(Color.white.opacity(0.08))
                chatInputBar
            }

            // ── Left drawer ──────────────────────────────────────────────
            if showDrawer {
                Color.black.opacity(0.45)
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

            // ── Confirm sheet ────────────────────────────────────────────
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

            // ── Progress overlay ─────────────────────────────────────────
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

    // MARK: - Header bar

    private var chatHeader: some View {
        HStack(spacing: 10) {
            // Triangle drawer toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showDrawer.toggle()
                }
            } label: {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(showDrawer ? 0.85 : 0.45))
                    .rotationEffect(.degrees(showDrawer ? 270 : 90))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.07)))
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showDrawer)
            }
            .padding(.leading, 14)

            // Agent avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(r: 0.45, g: 0.20, b: 0.95),
                                 Color(r: 0.15, g: 0.40, b: 0.90)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                Text(personaManager.selectedPersona.emoji)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(personaManager.selectedPersona.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(sessionDateString)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.45))
            }

            Spacer()

            let done  = scheduleManager.completedCards.count
            let total = scheduleManager.cards.count
            Text("\(done)/\(total) 完成")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.55))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .padding(.trailing, 16)
        }
        .frame(height: 54)
        .background(Color.black.opacity(0.15))
    }

    private var sessionDateString: String {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    // MARK: - Chat scroll

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(scheduleManager.timeline) { item in
                        TimelineItemView(item: item) { card in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                confirmCard = card
                            }
                        }
                    }
                    if isThinking {
                        ThinkingBubble()
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }
            .onChange(of: scheduleManager.timeline.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: isThinking) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Input bar

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("发送指令给代理人…", text: $inputText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1))
                )
                .focused($inputFocused)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        (inputText.isEmpty || isThinking)
                            ? Color.white.opacity(0.2)
                            : Color(r: 0.45, g: 0.20, b: 0.95)
                    )
            }
            .disabled(inputText.isEmpty || isThinking)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.20))
    }

    // MARK: - Send message

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        inputText    = ""
        inputFocused = false

        scheduleManager.appendUser(trimmed)
        isThinking = true

        let delay = Double.random(in: 0.9...1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isThinking = false
            let resp = agentResponse(for: trimmed)
            scheduleManager.appendAgent(resp.text)
            if let platform = resp.platform {
                scheduleManager.queueManual(platform: platform)
            }
        }
    }

    private struct AgentResp { let text: String; var platform: Platform? = nil }

    private func agentResponse(for input: String) -> AgentResp {
        let s       = input.lowercased()
        let persona = personaManager.selectedPersona
        let done    = scheduleManager.completedCards.count
        let total   = scheduleManager.cards.count

        if s.contains("今天") || s.contains("计划") || s.contains("行程") || s.contains("什么") {
            let lines = scheduleManager.cards.prefix(5).enumerated().map { i, c -> String in
                let status = c.isPosted ? "✅" : "⏳"
                return "\(i+1). [\(c.platform.rawValue)] \(c.title) \(status)"
            }
            return AgentResp(text: "📋 今日发布计划（\(total) 条）：\n\n"
                + lines.joined(separator: "\n")
                + "\n\n已完成 \(done)/\(total)，当前人设：\(persona.emoji) \(persona.name)")
        }
        if s.contains("朋友圈") {
            return AgentResp(
                text: "✅ 朋友圈任务已加入待执行队列！请在下方卡片确认执行。",
                platform: .wechatMoments)
        }
        if s.contains("小红书") || s.contains("红书") {
            return AgentResp(
                text: "✅ 小红书推送任务已加入待执行队列！请在下方卡片确认执行。",
                platform: .xiaohongshu)
        }
        if s.contains("公众号") || s.contains("推文") {
            return AgentResp(
                text: "✅ 公众号推文任务已加入待执行队列！请在下方卡片确认执行。",
                platform: .wechatOA)
        }
        if s.contains("互动") || s.contains("私聊") || s.contains("卡片") {
            return AgentResp(
                text: "✅ 微信互动卡片任务已加入待执行队列！请在下方卡片确认执行。",
                platform: .wechatPrivate)
        }
        if s.contains("报告") || s.contains("总结") {
            let manual = scheduleManager.cards.filter { $0.isManualTrigger }.count
            return AgentResp(text: "📊 今日运营报告\n─────────\n计划：\(total) 条 · 完成：\(done) 条 · 手动：\(manual) 次\n人设：\(persona.emoji) \(persona.name) · \(persona.tone.rawValue)\n─────────\n系统运行正常 ✅")
        }
        if s.contains("人设") || s.contains("切换") {
            return AgentResp(text: "当前人设：\(persona.emoji) \(persona.name)\n\(persona.tone.rawValue) · \(persona.description)\n\n如需切换，请点击左上角 ▶ 菜单。")
        }
        let fallbacks = [
            "指令已接收 ✅\n\n正在以「\(persona.name)」人设处理你的请求。",
            "明白！将按照 \(persona.tone.rawValue) 风格执行。\n\n如需触发某平台，可直接告诉我（如：发朋友圈）。",
            "好的，正在处理中 ⚡\n\n如需发布内容，告诉我平台名称即可。",
        ]
        return AgentResp(text: fallbacks.randomElement()!)
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
        case .agentText(_, let text, _):
            AgentBubble(text: text)
        case .userText(_, let text, _):
            UserBubble(text: text)
        case .overviewCard(_, _):
            OverviewCardBubble()
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

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1))
                )
                .frame(maxWidth: 280, alignment: .leading)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - User text bubble

struct UserBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 0)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(r: 0.45, g: 0.20, b: 0.95),
                                     Color(r: 0.15, g: 0.40, b: 0.90)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .frame(maxWidth: 260, alignment: .trailing)
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
                        .fill(Color.white.opacity(phase == i ? 0.9 : 0.28))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.25 : 0.85)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.10)))
            Spacer()
        }
        .onReceive(ticker) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - Overview card bubble

struct OverviewCardBubble: View {
    @EnvironmentObject var scheduleManager: ScheduleManager

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(r: 0.45, g: 0.20, b: 0.95))
                    Text("今日总览 · \(dateString)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(scheduleManager.timelineCards.enumerated()), id: \.element.id) { idx, card in
                            MiniTimelineDot(
                                card: card,
                                isLast: idx == scheduleManager.timelineCards.count - 1
                            )
                        }
                    }
                }

                let done  = scheduleManager.completedCards.count
                let total = scheduleManager.cards.count
                HStack(spacing: 8) {
                    statPill("list.bullet",          "\(total)",       "计划",  .white.opacity(0.55))
                    statPill("checkmark.circle.fill", "\(done)",       "完成",  Color(r: 0.027, g: 0.757, b: 0.376))
                    statPill("clock.fill",            "\(total-done)", "待执行", Color(r: 1.0, g: 0.6, b: 0.1))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1))
            )
            .frame(maxWidth: 310)
            Spacer(minLength: 0)
        }
    }

    private func statPill(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
            Text("\(value) \(label)").font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.07)))
    }
}

// MARK: - Mini timeline dot (inside OverviewCardBubble)

private struct MiniTimelineDot: View {
    let card:   ScheduleCard
    let isLast: Bool

    private var isDue: Bool { card.scheduledTime <= Date() && !card.isPosted }

    private var timeStr: String {
        let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(timeStr)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .frame(width: 46)

                ZStack {
                    Circle()
                        .fill(card.isPosted
                              ? card.platform.primaryColor.opacity(0.20)
                              : isDue
                                ? Color(r: 1.0, g: 0.6, b: 0.1).opacity(0.20)
                                : Color.white.opacity(0.06))
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(
                            card.isPosted ? card.platform.primaryColor
                                : isDue   ? Color(r: 1.0, g: 0.6, b: 0.1)
                                          : Color.white.opacity(0.18),
                            lineWidth: 1.5))

                    if card.isPosted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(card.platform.primaryColor)
                    } else {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isDue
                                ? Color(r: 1.0, g: 0.6, b: 0.1)
                                : card.platform.primaryColor.opacity(0.6))
                    }
                }

                Text(card.platform.rawValue)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(card.isPosted
                        ? card.platform.primaryColor : Color.white.opacity(0.38))
                    .frame(width: 46).multilineTextAlignment(.center)
            }

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 16, height: 1)
                    .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Pending action card bubble

struct PendingCardBubble: View {
    let card:  ScheduleCard
    let onTap: () -> Void

    private var timeStr: String {
        let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: card.platform.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(card.platform.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: card.platform.gradientColors,
                                           startPoint: .leading, endPoint: .trailing)
                                .clipShape(Capsule())
                        )

                        if card.isManualTrigger {
                            Text("手动")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(Color(r: 1.0, g: 0.6, b: 0.0)))
                        }

                        Spacer()

                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color.white.opacity(0.38))
                            Text(timeStr)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }

                    Text(card.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(card.content)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.62))
                        .lineLimit(2)

                    HStack {
                        Spacer()
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill").font(.system(size: 10, weight: .bold))
                            Text("点击确认执行").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(
                            LinearGradient(colors: card.platform.gradientColors,
                                           startPoint: .leading, endPoint: .trailing)
                                .clipShape(Capsule())
                        )
                        .shadow(color: card.platform.primaryColor.opacity(0.4), radius: 8, y: 3)
                    }
                }
                .padding(13)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 16)
                            .fill(RadialGradient(
                                colors: [card.platform.primaryColor.opacity(0.12), .clear],
                                center: .topLeading, startRadius: 0, endRadius: 160))
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [card.platform.primaryColor.opacity(0.6),
                                             Color.white.opacity(0.06)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                    }
                )
                .shadow(color: card.platform.primaryColor.opacity(0.20), radius: 12, y: 4)
            }
            .buttonStyle(CardPressStyle())
            .frame(maxWidth: 300)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Completed action card bubble

struct CompletedCardBubble: View {
    let card: ScheduleCard

    private var timeStr: String {
        let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            agentAvatar

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(card.platform.primaryColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(card.platform.primaryColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.85))
                    HStack(spacing: 5) {
                        Text(card.platform.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(card.platform.primaryColor.opacity(0.8))
                        Text("· 已发布")
                            .font(.system(size: 11))
                            .foregroundColor(Color(r: 0.027, g: 0.757, b: 0.376))
                        Text(timeStr)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.38))
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1))
            )

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Shared agent avatar

private var agentAvatar: some View {
    Circle()
        .fill(LinearGradient(
            colors: [Color(r: 0.45, g: 0.20, b: 0.95),
                     Color(r: 0.15, g: 0.40, b: 0.90)],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: 28, height: 28)
        .overlay(Text("🤖").font(.system(size: 13)))
}

// MARK: - Card press style

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
