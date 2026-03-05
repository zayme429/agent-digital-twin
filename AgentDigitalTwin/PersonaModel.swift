import Foundation
import SwiftUI

// MARK: - PersonaTone
enum PersonaTone: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }

    case professional = "专业严谨"
    case friendly     = "亲切温暖"
    case creative     = "创意活泼"
    case concise      = "简洁高效"

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
    var tone: PersonaTone
    var tags: [String]

    static func == (lhs: AgentPersona, rhs: AgentPersona) -> Bool { lhs.id == rhs.id }

    static let defaults: [AgentPersona] = [
        AgentPersona(
            id: UUID(),
            name: "职场精英",
            emoji: "👔",
            description: "专业、严谨、高效的职场形象，适合商务场景的内容发布与互动",
            tone: .professional,
            tags: ["商务", "专业", "严谨"]
        ),
        AgentPersona(
            id: UUID(),
            name: "生活达人",
            emoji: "✨",
            description: "亲切温暖、充满正能量，适合生活方式内容分享和情感连接",
            tone: .friendly,
            tags: ["生活", "温暖", "治愈"]
        ),
        AgentPersona(
            id: UUID(),
            name: "创意博主",
            emoji: "🎨",
            description: "充满创意和个性，适合创作类内容输出和年轻受众互动",
            tone: .creative,
            tags: ["创意", "个性", "潮流"]
        ),
        AgentPersona(
            id: UUID(),
            name: "知识领袖",
            emoji: "🔬",
            description: "简洁有力、深度思考，适合知识分享、行业洞察与观点输出",
            tone: .concise,
            tags: ["知识", "深度", "洞察"]
        ),
    ]
}
