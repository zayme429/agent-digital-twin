import Foundation
import SwiftUI

class PersonaManager: ObservableObject {
    @Published var personas: [AgentPersona]
    @Published var selectedPersona: AgentPersona

    init() {
        let defaults = AgentPersona.defaults
        self.personas       = defaults
        self.selectedPersona = defaults[0]
    }

    func select(_ persona: AgentPersona) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPersona = persona
        }
    }

    func add(_ persona: AgentPersona) {
        withAnimation(.spring(response: 0.4)) {
            personas.append(persona)
        }
    }

    func update(_ persona: AgentPersona) {
        guard let idx = personas.firstIndex(where: { $0.id == persona.id }) else { return }
        withAnimation {
            personas[idx] = persona
            if selectedPersona.id == persona.id { selectedPersona = persona }
        }
    }

    func delete(_ persona: AgentPersona) {
        withAnimation {
            personas.removeAll { $0.id == persona.id }
            if selectedPersona.id == persona.id, let first = personas.first {
                selectedPersona = first
            }
        }
    }
}
