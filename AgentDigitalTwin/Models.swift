import Foundation
import SwiftUI

// MARK: - Platform
enum Platform: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case wechatMoments = "朋友圈"
    case xiaohongshu   = "小红书"
    case wechatOA      = "公众号"
    case wechatPrivate = "微信私聊"
    case clientMgmt    = "客户经营"
    case meeting       = "面谈"

    var icon: String {
        switch self {
        case .wechatMoments: return "person.2.fill"
        case .xiaohongshu:   return "heart.fill"
        case .wechatOA:      return "antenna.radiowaves.left.and.right"
        case .wechatPrivate: return "bubble.left.and.bubble.right.fill"
        case .clientMgmt:    return "person.3.fill"
        case .meeting:       return "cup.and.saucer.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .wechatMoments: return Color(r: 0.027, g: 0.757, b: 0.376)
        case .xiaohongshu:   return Color(r: 1.000, g: 0.141, b: 0.259)
        case .wechatOA:      return Color(r: 0.471, g: 0.549, b: 0.714)
        case .wechatPrivate: return Color(r: 0.000, g: 0.690, b: 0.941)
        case .clientMgmt:    return Color(r: 1.000, g: 0.500, b: 0.100)
        case .meeting:       return Color(r: 0.520, g: 0.200, b: 0.820)
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
        case .clientMgmt:
            return [Color(r: 1.000, g: 0.500, b: 0.100), Color(r: 0.850, g: 0.330, b: 0.020)]
        case .meeting:
            return [Color(r: 0.520, g: 0.200, b: 0.820), Color(r: 0.350, g: 0.100, b: 0.620)]
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
                title: "早安问候",
                content: "风格：专业顾问｜「早安。好的保障不是等风险来了才想起，而是在平静日常里把底盘打稳。」+问候贴图",
                scheduledTime: t(8, 45)
            ),
            ScheduleCard(
                platform: .wechatPrivate,
                title: "跟进：张总重疾险签约",
                content: "每30分钟查询核保进度，17:00核保完成：肝癌除外承保。已生成安抚话术待发送",
                scheduledTime: t(9, 0)
            ),
            ScheduleCard(
                platform: .xiaohongshu,
                title: "热点切入｜黄金波动",
                content: "美以冲突升级→黄金/美元波动→年金险确定性规划科普。热点卡视觉，不硬推。",
                scheduledTime: t(9, 10)
            ),
            ScheduleCard(
                platform: .clientMgmt,
                title: "客户互动经营（10人）",
                content: "老客维系 4｜潜力跟进 3｜生日/纪念日 2｜沉默唤醒 1，个性化私信触达",
                scheduledTime: t(9, 30)
            ),
            ScheduleCard(
                platform: .clientMgmt,
                title: "高潜面谈邀约（10人）",
                content: "推荐邀约窗口：下周五 14-17点｜周六 10-12点。附话术+预判异议，支持批量发送",
                scheduledTime: t(10, 20)
            ),
            ScheduleCard(
                platform: .meeting,
                title: "面谈：王姐 @ 星巴克",
                content: "家庭健康保障规划（重疾险为主）｜40分钟｜目标：当场确定预算与保障优先级",
                scheduledTime: t(15, 0)
            ),
        ]
    }
}
