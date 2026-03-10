import SwiftUI

// MARK: - OpenClaw Chat View
struct OpenClawChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [OpenClawMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var sessionId: String = UUID().uuidString

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 0.044, g: 0.044, b: 0.115).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                if isLoading {
                                    HStack {
                                        ProgressView()
                                            .tint(.white)
                                        Text("思考中...")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastId = messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input
                    HStack(spacing: 12) {
                        TextField("输入消息...", text: $inputText, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(20)
                            .foregroundColor(.white)

                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.isEmpty ? .gray : Color(r: 0.55, g: 0.3, b: 0.95))
                        }
                        .disabled(inputText.isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color(r: 0.044, g: 0.044, b: 0.115))
                }
            }
            .navigationTitle("OpenClaw 对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(r: 0.044, g: 0.044, b: 0.115), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        messages.removeAll()
                        sessionId = UUID().uuidString
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = OpenClawMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        // Call backend API
        Task {
            do {
                let response = try await callOpenClaw(message: text, sessionId: sessionId)
                await MainActor.run {
                    if let reply = response["reply"] as? String {
                        let aiMessage = OpenClawMessage(role: .assistant, content: reply)
                        messages.append(aiMessage)
                    }
                    if let newSessionId = response["sessionId"] as? String {
                        sessionId = newSessionId
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = OpenClawMessage(role: .assistant, content: "❌ 错误：\(error.localizedDescription)")
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }

    private func callOpenClaw(message: String, sessionId: String) async throws -> [String: Any] {
        guard let url = URL(string: "http://localhost:8765/api/openclaw/chat") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": message,
            "userId": "ios-app",
            "sessionId": sessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        return json
    }
}

// MARK: - Chat Message Model
struct OpenClawMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case user
        case assistant
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: OpenClawMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    message.role == .user
                        ? Color(r: 0.55, g: 0.3, b: 0.95)
                        : Color.white.opacity(0.1)
                )
                .cornerRadius(16)

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
