import Foundation
import SwiftUI

class ScheduleManager: ObservableObject {
    @Published var cards:    [ScheduleCard]  = []
    @Published var timeline: [TimelineItem]  = []

    private var sessionDate:       Date       = Calendar.current.startOfDay(for: Date())
    private var announcedCardIDs:  Set<UUID>  = []
    private var timer:             Timer?

    init() {
        initializeDay()
        loadFromBackend()   // Try to refresh cards from backend config
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkDayRollover()
            self?.checkForDueCards()
        }
    }

    // MARK: - Backend sync

    private func loadFromBackend() {
        guard let url = URL(string: "http://localhost:8765/api/config") else { return }
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            guard error == nil, let data else { return }
            guard
                let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let schedule = json["schedule"] as? [[String: Any]]
            else { return }
            let loaded = schedule.compactMap { ScheduleCard.fromConfig($0) }
                                 .sorted { $0.scheduledTime < $1.scheduledTime }
            guard !loaded.isEmpty else { return }
            DispatchQueue.main.async {
                // Preserve any already-posted state by matching titles + times
                let postedIDs = Set(self.cards.filter(\.isPosted).map { "\($0.platform.rawValue)|\($0.title)" })
                self.cards = loaded.map { card in
                    let key = "\(card.platform.rawValue)|\(card.title)"
                    return postedIDs.contains(key)
                        ? ScheduleCard(id: card.id, platform: card.platform, title: card.title,
                                       content: card.content, scheduledTime: card.scheduledTime, isPosted: true)
                        : card
                }
            }
        }.resume()
    }

    // MARK: - Day session

    private func initializeDay() {
        cards             = ScheduleCard.todayCards()
        announcedCardIDs  = []
        sessionDate       = Calendar.current.startOfDay(for: Date())
        timeline          = []

        appendAgent(morningGreeting())
        timeline.append(.overviewCard(id: UUID(), time: Date()))
        checkForDueCards()
    }

    private func morningGreeting() -> String {
        let hour  = Calendar.current.component(.hour, from: Date())
        let greet = hour < 12 ? "早上好" : hour < 18 ? "下午好" : "晚上好"
        let f     = DateFormatter()
        f.locale      = Locale(identifier: "zh_CN")
        f.dateFormat  = "M月d日 EEEE"
        let count = ScheduleCard.todayCards().count
        return "\(greet)！今天是 \(f.string(from: Date()))，共安排了 \(count) 条内容发布计划。到达时间点我会自动提醒你确认执行。"
    }

    private func checkDayRollover() {
        let today = Calendar.current.startOfDay(for: Date())
        guard today > sessionDate else { return }
        withAnimation { initializeDay() }
    }

    func checkForDueCards() {
        let now = Date()
        for card in cards.sorted(by: { $0.scheduledTime < $1.scheduledTime }) where !card.isPosted && !announcedCardIDs.contains(card.id) {
            guard card.scheduledTime <= now else { continue }
            announcedCardIDs.insert(card.id)
            // Notification time = the card's scheduled time (not now)
            appendAgent("📬 \(card.platform.rawValue) 发布时间到了！请确认是否执行「\(card.title)」。",
                        at: card.scheduledTime)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                timeline.append(.pendingAction(id: UUID(), card: card))
            }
        }
        objectWillChange.send()
    }

    // MARK: - Actions

    func execute(_ card: ScheduleCard) {
        guard let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            cards[idx].isPosted = true
        }
        let updated = cards[idx]
        if let tIdx = timeline.firstIndex(where: {
            if case .pendingAction(_, let c) = $0 { return c.id == card.id }
            return false
        }) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                timeline[tIdx] = .completedAction(id: UUID(), card: updated)
            }
        }
        appendAgent("✅ 「\(card.title)」已成功发布至 \(card.platform.rawValue)！")
    }

    func queueManual(platform: Platform) {
        let titles: [Platform: String] = [
            .wechatMoments: "朋友圈动态",
            .xiaohongshu:   "小红书推送",
            .wechatOA:      "公众号推文",
            .wechatPrivate: "微信互动卡片",
        ]
        let card = ScheduleCard(
            platform:        platform,
            title:           titles[platform] ?? "手动发布",
            content:         "代理人将根据「当前人设」自动生成并发布内容",
            scheduledTime:   Date(),
            isManualTrigger: true
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            cards.insert(card, at: 0)
            announcedCardIDs.insert(card.id)
            timeline.append(.pendingAction(id: UUID(), card: card))
        }
    }

    // MARK: - Timeline helpers

    func appendAgent(_ text: String, at time: Date = Date()) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            timeline.append(.agentText(id: UUID(), text: text, time: time))
        }
    }

    func appendUser(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            timeline.append(.userText(id: UUID(), text: text, time: Date()))
        }
    }

    // MARK: - Computed

    var pendingCards: [ScheduleCard] {
        cards.filter { !$0.isPosted }.sorted {
            let aDue = $0.scheduledTime <= Date()
            let bDue = $1.scheduledTime <= Date()
            if aDue != bDue { return aDue }
            return $0.scheduledTime < $1.scheduledTime
        }
    }

    var completedCards: [ScheduleCard] {
        cards.filter { $0.isPosted }.sorted { $0.scheduledTime > $1.scheduledTime }
    }

    var timelineCards: [ScheduleCard] {
        cards.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    deinit { timer?.invalidate() }
}
