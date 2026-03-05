import SwiftUI

struct MessageInputView: View {
    @Binding var isPresented: Bool
    let onTrigger: (Platform) -> Void

    @State private var messageText       = ""
    @State private var selectedPlatform  = Platform.wechatMoments
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 38, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, 22)

                // Title row
                HStack {
                    Text("手动触发发布")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.white.opacity(0.38))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)

                // Platform chips
                sectionLabel("选择平台")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Platform.allCases) { p in
                            Button {
                                withAnimation(.spring(response: 0.28)) { selectedPlatform = p }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: p.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(p.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color.white.opacity(0.09))
                                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                                            .opacity(selectedPlatform == p ? 0 : 1)
                                        LinearGradient(colors: p.gradientColors,
                                                       startPoint: .leading, endPoint: .trailing)
                                            .clipShape(Capsule())
                                            .opacity(selectedPlatform == p ? 1 : 0)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)

                // Message input
                sectionLabel("消息内容（选填）")

                TextField("输入触发内容…", text: $messageText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(3...5)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedPlatform.primaryColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .focused($focused)
                    .padding(.bottom, 22)

                // Trigger button
                Button {
                    onTrigger(selectedPlatform)
                    withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("立即触发")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(colors: selectedPlatform.gradientColors,
                                       startPoint: .leading, endPoint: .trailing)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .shadow(color: selectedPlatform.primaryColor.opacity(0.45), radius: 14, y: 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(r: 0.07, g: 0.055, b: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .ignoresSafeArea()
            )
        }
        .ignoresSafeArea()
        .onTapGesture { focused = false }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
}
