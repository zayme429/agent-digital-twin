#!/usr/bin/env python3
"""
AgentDigitalTwin — Backend Configuration Server
Run:  python3 server.py
Open: http://localhost:8765
"""

import json
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

PORT = 8765
CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")

# ── Default config ──────────────────────────────────────────────────────────

DEFAULT_CONFIG = {
    "llm": {
        "provider": "anthropic",
        "model": "claude-sonnet-4-6",
        "api_key": "",
        "base_url": "https://api.anthropic.com",
        "temperature": 0.7,
        "max_tokens": 2048
    },
    "persona": {
        "name": "林晓薇",
        "tone": "professional",
        "bio": "10年寿险顾问 | 专注家庭财富保障规划",
        "brand_keywords": "保险规划,家庭保障,专业顾问"
    },
    "content": {
        "auto_generate": True,
        "review_before_post": True,
        "moments_daily": 1,
        "xhs_daily": 1,
        "oa_weekly": 1
    },
    "schedule": [
        {
            "platform": "朋友圈", "time": "08:45", "title": "早安问候", "enabled": True,
            "card_summary": "专业顾问风格｜「早安。好的保障不是等风险来了才想起，而是在平静日常里把底盘打稳。」+问候贴图",
            "post_content": "早安。好的保障不是等风险来了才想起，而是在平静日常里把底盘打稳。愿你今天忙而不乱，稳而有底。",
            "media_desc": "一张职场问候帖", "style_note": "专业顾问风格，温暖不说教"
        },
        {
            "platform": "微信私聊", "time": "09:00", "title": "跟进：张总重疾险签约", "enabled": True,
            "card_summary": "每30分钟查询核保进度，17:00核保完成：肝癌除外承保。已生成安抚话术待发送",
            "post_content": "张总，核保结果出来了：可以正常承保，肝癌项做除外责任。其余重疾保障不受影响，确认后我发您签约链接。",
            "media_desc": "", "style_note": "专业简洁，安抚情绪，推动签约"
        },
        {
            "platform": "小红书", "time": "09:10", "title": "热点切入｜黄金波动", "enabled": True,
            "card_summary": "美以冲突升级→黄金/美元波动→年金险确定性规划科普。热点卡视觉，不硬推。",
            "post_content": "美以冲突升级 → 黄金/美元剧烈波动。市场越动荡，年金险的「确定性」越珍贵。今天聊聊怎么用年金险对冲不确定性。",
            "media_desc": "极简对比信息图：黄金波动 vs 年金确定性", "style_note": "热点切入，不硬推，科普为主"
        },
        {
            "platform": "客户经营", "time": "09:30", "title": "客户互动经营（10人）", "enabled": True,
            "card_summary": "老客维系 4｜潜力跟进 3｜生日/纪念日 2｜沉默唤醒 1，个性化私信触达",
            "post_content": "老客维系：体检权益到期提醒；潜力跟进：开门红年金险邀约；生日触达：专属问候卡；沉默唤醒：新年关怀祝福。",
            "media_desc": "", "style_note": "个性化，不群发，自然触达"
        },
        {
            "platform": "客户经营", "time": "10:20", "title": "高潜面谈邀约（10人）", "enabled": True,
            "card_summary": "推荐邀约窗口：下周五 14-17点｜周六 10-12点。附话术+预判异议，支持批量发送",
            "post_content": "推荐邀约窗口：下周五 14–17点｜周六 10–12点。附话术+预判异议，支持批量发送。",
            "media_desc": "", "style_note": "简洁利落，给明确选择"
        },
        {
            "platform": "面谈", "time": "15:00", "title": "面谈：王姐 @ 星巴克", "enabled": True,
            "card_summary": "家庭健康保障规划（重疾险为主）｜40分钟｜目标：当场确定预算与保障优先级",
            "post_content": "家庭健康保障规划（重疾险为主）｜40分钟｜目标：当场确定预算与保障优先级。已备3套方案+《重疾险3分钟看懂卡》。",
            "media_desc": "", "style_note": "用生活化表达，避免专业术语"
        },
    ]
}

# ── Config helpers ───────────────────────────────────────────────────────────

def load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return DEFAULT_CONFIG

def save_config(cfg):
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)

# ── HTML page ────────────────────────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AgentDigitalTwin · 后台配置</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  :root {
    --bg:      #F2F2F7;
    --card:    #FFFFFF;
    --accent:  #007AFF;
    --danger:  #FF3B30;
    --green:   #34C759;
    --label:   #1C1C1E;
    --sub:     #6C6C70;
    --border:  #E5E5EA;
    --input-bg:#F9F9FB;
    --radius:  12px;
    --shadow:  0 2px 12px rgba(0,0,0,.07);
  }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
    background: var(--bg);
    color: var(--label);
    min-height: 100vh;
  }

  /* ── Top bar ── */
  header {
    background: rgba(255,255,255,.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border-bottom: 1px solid var(--border);
    padding: 0 24px;
    height: 56px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: sticky;
    top: 0;
    z-index: 100;
  }
  .brand {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 17px;
    font-weight: 700;
    color: var(--label);
  }
  .brand-dot {
    width: 10px; height: 10px;
    background: var(--accent);
    border-radius: 50%;
  }
  .save-btn {
    background: var(--accent);
    color: #fff;
    border: none;
    border-radius: 20px;
    padding: 8px 20px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: opacity .15s;
  }
  .save-btn:hover { opacity: .85; }
  .save-btn:active { opacity: .7; }

  /* ── Toast ── */
  #toast {
    position: fixed;
    bottom: 32px;
    left: 50%;
    transform: translateX(-50%) translateY(20px);
    background: #1C1C1E;
    color: #fff;
    padding: 10px 20px;
    border-radius: 20px;
    font-size: 14px;
    font-weight: 500;
    opacity: 0;
    transition: opacity .25s, transform .25s;
    pointer-events: none;
    z-index: 999;
  }
  #toast.show { opacity: 1; transform: translateX(-50%) translateY(0); }

  /* ── Layout ── */
  .layout { display: flex; min-height: calc(100vh - 56px); }

  /* ── Sidebar tabs ── */
  nav {
    width: 200px;
    flex-shrink: 0;
    padding: 20px 12px;
    border-right: 1px solid var(--border);
    background: rgba(255,255,255,.6);
  }
  nav .tab {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 14px;
    border-radius: 10px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    color: var(--sub);
    transition: background .15s, color .15s;
    margin-bottom: 2px;
  }
  nav .tab.active {
    background: var(--accent);
    color: #fff;
  }
  nav .tab:not(.active):hover {
    background: rgba(0,0,0,.05);
    color: var(--label);
  }
  nav .tab-icon { font-size: 16px; width: 20px; text-align: center; }

  /* ── Content panes ── */
  main { flex: 1; padding: 28px 32px; max-width: 780px; }
  .pane { display: none; }
  .pane.active { display: block; }

  /* ── Section ── */
  .section-title {
    font-size: 12px;
    font-weight: 600;
    color: var(--sub);
    text-transform: uppercase;
    letter-spacing: .6px;
    margin-bottom: 10px;
    margin-top: 28px;
  }
  .section-title:first-child { margin-top: 0; }

  /* ── Card ── */
  .card {
    background: var(--card);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    overflow: hidden;
  }

  /* ── Field row ── */
  .field {
    display: flex;
    align-items: center;
    padding: 13px 16px;
    border-bottom: 1px solid var(--border);
    gap: 12px;
  }
  .field:last-child { border-bottom: none; }
  .field-label {
    font-size: 14px;
    font-weight: 500;
    color: var(--label);
    width: 130px;
    flex-shrink: 0;
  }
  .field-sub {
    font-size: 12px;
    color: var(--sub);
    margin-top: 2px;
  }
  .field-label-wrap { flex: 0 0 130px; }
  input[type="text"], input[type="password"], input[type="number"],
  select, textarea {
    flex: 1;
    background: var(--input-bg);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 8px 11px;
    font-size: 14px;
    color: var(--label);
    font-family: inherit;
    outline: none;
    transition: border-color .15s;
  }
  input:focus, select:focus, textarea:focus {
    border-color: var(--accent);
  }
  textarea { resize: vertical; min-height: 72px; }
  input[type="range"] {
    flex: 1;
    accent-color: var(--accent);
  }
  .range-val {
    font-size: 13px;
    font-weight: 600;
    color: var(--accent);
    width: 34px;
    text-align: right;
  }

  /* ── Toggle ── */
  .toggle-wrap { margin-left: auto; }
  .toggle {
    position: relative;
    width: 48px;
    height: 28px;
    flex-shrink: 0;
  }
  .toggle input { opacity: 0; width: 0; height: 0; }
  .slider {
    position: absolute;
    inset: 0;
    background: #E5E5EA;
    border-radius: 28px;
    cursor: pointer;
    transition: background .2s;
  }
  .slider::before {
    content: "";
    position: absolute;
    width: 22px; height: 22px;
    left: 3px; top: 3px;
    background: white;
    border-radius: 50%;
    box-shadow: 0 1px 4px rgba(0,0,0,.2);
    transition: transform .2s;
  }
  input:checked + .slider { background: var(--green); }
  input:checked + .slider::before { transform: translateX(20px); }

  /* ── Schedule cards ── */
  .sched-item {
    border-bottom: 1px solid var(--border);
  }
  .sched-item:last-child { border-bottom: none; }

  /* Top meta row: time / platform / title / toggle / delete */
  .sched-meta {
    display: grid;
    grid-template-columns: 76px 100px 1fr auto auto;
    gap: 8px;
    align-items: center;
    padding: 10px 14px 8px;
  }
  .sched-meta input[type="time"],
  .sched-meta input[type="text"],
  .sched-meta select {
    width: 100%;
    padding: 6px 9px;
    font-size: 13px;
  }

  /* Content area — always visible */
  .sched-content {
    padding: 0 14px 14px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .sched-field-label {
    font-size: 11px;
    font-weight: 600;
    color: var(--sub);
    text-transform: uppercase;
    letter-spacing: .4px;
    margin-bottom: 5px;
  }
  .sched-content textarea,
  .sched-content input[type="text"] {
    width: 100%;
    padding: 8px 11px;
    font-size: 13px;
    line-height: 1.55;
  }
  .sched-content textarea { resize: vertical; }
  .sched-post  { min-height: 90px; }
  .sched-summary { min-height: 52px; }

  /* Advanced toggle link */
  .adv-toggle {
    font-size: 12px;
    color: var(--sub);
    cursor: pointer;
    user-select: none;
    display: inline-flex;
    align-items: center;
    gap: 4px;
  }
  .adv-toggle:hover { color: var(--accent); }
  .adv-section { display: none; gap: 10px; flex-direction: column; }
  .adv-section.open { display: flex; }

  .add-row-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 500;
    color: var(--accent);
    cursor: pointer;
    border: none;
    background: none;
    width: 100%;
    text-align: left;
  }
  .add-row-btn:hover { background: rgba(0,122,255,.04); }

  .del-btn {
    background: none;
    border: none;
    color: var(--danger);
    cursor: pointer;
    font-size: 18px;
    line-height: 1;
    padding: 4px;
    border-radius: 6px;
    transition: background .15s;
  }
  .del-btn:hover { background: rgba(255,59,48,.08); }

  /* ── Platform badge colors ── */
  .p-moments  { background:#E6F9EF; color:#07C260; }
  .p-xhs      { background:#FFE8EC; color:#FF2442; }
  .p-oa       { background:#EEF1F9; color:#7B8CB6; }
  .p-private  { background:#E0F5FD; color:#00B0F0; }
  .p-client   { background:#FFF3E6; color:#FF8010; }
  .p-meeting  { background:#F2E8FF; color:#8530D1; }

  /* ── Status badge ── */
  .status-dot {
    display: inline-block;
    width: 8px; height: 8px;
    border-radius: 50%;
    background: var(--green);
    margin-right: 6px;
  }
  .hint {
    font-size: 12px;
    color: var(--sub);
    padding: 12px 16px;
    border-top: 1px solid var(--border);
    background: var(--bg);
    border-radius: 0 0 var(--radius) var(--radius);
  }
</style>
</head>
<body>

<header>
  <div class="brand">
    <div class="brand-dot"></div>
    AgentDigitalTwin · 后台配置
  </div>
  <button class="save-btn" onclick="saveAll()">保存配置</button>
</header>

<div class="layout">
  <nav>
    <div class="tab active" onclick="switchTab('llm', this)">
      <span class="tab-icon">🤖</span>大模型配置
    </div>
    <div class="tab" onclick="switchTab('persona', this)">
      <span class="tab-icon">👤</span>人设设置
    </div>
    <div class="tab" onclick="switchTab('content', this)">
      <span class="tab-icon">✍️</span>内容配置
    </div>
    <div class="tab" onclick="switchTab('schedule', this)">
      <span class="tab-icon">📅</span>发布计划
    </div>
  </nav>

  <main>

    <!-- ── 大模型配置 ── -->
    <div id="pane-llm" class="pane active">
      <p class="section-title">接入配置</p>
      <div class="card">
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">服务商</div>
          </div>
          <select id="llm_provider">
            <option value="anthropic">Anthropic (Claude)</option>
            <option value="openai">OpenAI (GPT)</option>
            <option value="zhipu">智谱 AI (GLM)</option>
            <option value="qwen">阿里云 (Qwen)</option>
            <option value="custom">自定义</option>
          </select>
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">模型</div>
          </div>
          <input type="text" id="llm_model" placeholder="claude-sonnet-4-6">
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">API Key</div>
            <div class="field-sub">不会明文存储在前端</div>
          </div>
          <input type="password" id="llm_api_key" placeholder="sk-ant-...">
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">Base URL</div>
          </div>
          <input type="text" id="llm_base_url" placeholder="https://api.anthropic.com">
        </div>
      </div>

      <p class="section-title">生成参数</p>
      <div class="card">
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">Temperature</div>
            <div class="field-sub">创意度（0 保守 → 1 发散）</div>
          </div>
          <input type="range" id="llm_temperature" min="0" max="1" step="0.05"
                 oninput="document.getElementById('temp_val').textContent=this.value">
          <span class="range-val" id="temp_val">0.7</span>
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">Max Tokens</div>
          </div>
          <input type="number" id="llm_max_tokens" min="256" max="8192" step="256">
        </div>
      </div>
    </div>

    <!-- ── 人设设置 ── -->
    <div id="pane-persona" class="pane">
      <p class="section-title">基础信息</p>
      <div class="card">
        <div class="field">
          <div class="field-label">人设名称</div>
          <input type="text" id="persona_name" placeholder="林晓薇">
        </div>
        <div class="field">
          <div class="field-label">风格基调</div>
          <select id="persona_tone">
            <option value="professional">专业顾问</option>
            <option value="friendly">生活达人</option>
            <option value="creative">创意博主</option>
            <option value="concise">知识领袖</option>
          </select>
        </div>
        <div class="field" style="align-items:flex-start">
          <div class="field-label" style="padding-top:4px">人设简介</div>
          <textarea id="persona_bio" rows="3" placeholder="10年寿险顾问 | 专注家庭财富保障规划"></textarea>
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">品牌关键词</div>
            <div class="field-sub">逗号分隔</div>
          </div>
          <input type="text" id="persona_brand_keywords" placeholder="保险规划,家庭保障,专业顾问">
        </div>
      </div>
    </div>

    <!-- ── 内容配置 ── -->
    <div id="pane-content" class="pane">
      <p class="section-title">自动化设置</p>
      <div class="card">
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">自动生成内容</div>
            <div class="field-sub">到时间自动由模型生成文案</div>
          </div>
          <div class="toggle-wrap">
            <label class="toggle">
              <input type="checkbox" id="content_auto_generate">
              <span class="slider"></span>
            </label>
          </div>
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">发前人工确认</div>
            <div class="field-sub">生成后弹出确认卡片</div>
          </div>
          <div class="toggle-wrap">
            <label class="toggle">
              <input type="checkbox" id="content_review_before_post">
              <span class="slider"></span>
            </label>
          </div>
        </div>
      </div>

      <p class="section-title">发布频率</p>
      <div class="card">
        <div class="field">
          <div class="field-label">朋友圈 / 天</div>
          <input type="number" id="content_moments_daily" min="0" max="10" style="max-width:100px">
        </div>
        <div class="field">
          <div class="field-label">小红书 / 天</div>
          <input type="number" id="content_xhs_daily" min="0" max="10" style="max-width:100px">
        </div>
        <div class="field">
          <div class="field-label">公众号 / 周</div>
          <input type="number" id="content_oa_weekly" min="0" max="10" style="max-width:100px">
        </div>
      </div>
    </div>

    <!-- ── 发布计划 ── -->
    <div id="pane-schedule" class="pane">
      <p class="section-title">今日任务列表</p>
      <div class="card">
        <div id="schedule-body"></div>
        <button class="add-row-btn" onclick="addScheduleRow()">＋ 添加任务</button>
      </div>
      <div class="hint">修改「发布内容」和「卡片摘要」后点击右上角保存，App 下次启动时自动读取新计划。</div>
    </div>

  </main>
</div>

<div id="toast">✓ 配置已保存</div>

<script>
// ── Platform options ──────────────────────────────────────────────────────
const PLATFORMS = ["朋友圈","微信私聊","小红书","公众号","客户经营","面谈"];
const P_CLASS = {
  "朋友圈":"p-moments","小红书":"p-xhs","公众号":"p-oa",
  "微信私聊":"p-private","客户经营":"p-client","面谈":"p-meeting"
};

// ── Tab switching ─────────────────────────────────────────────────────────
function switchTab(id, el) {
  document.querySelectorAll('.pane').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById('pane-' + id).classList.add('active');
  el.classList.add('active');
}

// ── Load config from server ───────────────────────────────────────────────
async function loadConfig() {
  const res = await fetch('/api/config');
  const cfg = await res.json();

  // LLM
  document.getElementById('llm_provider').value   = cfg.llm.provider   || 'anthropic';
  document.getElementById('llm_model').value       = cfg.llm.model      || '';
  document.getElementById('llm_api_key').value     = cfg.llm.api_key    || '';
  document.getElementById('llm_base_url').value    = cfg.llm.base_url   || '';
  const temp = cfg.llm.temperature ?? 0.7;
  document.getElementById('llm_temperature').value = temp;
  document.getElementById('temp_val').textContent  = temp;
  document.getElementById('llm_max_tokens').value  = cfg.llm.max_tokens || 2048;

  // Persona
  document.getElementById('persona_name').value           = cfg.persona.name           || '';
  document.getElementById('persona_tone').value           = cfg.persona.tone           || 'professional';
  document.getElementById('persona_bio').value            = cfg.persona.bio            || '';
  document.getElementById('persona_brand_keywords').value = cfg.persona.brand_keywords || '';

  // Content
  document.getElementById('content_auto_generate').checked    = cfg.content.auto_generate    ?? true;
  document.getElementById('content_review_before_post').checked = cfg.content.review_before_post ?? true;
  document.getElementById('content_moments_daily').value = cfg.content.moments_daily ?? 1;
  document.getElementById('content_xhs_daily').value     = cfg.content.xhs_daily     ?? 1;
  document.getElementById('content_oa_weekly').value     = cfg.content.oa_weekly     ?? 1;

  // Schedule
  renderSchedule(cfg.schedule || []);
}

// ── Schedule ──────────────────────────────────────────────────────────────
function renderSchedule(rows) {
  const body = document.getElementById('schedule-body');
  body.innerHTML = '';
  rows.forEach((row, i) => body.appendChild(makeSchedItem(row, i)));
}

function makeSchedItem(row, i) {
  const wrap = document.createElement('div');
  wrap.className = 'sched-item';

  // ── Meta row: time / platform / title / toggle / delete ──
  const metaDiv = document.createElement('div');
  metaDiv.className = 'sched-meta';

  const timeInput = document.createElement('input');
  timeInput.type = 'time';
  timeInput.value = row.time || '09:00';
  timeInput.dataset.key = 'time';

  const platSel = document.createElement('select');
  platSel.dataset.key = 'platform';
  PLATFORMS.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p; opt.textContent = p;
    if (p === row.platform) opt.selected = true;
    platSel.appendChild(opt);
  });

  const titleInput = document.createElement('input');
  titleInput.type = 'text';
  titleInput.value = row.title || '';
  titleInput.placeholder = '任务名称';
  titleInput.dataset.key = 'title';

  const label = document.createElement('label');
  label.className = 'toggle';
  label.style.cssText = 'width:40px;height:24px;flex-shrink:0;';
  const cb = document.createElement('input');
  cb.type = 'checkbox';
  cb.checked = row.enabled !== false;
  cb.dataset.key = 'enabled';
  const sliderSpan = document.createElement('span');
  sliderSpan.className = 'slider';
  label.appendChild(cb); label.appendChild(sliderSpan);

  const delBtn = document.createElement('button');
  delBtn.className = 'del-btn';
  delBtn.innerHTML = '×';
  delBtn.onclick = () => wrap.remove();

  metaDiv.appendChild(timeInput);
  metaDiv.appendChild(platSel);
  metaDiv.appendChild(titleInput);
  metaDiv.appendChild(label);
  metaDiv.appendChild(delBtn);

  // ── Content area — always visible ──
  const contentDiv = document.createElement('div');
  contentDiv.className = 'sched-content';

  function makeBlock(labelText, key, isTextarea, placeholder, value, extraClass) {
    const block = document.createElement('div');
    const lbl = document.createElement('div');
    lbl.className = 'sched-field-label';
    lbl.textContent = labelText;
    const el = document.createElement(isTextarea ? 'textarea' : 'input');
    if (!isTextarea) el.type = 'text';
    el.placeholder = placeholder;
    el.value = value || '';
    el.dataset.key = key;
    if (extraClass) el.classList.add(extraClass);
    block.appendChild(lbl);
    block.appendChild(el);
    return block;
  }

  // Primary: 发布内容 (the text that gets sent to the platform)
  contentDiv.appendChild(makeBlock(
    '发布内容 — App 中「确认执行」时展示的完整内容',
    'post_content', true,
    '输入实际要发布的文字内容…',
    row.post_content || '', 'sched-post'
  ));

  // Secondary: 卡片摘要 (short description shown on the schedule card in the iOS app)
  contentDiv.appendChild(makeBlock(
    '卡片摘要 — iOS 任务卡片上显示的一句话描述',
    'card_summary', true,
    '简短描述这条任务的内容要点…',
    row.card_summary || '', 'sched-summary'
  ));

  // Advanced toggle
  const advToggle = document.createElement('span');
  advToggle.className = 'adv-toggle';
  advToggle.innerHTML = '▸ 配图 / 风格备注';

  const advSection = document.createElement('div');
  advSection.className = 'adv-section';
  advSection.appendChild(makeBlock(
    '配图 / 附件说明',
    'media_desc', false,
    '例如：一张职场问候帖、对比信息图…',
    row.media_desc || '', ''
  ));
  advSection.appendChild(makeBlock(
    '风格备注',
    'style_note', false,
    '例如：专业简洁，避免术语…',
    row.style_note || '', ''
  ));

  advToggle.onclick = () => {
    const open = advSection.classList.toggle('open');
    advToggle.innerHTML = (open ? '▾ ' : '▸ ') + '配图 / 风格备注';
  };

  contentDiv.appendChild(advToggle);
  contentDiv.appendChild(advSection);

  wrap.appendChild(metaDiv);
  wrap.appendChild(contentDiv);
  return wrap;
}

function addScheduleRow() {
  const body = document.getElementById('schedule-body');
  body.appendChild(makeSchedItem(
    {platform:'朋友圈',time:'10:00',title:'',enabled:true,
     card_summary:'',post_content:'',media_desc:'',style_note:''},
    body.children.length
  ));
}

function collectSchedule() {
  const rows = [];
  document.querySelectorAll('.sched-item').forEach(item => {
    const get = key => {
      const el = item.querySelector(`[data-key="${key}"]`);
      return el ? (el.type === 'checkbox' ? el.checked : el.value) : '';
    };
    rows.push({
      time:         get('time'),
      platform:     get('platform'),
      title:        get('title'),
      enabled:      get('enabled'),
      card_summary: get('card_summary'),
      post_content: get('post_content'),
      media_desc:   get('media_desc'),
      style_note:   get('style_note'),
    });
  });
  rows.sort((a, b) => a.time.localeCompare(b.time));
  return rows;
}

// ── Save ──────────────────────────────────────────────────────────────────
async function saveAll() {
  const cfg = {
    llm: {
      provider:    document.getElementById('llm_provider').value,
      model:       document.getElementById('llm_model').value,
      api_key:     document.getElementById('llm_api_key').value,
      base_url:    document.getElementById('llm_base_url').value,
      temperature: parseFloat(document.getElementById('llm_temperature').value),
      max_tokens:  parseInt(document.getElementById('llm_max_tokens').value),
    },
    persona: {
      name:           document.getElementById('persona_name').value,
      tone:           document.getElementById('persona_tone').value,
      bio:            document.getElementById('persona_bio').value,
      brand_keywords: document.getElementById('persona_brand_keywords').value,
    },
    content: {
      auto_generate:     document.getElementById('content_auto_generate').checked,
      review_before_post:document.getElementById('content_review_before_post').checked,
      moments_daily:     parseInt(document.getElementById('content_moments_daily').value),
      xhs_daily:         parseInt(document.getElementById('content_xhs_daily').value),
      oa_weekly:         parseInt(document.getElementById('content_oa_weekly').value),
    },
    schedule: collectSchedule(),
  };

  const res = await fetch('/api/config', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cfg),
  });

  if (res.ok) {
    const toast = document.getElementById('toast');
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2200);
  }
}

// ── Boot ──────────────────────────────────────────────────────────────────
loadConfig();
</script>
</body>
</html>
"""

# ── HTTP handler ─────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        print(f"  {self.address_string()} {fmt % args}")

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, html):
        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            self.send_html(HTML)
        elif path == "/api/config":
            self.send_json(load_config())
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        path = urlparse(self.path).path
        if path == "/api/config":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                cfg = json.loads(body)
                save_config(cfg)
                self.send_json({"ok": True})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, status=400)
        else:
            self.send_response(404)
            self.end_headers()


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"\n  AgentDigitalTwin 后台配置服务已启动")
    print(f"  访问地址：http://localhost:{PORT}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  已停止。")
        sys.exit(0)
