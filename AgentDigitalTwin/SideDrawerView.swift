import SwiftUI

private enum DS {
    static let bg       = Color(red: 0.970, green: 0.968, blue: 0.980)
    static let card     = Color.white
    static let accent   = Color(red: 0.330, green: 0.180, blue: 0.780)
    static let label    = Color(red: 0.12,  green: 0.10,  blue: 0.18)
    static let sub      = Color(red: 0.55,  green: 0.53,  blue: 0.62)
    static let divider  = Color(red: 0.88,  green: 0.876, blue: 0.900)
    static let border   = Color(red: 0.90,  green: 0.896, blue: 0.912)
}

struct SideDrawerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var personaManager:  PersonaManager
    @EnvironmentObject var scheduleManager: ScheduleManager

    @State private var showPersonaSettings = false
    @State private var showCompanion       = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {

                // ── Header card ────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("代理人控制台")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DS.label)
                        Spacer()
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(DS.sub)
                        }
                    }

                    HStack(spacing: 10) {
                        Text(personaManager.selectedPersona.emoji)
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(personaManager.selectedPersona.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DS.label)
                            Text(personaManager.selectedPersona.tone.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(DS.sub)
                        }
                        Spacer()
                        Button { showPersonaSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundColor(DS.sub)
                                .padding(8)
                                .background(Circle().fill(DS.border))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.card)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(DS.border, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 56)
                .padding(.bottom, 16)

                Divider().background(DS.divider)

                // ── Scrollable sections ────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Tools section
                        drawerSection("工具") {
                            Button {
                                showCompanion = true
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(red: 0.33, green: 0.18, blue: 0.78).opacity(0.12))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "person.wave.2.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(DS.accent)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("智能伴聊")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(DS.label)
                                        Text("实时语音 · 沟通建议")
                                            .font(.system(size: 11))
                                            .foregroundColor(DS.sub)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(DS.sub)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(DS.card)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(DS.border, lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1))
                            }
                        }

                        Divider().background(DS.divider)

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

                        Divider().background(DS.divider)

                        // Today completed
                        drawerSection("今日已执行 (\(scheduleManager.completedCards.count))") {
                            if scheduleManager.completedCards.isEmpty {
                                Text("暂无已执行任务")
                                    .font(.system(size: 12))
                                    .foregroundColor(DS.sub)
                                    .padding(.horizontal, 4)
                            } else {
                                ForEach(scheduleManager.completedCards) { card in
                                    DrawerCompletedRow(card: card)
                                }
                            }
                        }

                        Divider().background(DS.divider)

                        // History (placeholder)
                        drawerSection("历史对话") {
                            ForEach(1..<4) { i in DrawerHistoryRow(daysAgo: i) }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
            }
            .frame(width: 280)
            .background(DS.bg)
            .overlay(alignment: .trailing) {
                Rectangle().fill(DS.divider).frame(width: 1)
            }

            Spacer()
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPersonaSettings) {
            PersonaSettingsView().environmentObject(personaManager)
        }
        .fullScreenCover(isPresented: $showCompanion) {
            CompanionChatView(client: .wangJie)
        }
    }

    @ViewBuilder
    private func drawerSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DS.sub)
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

    private let accent = Color(red: 0.330, green: 0.180, blue: 0.780)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(persona.emoji)
                    .font(.system(size: 17))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(isSelected ? accent.opacity(0.12) : Color(red: 0.92, green: 0.918, blue: 0.930))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? accent : Color(red: 0.20, green: 0.18, blue: 0.28))
                    Text(persona.tone.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(accent)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accent.opacity(0.06) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? accent.opacity(0.18) : Color.clear, lineWidth: 1)
                    )
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
                .foregroundColor(Color(red: 0.027, green: 0.757, blue: 0.376))
            Text(card.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.20, green: 0.18, blue: 0.28))
                .lineLimit(1)
            Spacer()
            Text(timeStr)
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.90, green: 0.896, blue: 0.912), lineWidth: 1))
        )
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
                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
            Text(dateStr)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.20, green: 0.18, blue: 0.28))
            Spacer()
            Text("4 条记录")
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.90, green: 0.896, blue: 0.912), lineWidth: 1))
        )
    }
}
