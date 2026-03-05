import Foundation
import SwiftUI

// MARK: - Platform
enum Platform: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case wechatMoments = "朋友圈"
    case xiaohongshu   = "小红书"
    case wechatOA      = "公众号"
    case wechatPrivate = "微信私聊"

    var icon: String {
        switch self {
        case .wechatMoments: return "person.2.fill"
        case .xiaohongshu:   return "heart.fill"
        case .wechatOA:      return "antenna.radiowaves.left.and.right"
        case .wechatPrivate: return "bubble.left.and.bubble.right.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .wechatMoments: return Color(r: 0.027, g: 0.757, b: 0.376)
        case .xiaohongshu:   return Color(r: 1.000, g: 0.141, b: 0.259)
        case .wechatOA:      return Color(r: 0.471, g: 0.549, b: 0.714)
        case .wechatPrivate: return Color(r: 0.000, g: 0.690, b: 0.941)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .wechatMoments:
            return [Color(r: 0.027, g: 0.757, b: 0.376), Color(r: 0.012, g: 0.502, b: 0.247)]
        case .xiaohongshu:
            return [Color(r: 1.000, g: 0.141, b: 0.259), Color(r: 0.784, g: 0.063, b: 0.184)]
        case .wechatOA:
            return [Color(r: 0.471, g: 0.549, b: 0.714), Color(r: 0.263, g: 0.337, b: 0.502)]
        case .wechatPrivate:
            return [Color(r: 0.000, g: 0.690, b: 0.941), Color(r: 0.000, g: 0.478, b: 0.678)]
        }
    }
}

extension Color {
    init(r: Double, g: Double, b: Double) {
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Timeline item (chat messages)
enum TimelineItem: Identifiable {
    case agentText(id: UUID, text: String, time: Date)
    case userText(id: UUID, text: String, time: Date)
    case overviewCard(id: UUID, time: Date)
    case pendingAction(id: UUID, card: ScheduleCard)
    case completedAction(id: UUID, card: ScheduleCard)

    var id: UUID {
        switch self {
        case .agentText(let id, _, _):    return id
        case .userText(let id, _, _):     return id
        case .overviewCard(let id, _):    return id
        case .pendingAction(let id, _):   return id
        case .completedAction(let id, _): return id
        }
    }
}

// MARK: - ScheduleCard
struct ScheduleCard: Identifiable {
    let id: UUID
    let platform: Platform
    let title: String
    let content: String
    let scheduledTime: Date
    var isPosted: Bool
    var isManualTrigger: Bool

    init(
        id: UUID = UUID(),
        platform: Platform,
        title: String,
        content: String,
        scheduledTime: Date,
        isPosted: Bool = false,
        isManualTrigger: Bool = false
    ) {
        self.id = id
        self.platform = platform
        self.title = title
        self.content = content
        self.scheduledTime = scheduledTime
        self.isPosted = isPosted
        self.isManualTrigger = isManualTrigger
    }

    static func todayCards() -> [ScheduleCard] {
        let cal   = Calendar.current
        let today = Date()

        func t(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: today) ?? today
        }

        return [
            ScheduleCard(
                platform: .wechatMoments,
                title: "早间动态",
                content: "新的一天开始了！数字孪生系统已全面激活，今日工作按计划有序推进中。",
                scheduledTime: t(9, 0)
            ),
            ScheduleCard(
                platform: .xiaohongshu,
                title: "效率工具分享",
                content: "今天给大家分享我最近在用的效率神器，让工作和生活都更上一层楼！",
                scheduledTime: t(11, 30)
            ),
            ScheduleCard(
                platform: .wechatOA,
                title: "深度内容发布",
                content: "【数字孪生实践】全面解析个人数字资产的构建与管理策略，建立你的智能分身。",
                scheduledTime: t(14, 0)
            ),
            ScheduleCard(
                platform: .wechatPrivate,
                title: "互动卡片推送",
                content: "向重要联系人发送今日进展报告与互动邀请卡，维系高质量人脉连接。",
                scheduledTime: t(16, 30)
            ),
            ScheduleCard(
                platform: .wechatMoments,
                title: "晚间复盘",
                content: "今日任务完成度 98% | 数字孪生已同步今日所有知识节点与决策记录。",
                scheduledTime: t(21, 0)
            ),
        ]
    }
}
