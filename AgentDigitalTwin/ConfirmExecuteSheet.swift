import SwiftUI

struct ConfirmExecuteSheet: View {
    let card: ScheduleCard
    let persona: AgentPersona
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var accent: Color { Color(red: 0.330, green: 0.180, blue: 0.780) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.85, green: 0.84, blue: 0.88))
                        .frame(width: 38, height: 5)
                        .padding(.top, 14)
                        .padding(.bottom, 22)

                    // Platform icon
                    ZStack {
                        Circle()
                            .fill(card.platform.primaryColor.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(card.platform.primaryColor)
                    }
                    .padding(.bottom, 14)

                    // Title
                    Text("确认执行任务")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.12, green: 0.10, blue: 0.18))
                        .padding(.bottom, 8)

                    // Task badge
                    HStack(spacing: 6) {
                        Image(systemName: card.platform.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(card.platform.rawValue) · \(card.title)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(card.platform.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(card.platform.primaryColor.opacity(0.10))
                    )
                    .padding(.bottom, 20)

                    // Recommended content block
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(accent)
                            Text("推荐发布内容")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(accent)
                        }

                        Text(recommendedContent(platform: card.platform, persona: persona))
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.35))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accent.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Auto-steps
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
                            Text("代理人将全自动执行以下步骤")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            AutoStepRow(icon: "wand.and.stars.inverse",
                                        text: "以「\(persona.name)」人设自动生成\(card.platform.rawValue)内容")
                            AutoStepRow(icon: "checkmark.shield.fill",
                                        text: "自动完成内容审核与风格优化")
                            AutoStepRow(icon: card.platform.icon,
                                        text: "发布至 \(card.platform.rawValue)")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.96, green: 0.958, blue: 0.972))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // Confirm button
                    Button(action: onConfirm) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("确认执行")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accent)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Cancel
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
                    }
                    .padding(.bottom, 40)
                }
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .ignoresSafeArea()
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Content templates

private func recommendedContent(platform: Platform, persona: AgentPersona) -> String {
    switch (platform, persona.tone) {
    case (.wechatMoments, .professional):
        return "风格：专业顾问\n「早安。好的保障不是「等风险来了才想起」，而是在平静日常里把底盘打稳。愿你今天忙而不乱，稳而有底。」\n+ 一张职场问候帖"
    case (.wechatMoments, .friendly):
        return "风格：生活达人\n「早安呀～今天也是元气满满的一天！记得喝水、好好吃饭，把自己照顾好，才有能量照顾身边的人。」\n+ 一张温馨早安图"
    case (.wechatMoments, .creative):
        return "风格：创意博主\n「用一杯咖啡的时间思考：你有没有一个计划，在五年后还在保护现在的你？」\n+ 一张创意排版问候卡"
    case (.wechatMoments, .concise):
        return "风格：知识领袖\n「早安。复利的本质，不只是财富，也是健康与关系。今天的小积累，都在为未来铺路。」\n+ 一张简约知识卡"

    case (.xiaohongshu, .professional):
        return "风格：专业顾问\n「保险规划的 3 个误区，很多人第一条就踩了｜干货分享」\n正文：误区一：保额越高越好；误区二…\n+ 3 张图文卡片"
    case (.xiaohongshu, .friendly):
        return "风格：生活达人\n「闺蜜问我：买保险真的有用吗？我用亲身经历告诉她…」\n+ 暖色系 Vlog 封面图"
    case (.xiaohongshu, .creative):
        return "风格：创意博主\n「如果人生是一款游戏，你给自己加了什么「护甲」？｜创意测评」\n+ 游戏风格封面设计"
    case (.xiaohongshu, .concise):
        return "风格：知识领袖\n「一张图读懂：重疾险 vs 医疗险，到底差在哪？」\n+ 极简对比信息图"

    case (.wechatOA, .professional):
        return "风格：专业顾问\n标题：《2025 年家庭财务规划白皮书：保障篇》\n导语：在不确定的时代，专业规划是最稳定的护城河…\n+ 深度长图文"
    case (.wechatOA, .friendly):
        return "风格：生活达人\n标题：《那一年，一张保单改变了我们家的走向》\n导语：真实故事，温暖分享。不是在卖保险，是在讲人…\n+ 暖色故事封面"
    case (.wechatOA, .creative):
        return "风格：创意博主\n标题：《如果把保险设计成 RPG 游戏，你的角色卡是什么？》\n导语：用游戏思维理解保障…\n+ 创意互动封面"
    case (.wechatOA, .concise):
        return "风格：知识领袖\n标题：《3 分钟读懂：为什么聪明人都在 30 岁前做规划？》\n导语：数据说话，逻辑先行…\n+ 简洁信息图"

    case (.wechatPrivate, .professional):
        return "风格：专业顾问\n「您好，上次我们聊到您家庭规划的问题，我整理了一份针对性方案，方便今天看一下吗？」"
    case (.wechatPrivate, .friendly):
        return "风格：生活达人\n「嗨～最近还好吗？天气变化大，记得注意身体。上次提到的那个问题，我帮你查了一下～」"
    case (.wechatPrivate, .creative):
        return "风格：创意博主\n「给你发一个有趣的测试：30 秒测出你现在最需要哪种保障——结果可能会让你意外！」"
    case (.wechatPrivate, .concise):
        return "风格：知识领袖\n「附上这周最值得看的一篇文章：《为什么说保障规划是最划算的投资》，三分钟读完。」"

    case (.clientMgmt, .professional):
        return "风格：专业顾问\n【老客维系】臻享家医体检权益还有3个月到期，已发送预约提醒链接\n【潜力跟进】昨天点赞朋友圈的客户→开门红年金险活动邀约\n【生日触达】今日生日客户→专属问候卡\n【沉默唤醒】30天未互动→新年关怀祝福"
    case (.clientMgmt, .friendly):
        return "风格：生活达人\n给每位客户发一条暖心的个性化消息～\n生日的送祝福、好久不见的问问近况、有新资讯的分享一下，自然不硬推！"
    case (.clientMgmt, .creative):
        return "风格：创意博主\n用有趣的方式触达10位客户：一个测试链接、一条有料的内容、一句让人想回复的问候"
    case (.clientMgmt, .concise):
        return "风格：知识领袖\n10人分4组，精准触达：\n① 权益提醒 × 1  ② 活动邀约 × 3  ③ 生日祝福 × 2  ④ 关怀唤醒 × 4"

    case (.meeting, .professional):
        return "风格：专业顾问\n【会前 brief】王姐，36岁，乳腺囊肿+桥本氏甲状腺炎，关注重疾险\n目标：当场确定保额与预算\n已备：3套方案对比表 + 《重疾险3分钟看懂卡》"
    case (.meeting, .friendly):
        return "风格：生活达人\n见王姐前整理好思路～她最在意的是「别让一场病拖垮家里」，用真实案例说话，不要背条款！"
    case (.meeting, .creative):
        return "风格：创意博主\n会谈 brief：把「买保险」变成「给家庭打底盘」的对话，用可视化工具让她自己算出答案"
    case (.meeting, .concise):
        return "风格：知识领袖\n核心议题：重疾险保额 = 3-5年收入替代 + 房贷缓冲\n3套方案，15分钟讲清，30分钟促成决策"
    }
}

// MARK: - Step row

private struct AutoStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.55, green: 0.53, blue: 0.62))
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.35, green: 0.33, blue: 0.45))
        }
    }
}
