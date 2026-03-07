import SwiftUI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id      = UUID()
    let isUser:  Bool
    let text:    String
    var isThinking = false
}

// MARK: - Preset Command
private struct PresetCommand: Identifiable {
    let id      = UUID()
    let icon:   String
    let label:  String
    let prompt: String
}

// MARK: - Floating Button
struct CommandChatButton: View {
    @Binding var showChat: Bool

    var body: some View {
        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { showChat = true } } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(r: 0.45, g: 0.20, b: 0.95), Color(r: 0.15, g: 0.40, b: 0.90)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(r: 0.35, g: 0.15, b: 0.85).opacity(0.55), radius: 14, y: 5)

                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Chat Panel
struct CommandChatView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var personaManager: PersonaManager

    @State private var messages: [ChatMessage] = []
    @State private var inputText      = ""
    @State private var isThinking     = false
    @FocusState private var inputFocused: Bool

    private let presets: [PresetCommand] = [
        PresetCommand(icon: "list.bullet.clipboard.fill", label: "今日计划",   prompt: "今天要发什么？"),
        PresetCommand(icon: "person.2.fill",              label: "发朋友圈",   prompt: "立即发布朋友圈内容"),
        PresetCommand(icon: "heart.fill",                 label: "推小红书",   prompt: "推送小红书内容"),
        PresetCommand(icon: "antenna.radiowaves.left.and.right", label: "发公众号", prompt: "发布公众号推文"),
        PresetCommand(icon: "bubble.left.and.bubble.right.fill", label: "发互动卡", prompt: "发送微信互动卡片"),
        PresetCommand(icon: "chart.bar.doc.horizontal.fill",     label: "生成报告", prompt: "生成今日内容发布报告"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 38, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                // Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(r: 0.45, g: 0.20, b: 0.95), Color(r: 0.15, g: 0.40, b: 0.90)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 34, height: 34)
                        Text(personaManager.selectedPersona.emoji)
                            .font(.system(size: 17))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(personaManager.selectedPersona.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("数字孪生代理人 · \(personaManager.selectedPersona.tone.rawValue)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.48))
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.white.opacity(0.38))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.1))

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { msg in
                                ChatBubbleView(message: msg,
                                               accentColors: personaManager.selectedPersona.tone.gradientColors)
                            }
                            if isThinking {
                                ThinkingBubbleView()
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                    }
                    .frame(height: 220)
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom") }
                    }
                    .onChange(of: isThinking) { _ in
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
                    }
                }

                Divider().background(Color.white.opacity(0.1)).padding(.bottom, 8)

                // Preset command chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(presets) { cmd in
                            Button {
                                sendMessage(text: cmd.prompt)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: cmd.icon)
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(cmd.label)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.09))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                                )
                            }
                            .disabled(isThinking)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 10)

                // Text input row
                HStack(spacing: 10) {
                    TextField("输入指令…", text: $inputText)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        )
                        .focused($inputFocused)
                        .onSubmit { sendMessage(text: inputText) }

                    Button { sendMessage(text: inputText) } label: {
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
                .padding(.bottom, 36)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(r: 0.068, g: 0.052, b: 0.158))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .ignoresSafeArea()
            )
        }
        .ignoresSafeArea()
        .onTapGesture { inputFocused = false }
        .onAppear {
            if messages.isEmpty {
                messages.append(ChatMessage(isUser: false,
                    text: "你好！我是「\(personaManager.selectedPersona.name)」数字孪生代理人。\n\n你可以向我发送指令，我来帮你管理今天的内容发布计划。"))
            }
        }
    }

    // MARK: - Send
    private func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        inputText    = ""
        inputFocused = false

        withAnimation(.spring(response: 0.3)) {
            messages.append(ChatMessage(isUser: true, text: trimmed))
        }

        isThinking = true
        let delay: Double = Double.random(in: 0.9...1.5)
        let deadline = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            isThinking = false
            let agentResp = agentResponse(for: trimmed)
            withAnimation(.spring(response: 0.35)) {
                messages.append(ChatMessage(isUser: false, text: agentResp.text))
            }
            if let platform = agentResp.platform {
                scheduleManager.queueManual(platform: platform)
            }
        }
    }

    // MARK: - Response Logic
    private struct AgentResponse {
        let text: String
        var platform: Platform? = nil
    }

    private func agentResponse(for input: String) -> AgentResponse {
        let s        = input.lowercased()
        let persona  = personaManager.selectedPersona
        let done     = scheduleManager.cards.filter { $0.isPosted }.count
        let total    = scheduleManager.cards.count

        if s.contains("今天") || s.contains("计划") || s.contains("行程") || s.contains("什么") {
            let lines = scheduleManager.cards.prefix(5).enumerated().map { i, c -> String in
                let status = c.isPosted ? "✅" : "⏳"
                return "\(i+1). [\(c.platform.rawValue)] \(c.title)  \(status)"
            }
            let body = "📋 今日发布计划（共 \(total) 条）：\n\n" + lines.joined(separator: "\n")
                     + "\n\n已完成 \(done)/\(total) 条，当前人设：\(persona.emoji) \(persona.name)"
            return AgentResponse(text: body)
        }
        if s.contains("朋友圈") {
            return AgentResponse(
                text: "✅ 朋友圈发布任务已加入待执行队列！\n\n请在主界面找到该任务卡片，确认后由代理人以「\(persona.name)」风格自动完成发布。",
                platform: .wechatMoments)
        }
        if s.contains("小红书") || s.contains("红书") {
            return AgentResponse(
                text: "✅ 小红书推送任务已加入待执行队列！\n\n请在主界面确认执行，代理人将以「\(persona.name)」风格自动创作并发布。",
                platform: .xiaohongshu)
        }
        if s.contains("公众号") || s.contains("推文") {
            return AgentResponse(
                text: "✅ 公众号推文任务已加入待执行队列！\n\n请在主界面确认执行，内容将按 \(persona.displayTone) 基调自动创作。",
                platform: .wechatOA)
        }
        if s.contains("互动") || s.contains("私聊") || s.contains("卡片") {
            return AgentResponse(
                text: "✅ 微信互动卡片任务已加入待执行队列！\n\n请在主界面确认执行，代理人将以「\(persona.name)」人设定制内容。",
                platform: .wechatPrivate)
        }
        if s.contains("报告") || s.contains("总结") || s.contains("统计") {
            let manual = scheduleManager.cards.filter { $0.isManualTrigger }.count
            let report = "📊 今日数字孪生运营报告\n─────────────────\n"
                       + "• 计划任务：\(total) 条\n• 已完成：\(done) 条\n"
                       + "• 手动触发：\(manual) 次\n"
                       + "• 当前人设：\(persona.emoji) \(persona.name)\n"
                       + "• 风格基调：\(persona.displayTone)\n"
                       + "─────────────────\n系统运行正常，数字孪生同步完成 ✅"
            return AgentResponse(text: report)
        }
        if s.contains("人设") || s.contains("切换") || s.contains("风格") {
            let tagStr  = persona.tags.map { "#\($0)" }.joined(separator: " ")
            let detail  = "当前激活人设：\n\n\(persona.emoji) \(persona.name)\n"
                        + "\(persona.displayTone) · \(persona.description)\n\n"
                        + "标签：\(tagStr)\n\n如需切换，请在顶部人设选择栏选择或长按编辑。"
            return AgentResponse(text: detail)
        }
        let fallbacks = [
            "指令已接收 ✅\n\n正在以「\(persona.name)」人设处理你的请求，稍候。",
            "明白！数字孪生代理人已记录该指令，将按照 \(persona.displayTone) 风格执行。\n\n如需立即触发某平台，可使用上方快捷按钮。",
            "好的，正在处理中 ⚡\n\n如果你想发布到特定平台，告诉我平台名称即可（如：发朋友圈、推小红书）。",
        ]
        return AgentResponse(text: fallbacks.randomElement()!)
    }
}

// MARK: - Chat Bubble
struct ChatBubbleView: View {
    let message: ChatMessage
    let accentColors: [Color]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(r: 0.45, g: 0.20, b: 0.95), Color(r: 0.15, g: 0.40, b: 0.90)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                    .overlay(Text("🤖").font(.system(size: 13)))
            }

            Text(message.text)
                .font(.system(size: 13.5))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if message.isUser {
                            LinearGradient(colors: accentColors,
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(BubbleShape(isUser: true))
                        } else {
                            BubbleShape(isUser: false)
                                .fill(Color.white.opacity(0.09))
                        }
                    }
                )
                .frame(maxWidth: 260, alignment: message.isUser ? .trailing : .leading)

            if message.isUser { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator
struct ThinkingBubbleView: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(r: 0.45, g: 0.20, b: 0.95), Color(r: 0.15, g: 0.40, b: 0.90)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 26, height: 26)
                .overlay(Text("🤖").font(.system(size: 13)))

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(phase == i ? 0.9 : 0.28))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.25 : 0.85)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(BubbleShape(isUser: false).fill(Color.white.opacity(0.09)))

            Spacer()
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - Bubble Shape
struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        return path
    }
}
