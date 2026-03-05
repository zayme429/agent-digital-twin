import SwiftUI

// MARK: - Persona Selector Strip (top of main screen)
struct PersonaSelectorView: View {
    @EnvironmentObject var personaManager: PersonaManager
    @State private var showSettings  = false
    @State private var editingPersona: AgentPersona?

    var body: some View {
        HStack(spacing: 0) {
            Text("人设")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.38))
                .padding(.leading, 20)
                .padding(.trailing, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(personaManager.personas) { persona in
                        PersonaChip(
                            persona:    persona,
                            isSelected: personaManager.selectedPersona.id == persona.id,
                            onTap:      { personaManager.select(persona) },
                            onLongPress: { editingPersona = persona }
                        )
                    }

                    // Add new persona button
                    Button { showSettings = true } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.07))
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.45))
                            }
                            Text("添加")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.35))
                                .frame(width: 42)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
            }

            // Settings icon
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.45))
                    .frame(width: 40, height: 40)
            }
            .padding(.trailing, 8)
        }
        .sheet(isPresented: $showSettings) {
            PersonaSettingsView().environmentObject(personaManager)
        }
        .sheet(item: $editingPersona) { persona in
            PersonaEditSheet(persona: persona, isNew: false) { personaManager.update($0) }
        }
    }
}

// MARK: - Single Persona Chip
struct PersonaChip: View {
    let persona: AgentPersona
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected
                            ? LinearGradient(colors: persona.tone.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.08)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(
                                isSelected ? persona.tone.color : Color.white.opacity(0.12),
                                lineWidth: isSelected ? 2 : 1
                            )
                        )
                        .shadow(color: isSelected ? persona.tone.color.opacity(0.45) : .clear,
                                radius: 8, x: 0, y: 2)

                    Text(persona.emoji)
                        .font(.system(size: 18))
                }

                Text(persona.name)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? persona.tone.color : Color.white.opacity(0.45))
                    .lineLimit(1)
                    .frame(width: 44)
            }
        }
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onLongPressGesture(minimumDuration: 0.5) { onLongPress() }
    }
}
