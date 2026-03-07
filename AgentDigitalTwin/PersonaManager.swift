import Foundation
import SwiftUI

class PersonaManager: ObservableObject {
    @Published var personas: [AgentPersona]
    @Published var selectedPersona: AgentPersona

    init() {
        let defaults = AgentPersona.defaults
        self.personas        = defaults
        self.selectedPersona = defaults[0]
        loadFromBackend()
    }

    // MARK: - Backend sync

    func loadFromBackend() {
        guard let url = URL(string: "http://localhost:8765/api/personas") else { return }
        URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, _, error in
            guard let self, error == nil, let data else { return }
            guard
                let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let rawPersonas = json["personas"] as? [[String: Any]],
                !rawPersonas.isEmpty
            else { return }
            let decoded = rawPersonas.compactMap { AgentPersona.fromDict($0) }
            guard !decoded.isEmpty else { return }
            let selectedId = (json["selectedPersonaId"] as? String)?.lowercased()
            DispatchQueue.main.async {
                self.personas = decoded
                if let sid   = selectedId,
                   let found = decoded.first(where: { $0.id.uuidString.lowercased() == sid }) {
                    self.selectedPersona = found
                } else if let first = decoded.first {
                    self.selectedPersona = first
                }
            }
        }.resume()
    }

    func saveToBackend() {
        guard let url = URL(string: "http://localhost:8765/api/personas") else { return }
        let payload: [String: Any] = [
            "personas":        personas.map { $0.toDict() },
            "selectedPersonaId": selectedPersona.id.uuidString.lowercased(),
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }

    // MARK: - CRUD

    func select(_ persona: AgentPersona) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPersona = persona
        }
        saveToBackend()
    }

    func add(_ persona: AgentPersona) {
        withAnimation(.spring(response: 0.4)) {
            personas.append(persona)
        }
        saveToBackend()
    }

    func update(_ persona: AgentPersona) {
        guard let idx = personas.firstIndex(where: { $0.id == persona.id }) else { return }
        withAnimation {
            personas[idx] = persona
            if selectedPersona.id == persona.id { selectedPersona = persona }
        }
        saveToBackend()
    }

    func delete(_ persona: AgentPersona) {
        withAnimation {
            personas.removeAll { $0.id == persona.id }
            if selectedPersona.id == persona.id, let first = personas.first {
                selectedPersona = first
            }
        }
        saveToBackend()
    }
}
