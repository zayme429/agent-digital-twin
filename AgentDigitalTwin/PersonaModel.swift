import Foundation
import SwiftUI

// MARK: - PersonaTone
enum PersonaTone: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }

    case professional = "专业严谨"
    case friendly     = "亲切温暖"
    case creative     = "创意活泼"
    case concise      = "简洁高效"

    /// Key used when serializing to/from the backend JSON (Chinese label = rawValue)
    var backendKey: String { rawValue }

    static func fromBackendKey(_ key: String) -> PersonaTone {
        // Match by Chinese label (new format, same as rawValue)
        if let found = PersonaTone.allCases.first(where: { $0.rawValue == key }) { return found }
        // Fall back to English keys (legacy format)
        switch key {
        case "professional": return .professional
        case "friendly":     return .friendly
        case "creative":     return .creative
        case "concise":      return .concise
        default:             return .professional
        }
    }

    var color: Color {
        switch self {
        case .professional: return Color(r: 0.341, g: 0.420, b: 0.714)
        case .friendly:     return Color(r: 1.000, g: 0.550, b: 0.200)
        case .creative:     return Color(r: 0.850, g: 0.200, b: 0.850)
        case .concise:      return Color(r: 0.027, g: 0.757, b: 0.376)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .professional: return [Color(r: 0.341, g: 0.420, b: 0.714), Color(r: 0.220, g: 0.300, b: 0.580)]
        case .friendly:     return [Color(r: 1.000, g: 0.550, b: 0.200), Color(r: 0.900, g: 0.380, b: 0.100)]
        case .creative:     return [Color(r: 0.850, g: 0.200, b: 0.850), Color(r: 0.600, g: 0.100, b: 0.700)]
        case .concise:      return [Color(r: 0.027, g: 0.757, b: 0.376), Color(r: 0.012, g: 0.502, b: 0.247)]
        }
    }
}

// MARK: - AgentPersona
struct AgentPersona: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var emoji: String
    var description: String
    var tone: PersonaTone           // used for color/gradient styling only
    var toneLabel: String = ""      // raw display text from backend; falls back to tone.rawValue if empty
    var tags: [String]

    /// Display label for tone — uses toneLabel if non-empty, falls back to tone.rawValue
    var displayTone: String { toneLabel.isEmpty ? tone.rawValue : toneLabel }

    static func == (lhs: AgentPersona, rhs: AgentPersona) -> Bool { lhs.id == rhs.id }

    func toDict() -> [String: Any] {
        ["id": id.uuidString.lowercased(),
         "name": name,
         "emoji": emoji,
         "description": description,
         "tone": displayTone,   // send raw label back so custom text is preserved
         "tags": tags]
    }

    static func fromDict(_ dict: [String: Any]) -> AgentPersona? {
        guard let name = dict["name"] as? String else { return nil }
        let rawTone  = dict["tone"] as? String ?? ""
        let tone     = PersonaTone.fromBackendKey(rawTone)   // best-fit enum for styling
        let idStr    = dict["id"] as? String ?? UUID().uuidString
        let id       = UUID(uuidString: idStr) ?? UUID()
        return AgentPersona(
            id:          id,
            name:        name,
            emoji:       dict["emoji"]       as? String   ?? "👤",
            description: dict["description"] as? String   ?? "",
            tone:        tone,
            toneLabel:   rawTone.isEmpty ? tone.rawValue : rawTone,
            tags:        dict["tags"]        as? [String] ?? []
        )
    }

    static let defaults: [AgentPersona] = [
        AgentPersona(id: UUID(), name: "职场精英", emoji: "👔",
                     description: "专业、严谨、高效的职场形象，适合商务场景的内容发布与互动",
                     tone: .professional, toneLabel: "专业严谨", tags: ["商务", "专业", "严谨"]),
        AgentPersona(id: UUID(), name: "生活达人", emoji: "✨",
                     description: "亲切温暖、充满正能量，适合生活方式内容分享和情感连接",
                     tone: .friendly, toneLabel: "亲切温暖", tags: ["生活", "温暖", "治愈"]),
        AgentPersona(id: UUID(), name: "创意博主", emoji: "🎨",
                     description: "充满创意和个性，适合创作类内容输出和年轻受众互动",
                     tone: .creative, toneLabel: "创意活泼", tags: ["创意", "个性", "潮流"]),
        AgentPersona(id: UUID(), name: "知识领袖", emoji: "🔬",
                     description: "简洁有力、深度思考，适合知识分享、行业洞察与观点输出",
                     tone: .concise, toneLabel: "简洁高效", tags: ["知识", "深度", "洞察"]),
    ]
}
