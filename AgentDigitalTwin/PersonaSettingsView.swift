import SwiftUI

// MARK: - Persona Settings (full list + manage)
struct PersonaSettingsView: View {
    @EnvironmentObject var personaManager: PersonaManager
    @Environment(\.dismiss) private var dismiss
    @State private var showNewPersona  = false
    @State private var editingPersona: AgentPersona?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 0.044, g: 0.044, b: 0.115).ignoresSafeArea()

                List {
                    ForEach(personaManager.personas) { persona in
                        PersonaListRow(
                            persona: persona,
                            isSelected: personaManager.selectedPersona.id == persona.id
                        ) {
                            personaManager.select(persona)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(
                                    personaManager.selectedPersona.id == persona.id ? 0.1 : 0.05))
                                .padding(.vertical, 2)
                        )
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                personaManager.delete(persona)
                            } label: { Label("删除", systemImage: "trash") }

                            Button {
                                editingPersona = persona
                            } label: { Label("编辑", systemImage: "pencil") }
                                .tint(Color(r: 0.35, g: 0.15, b: 0.85))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("人设配置")
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
                        showNewPersona = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(r: 0.55, g: 0.3, b: 0.95))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNewPersona) {
            PersonaEditSheet(
                persona: AgentPersona(id: UUID(), name: "", emoji: "🤖",
                                      description: "", tone: .professional, toneLabel: "专业严谨", tags: []),
                isNew: true
            ) { personaManager.add($0) }
        }
        .sheet(item: $editingPersona) { persona in
            PersonaEditSheet(persona: persona, isNew: false) { personaManager.update($0) }
        }
    }
}

// MARK: - List Row
struct PersonaListRow: View {
    let persona: AgentPersona
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: persona.tone.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Text(persona.emoji)
                        .font(.system(size: 24))
                }
                .shadow(color: persona.tone.color.opacity(0.4), radius: 8, y: 2)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(persona.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text(persona.displayTone)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(persona.tone.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(persona.tone.color.opacity(0.18)))
                    }

                    Text(persona.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)

                    if !persona.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(persona.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.38))
                            }
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(persona.tone.color)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Edit / Create Sheet
struct PersonaEditSheet: View {
    @State private var persona: AgentPersona
    let isNew: Bool
    let onSave: (AgentPersona) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tagInput = ""

    init(persona: AgentPersona, isNew: Bool, onSave: @escaping (AgentPersona) -> Void) {
        _persona  = State(initialValue: persona)
        self.isNew   = isNew
        self.onSave  = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 0.044, g: 0.044, b: 0.115).ignoresSafeArea()

                Form {
                    // Preview
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: persona.tone.gradientColors,
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                        .frame(width: 64, height: 64)
                                    Text(persona.emoji)
                                        .font(.system(size: 32))
                                }
                                .shadow(color: persona.tone.color.opacity(0.5), radius: 12, y: 4)

                                Text(persona.name.isEmpty ? "人设名称" : persona.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("基本信息") {
                        LabeledField(label: "头像 Emoji") {
                            TextField("🤖", text: $persona.emoji)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        LabeledField(label: "人设名称") {
                            TextField("如：职场精英", text: $persona.name)
                                .multilineTextAlignment(.trailing)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("人设描述")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField("描述该人设的特点与适用场景", text: $persona.description, axis: .vertical)
                                .lineLimit(3...5)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("风格基调") {
                        ForEach(PersonaTone.allCases) { tone in
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    persona.tone = tone
                                    persona.toneLabel = tone.rawValue
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(tone.color)
                                        .frame(width: 10, height: 10)
                                    Text(tone.rawValue)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if persona.tone == tone {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(tone.color)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("标签") {
                        ForEach(persona.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .foregroundColor(Color.white.opacity(0.75))
                        }
                        .onDelete { persona.tags.remove(atOffsets: $0) }

                        HStack {
                            TextField("添加标签（回车确认）", text: $tagInput)
                                .foregroundColor(.white)
                                .onSubmit { appendTag() }
                            if !tagInput.isEmpty {
                                Button("添加") { appendTag() }
                                    .foregroundColor(Color(r: 0.55, g: 0.3, b: 0.95))
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "新建人设" : "编辑人设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(r: 0.044, g: 0.044, b: 0.115), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(persona)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(persona.name.isEmpty
                        ? Color.white.opacity(0.3)
                        : Color(r: 0.55, g: 0.3, b: 0.95))
                    .disabled(persona.name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func appendTag() {
        let t = tagInput.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        persona.tags.append(t)
        tagInput = ""
    }
}

// MARK: - Helper
private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))
            Spacer()
            content
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}
