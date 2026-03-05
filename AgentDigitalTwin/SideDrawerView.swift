import SwiftUI

struct SideDrawerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var personaManager:  PersonaManager
    @EnvironmentObject var scheduleManager: ScheduleManager

    @State private var showPersonaSettings = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {

                // ── Header card ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("代理人控制台")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.white.opacity(0.38))
                        }
                    }

                    HStack(spacing: 10) {
                        Text(personaManager.selectedPersona.emoji)
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(personaManager.selectedPersona.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(personaManager.selectedPersona.tone.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        Spacer()
                        Button { showPersonaSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1))
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 56)
                .padding(.bottom, 16)

                Divider().background(Color.white.opacity(0.08))

                // ── Scrollable sections ───────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {

                        // Persona list
                        drawerSection("切换人设") {
                            ForEach(personaManager.personas) { persona in
                                PersonaDrawerRow(
                                    persona:    persona,
                                    isSelected: persona.id == personaManager.selectedPersona.id
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        personaManager.select(persona)
                                    }
                                }
                            }
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // Today completed
                        drawerSection("今日已执行 (\(scheduleManager.completedCards.count))") {
                            if scheduleManager.completedCards.isEmpty {
                                Text("暂无已执行任务")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.35))
                                    .padding(.horizontal, 4)
                            } else {
                                ForEach(scheduleManager.completedCards) { card in
                                    DrawerCompletedRow(card: card)
                                }
                            }
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // History (placeholder)
                        drawerSection("历史对话") {
                            ForEach(1..<4) { i in DrawerHistoryRow(daysAgo: i) }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
            }
            .frame(width: 280)
            .background(
                Color(r: 0.058, g: 0.042, b: 0.145)
                    .overlay(
                        LinearGradient(
                            colors: [Color(r: 0.45, g: 0.20, b: 0.95).opacity(0.08), .clear],
                            startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(alignment: .trailing) {
                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1)
            }

            Spacer()
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPersonaSettings) {
            PersonaSettingsView().environmentObject(personaManager)
        }
    }

    @ViewBuilder
    private func drawerSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.white.opacity(0.38))
                .textCase(.uppercase)
            content()
        }
    }
}

// MARK: - Persona row

private struct PersonaDrawerRow: View {
    let persona:    AgentPersona
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(persona.emoji)
                    .font(.system(size: 17))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(isSelected
                            ? LinearGradient(
                                colors: [Color(r: 0.45, g: 0.20, b: 0.95),
                                         Color(r: 0.15, g: 0.40, b: 0.90)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                    Text(persona.tone.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(r: 0.45, g: 0.20, b: 0.95))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completed row

private struct DrawerCompletedRow: View {
    let card: ScheduleCard

    private var timeStr: String {
        let f = DateFormatter(); f.timeStyle = .short; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: card.scheduledTime)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(card.platform.primaryColor)
            Text(card.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.65))
                .lineLimit(1)
            Spacer()
            Text(timeStr)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.35))
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
    }
}

// MARK: - History row

private struct DrawerHistoryRow: View {
    let daysAgo: Int

    private var dateStr: String {
        let d = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日"
        return f.string(from: d)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.35))
            Text(dateStr)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.5))
            Spacer()
            Text("4 条记录")
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.28))
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
    }
}
