#!/usr/bin/env python3
"""
AgentDigitalTwin — Backend Configuration Server
Run:  python3 server.py
Open: http://localhost:8765
"""

import cgi
import glob as glob_mod
import io
import json
import mimetypes
import os
import sys
import uuid as uuid_mod
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

PORT        = 8765
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")
MEDIA_DIR   = os.path.join(BASE_DIR, "media")
BACKUP_DIR  = os.path.join(BASE_DIR, "backups")
os.makedirs(MEDIA_DIR,  exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)

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
    "personas": [
        {"id": "11111111-0000-0000-0000-000000000001", "name": "职场精英", "emoji": "👔",
         "description": "专业、严谨、高效的职场形象，适合商务场景的内容发布与互动",
         "tone": "专业严谨", "tags": ["商务", "专业", "严谨"]},
        {"id": "11111111-0000-0000-0000-000000000002", "name": "生活达人", "emoji": "✨",
         "description": "亲切温暖、充满正能量，适合生活方式内容分享和情感连接",
         "tone": "亲切温暖", "tags": ["生活", "温暖", "治愈"]},
        {"id": "11111111-0000-0000-0000-000000000003", "name": "创意博主", "emoji": "🎨",
         "description": "充满创意和个性，适合创作类内容输出和年轻受众互动",
         "tone": "创意活泼", "tags": ["创意", "个性", "潮流"]},
        {"id": "11111111-0000-0000-0000-000000000004", "name": "知识领袖", "emoji": "🔬",
         "description": "简洁有力、深度思考，适合知识分享、行业洞察与观点输出",
         "tone": "简洁高效", "tags": ["知识", "深度", "洞察"]},
    ],
    "selectedPersonaId": "11111111-0000-0000-0000-000000000001",
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
            "media_files": [], "media_desc": "一张职场问候帖", "style_note": "专业顾问风格，温暖不说教"
        },
        {
            "platform": "微信私聊", "time": "09:00", "title": "跟进：张总重疾险签约", "enabled": True,
            "card_summary": "每30分钟查询核保进度，17:00核保完成：肝癌除外承保。已生成安抚话术待发送",
            "post_content": "张总，核保结果出来了：可以正常承保，肝癌项做除外责任。其余重疾保障不受影响，确认后我发您签约链接。",
            "media_files": [], "media_desc": "", "style_note": "专业简洁，安抚情绪，推动签约"
        },
        {
            "platform": "小红书", "time": "09:10",
            "title": "《黄金大涨后大跌！历史上6次黄金暴跌，我们该如何配置财富》", "enabled": True,
            "card_summary": "黄金历史暴跌复盘→保险作为确定性底仓的配置逻辑科普。引发互动，不硬推。",
            "post_content": (
                '别再把黄金当成"稳稳的幸福"了⚠️\n'
                '我真的花了3天把近40年数据翻了个底朝天📚\n'
                '结论：黄金的"腰斩名场面"比电视剧还抓马……💥\n'
                '看完这篇，你会比90%的炒金人更清醒🧠✨\n\n'
                '🪙黄金=乱世护身符，但不是"稳赚神器"\n'
                '黄金更像是极端情况下的保值工具：\n'
                '✅ 对抗货币贬值\n✅ 风险事件爆发时有机会顶一顶\n'
                '但它也有很现实的一面👇\n\n'
                '😵黄金风险暴露：跌起来真的不讲武德\n'
                '📉 历史上出现过单日跌超12%的情况\n'
                '⚡ 波动强到很多人根本扛不住\n'
                '🧨 而且政策/利率/预期一变，行情可能说崩就崩\n\n'
                '🛡️我更想要的是"能睡得着"的确定性\n'
                '这也是为什么很多家庭会用储蓄险做底仓：\n'
                '✅ 确定性收益（按合同走）\n'
                '✅ 时间规划（孩子教育/养老/家庭备用金）\n'
                '✅ "隔离人性弱点"（不追涨杀跌、不被情绪带着跑）\n\n'
                '📌避险逻辑：保险更像"家庭理财的稳定基石"\n'
                '📜 《保险法》框架下，合同权益更刚性\n'
                '🧱 还能做到一定程度的资产隔离（更适合做家庭底盘）\n'
                '（当然：具体以产品条款与个人情况为准～）\n\n'
                '🔁复利感受一下（仅供参考）\n假设：年缴10万×10年\n'
                '到第20年现金价值大概能到 151万+📈\n'
                '重点不是"赚多快"，而是确定增长 + 可规划🗓️\n\n'
                '🧩配置思路：别押单一资产，稳才是王道\n'
                '我更认可这种"分层配置"👇\n'
                '🛡️ 60%：保险打底（家庭底盘/确定性）\n'
                '🌿 30%：稳健资产（固收/高等级债/等）\n'
                '🚀 10%：进取资产（股票/权益/高波动）\n'
                '这样不管行情怎么折腾，都不至于慌到手抖😮‍💨\n\n'
                '💬你们觉得：\n保险算不算靠谱的避险工具？\n'
                '你会把"家庭底仓"放在哪里？评论区聊聊👇✨\n\n'
                '#黄金投资 #保险避险 #资产配置 #理财干货 #家庭理财 #稳稳的安全感'
            ),
            "media_files": [], "media_desc": "黄金暴跌历史图+保险配置信息图", "style_note": "热点切入，不硬推，科普为主"
        },
        {
            "platform": "客户经营", "time": "09:30", "title": "客户互动经营（10人）", "enabled": True,
            "card_summary": "老客维系 4｜潜力跟进 3｜生日/纪念日 2｜沉默唤醒 1，个性化私信触达",
            "post_content": "老客维系：体检权益到期提醒；潜力跟进：开门红年金险邀约；生日触达：专属问候卡；沉默唤醒：新年关怀祝福。",
            "media_files": [], "media_desc": "", "style_note": "个性化，不群发，自然触达"
        },
        {
            "platform": "客户经营", "time": "10:20", "title": "高潜面谈邀约（10人）", "enabled": True,
            "card_summary": "推荐邀约窗口：下周五 14-17点｜周六 10-12点。附话术+预判异议，支持批量发送",
            "post_content": "推荐邀约窗口：下周五 14–17点｜周六 10–12点。附话术+预判异议，支持批量发送。",
            "media_files": [], "media_desc": "", "style_note": "简洁利落，给明确选择"
        },
        {
            "platform": "面谈", "time": "15:00", "title": "面谈：王姐 @ 星巴克", "enabled": True,
            "card_summary": "家庭健康保障规划（重疾险为主）｜40分钟｜目标：当场确定预算与保障优先级",
            "post_content": "家庭健康保障规划（重疾险为主）｜40分钟｜目标：当场确定预算与保障优先级。已备3套方案+《重疾险3分钟看懂卡》。",
            "media_files": [], "media_desc": "", "style_note": "用生活化表达，避免专业术语"
        },
    ]
}

# ── Config helpers ───────────────────────────────────────────────────────────

def load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        # Migrate old single-persona format to personas array
        _tone_map = {"professional": "专业严谨", "friendly": "亲切温暖",
                     "creative": "创意活泼", "concise": "简洁高效"}
        if "personas" not in cfg:
            old = cfg.get("persona", {})
            raw_tone = old.get("tone", "professional")
            cfg["personas"] = [{
                "id": "11111111-0000-0000-0000-000000000001",
                "name": old.get("name", "默认人设"),
                "emoji": "👤",
                "description": old.get("bio", ""),
                "tone": _tone_map.get(raw_tone, raw_tone),
                "tags": [k.strip() for k in old.get("brand_keywords", "").split(",") if k.strip()],
            }]
            cfg["selectedPersonaId"] = "11111111-0000-0000-0000-000000000001"
        # Migrate English tone keys to Chinese labels
        for p in cfg.get("personas", []):
            p["tone"] = _tone_map.get(p.get("tone", ""), p.get("tone", ""))
        return cfg
    return DEFAULT_CONFIG

def backup_config():
    """Copy current config.json to backups/ with a timestamp. Keep last 10."""
    if not os.path.exists(CONFIG_PATH):
        return
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(BACKUP_DIR, f"config_{ts}.json")
    with open(CONFIG_PATH, "r", encoding="utf-8") as src, \
         open(dest, "w", encoding="utf-8") as dst:
        dst.write(src.read())
    # Prune: keep only the 10 most recent backups
    backups = sorted(glob_mod.glob(os.path.join(BACKUP_DIR, "config_*.json")))
    for old in backups[:-10]:
        os.remove(old)

def save_config(cfg):
    backup_config()
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

  /* ── Image upload widget (multi-image) ── */
  .img-grid {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: flex-start;
  }
  .img-thumb {
    position: relative;
    width: 80px;
    height: 80px;
    border-radius: 8px;
    overflow: hidden;
    flex-shrink: 0;
    background: var(--bg);
    border: 1.5px solid var(--border);
  }
  .img-thumb img {
    width: 100%; height: 100%; object-fit: cover;
  }
  .img-thumb .img-del {
    position: absolute;
    top: 3px; right: 3px;
    width: 18px; height: 18px;
    background: rgba(0,0,0,.55);
    color: #fff;
    border: none;
    border-radius: 50%;
    font-size: 11px;
    line-height: 18px;
    text-align: center;
    cursor: pointer;
    padding: 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .img-add-slot {
    width: 80px;
    height: 80px;
    border-radius: 8px;
    border: 1.5px dashed var(--border);
    background: var(--bg);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: border-color .15s, background .15s;
    font-size: 22px;
    color: var(--sub);
    flex-shrink: 0;
  }
  .img-add-slot:hover { border-color: var(--accent); background: rgba(0,122,255,.04); }
  .img-add-slot span { font-size: 10px; color: var(--sub); margin-top: 2px; }
  .img-uploading { font-size: 11px; color: var(--accent); }
  .img-upload-btn {
    background: var(--accent);
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 6px 14px;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: opacity .15s;
  }
  .img-upload-btn:hover { opacity: .85; }
  .img-clear-btn {
    background: none;
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 5px 14px;
    font-size: 13px;
    color: var(--danger);
    cursor: pointer;
    transition: background .15s;
    display: none;
  }
  .img-clear-btn:hover { background: rgba(255,59,48,.07); }
  .img-clear-btn.visible { display: block; }
  .img-name {
    font-size: 11px;
    color: var(--sub);
    word-break: break-all;
  }

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

  /* ── Persona cards ── */
  .persona-card {
    padding: 14px 16px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: flex-start;
    gap: 12px;
    transition: background .15s;
  }
  .persona-card:last-child { border-bottom: none; }
  .persona-card:hover { background: rgba(0,0,0,.015); }
  .persona-card.persona-selected { background: rgba(0,122,255,.04); }
  .persona-emoji { font-size: 30px; line-height: 1; width: 42px; text-align: center; flex-shrink: 0; padding-top: 2px; }
  .persona-info { flex: 1; min-width: 0; }
  .persona-name-row { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; flex-wrap: wrap; }
  .persona-name { font-size: 15px; font-weight: 600; color: var(--label); }
  .persona-tone-badge { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 10px; color: #fff; }
  .persona-sel-badge { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 10px; background: var(--accent); color: #fff; }
  .persona-desc { font-size: 13px; color: var(--sub); margin-bottom: 6px; line-height: 1.45; }
  .persona-tags { display: flex; flex-wrap: wrap; gap: 4px; }
  .persona-tag { font-size: 11px; padding: 2px 7px; border-radius: 8px; background: var(--bg); color: var(--sub); border: 1px solid var(--border); }
  .persona-actions { display: flex; flex-direction: column; gap: 4px; flex-shrink: 0; }
  .persona-action-btn { font-size: 12px; font-weight: 500; padding: 5px 12px; border-radius: 8px; border: none; cursor: pointer; transition: background .15s, opacity .15s; white-space: nowrap; }
  .persona-select-btn { background: var(--accent); color: #fff; }
  .persona-select-btn:hover { opacity: .85; }
  .persona-select-btn.active { background: var(--green); cursor: default; }
  .persona-edit-btn { background: var(--input-bg); color: var(--label); border: 1px solid var(--border); }
  .persona-edit-btn:hover { background: var(--border); }
  .persona-del-btn { background: none; color: var(--danger); border: 1px solid rgba(255,59,48,.3); }
  .persona-del-btn:hover { background: rgba(255,59,48,.07); }
  /* Persona inline form */
  .persona-form { padding: 16px; border-bottom: 1px solid var(--border); background: rgba(0,122,255,.02); display: flex; flex-direction: column; gap: 10px; }
  .persona-form:last-child { border-bottom: none; }
  .persona-form-row { display: flex; gap: 8px; align-items: center; }
  .persona-form-label { font-size: 12px; font-weight: 600; color: var(--sub); text-transform: uppercase; letter-spacing: .4px; width: 52px; flex-shrink: 0; }
  .persona-form input[type="text"], .persona-form textarea, .persona-form select { flex: 1; font-size: 13px; padding: 7px 10px; }
  .emoji-input { width: 60px !important; flex: 0 0 60px !important; text-align: center; font-size: 20px; }
  .persona-form-btns { display: flex; gap: 8px; justify-content: flex-end; }
  .persona-form-save { background: var(--accent); color: #fff; border: none; border-radius: 8px; padding: 7px 18px; font-size: 13px; font-weight: 600; cursor: pointer; }
  .persona-form-save:hover { opacity: .85; }
  .persona-form-cancel { background: none; color: var(--sub); border: 1px solid var(--border); border-radius: 8px; padding: 7px 18px; font-size: 13px; cursor: pointer; }
  .persona-form-cancel:hover { background: var(--bg); }

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
    <div class="tab" onclick="switchTab('openclaw', this)">
      <span class="tab-icon">🔌</span>OpenClaw
    </div>
    <div class="tab" onclick="switchTab('backups', this); loadBackups()">
      <span class="tab-icon">🗂</span>备份恢复
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
      <p class="section-title">人设列表</p>
      <div class="card">
        <div id="persona-list"></div>
        <button class="add-row-btn" onclick="addPersona()">＋ 添加人设</button>
      </div>
      <div class="hint">点击「设为当前」切换 App 中使用的人设，保存后 App 重新读取配置时生效。</div>
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

    <!-- ── 备份恢复 ── -->
    <div id="pane-backups" class="pane">
      <p class="section-title">历史备份</p>
      <div class="card" id="backup-list">
        <div style="padding:16px;color:var(--sub);font-size:14px;">加载中…</div>
      </div>
      <div class="hint">每次点击「保存配置」时自动备份，保留最近 10 份。点击「恢复」将覆盖当前配置。</div>
    </div>

    <!-- ── OpenClaw 配置 ── -->
    <div id="pane-openclaw" class="pane">
      <p class="section-title">连接配置</p>
      <div class="card">
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">启用 OpenClaw</div>
            <div class="field-sub">连接到 OpenClaw 服务</div>
          </div>
          <div class="toggle-wrap">
            <label class="toggle">
              <input type="checkbox" id="openclaw_enabled">
              <span class="slider"></span>
            </label>
          </div>
        </div>
        <div class="field">
          <div class="field-label-wrap">
            <div class="field-label">服务地址</div>
          </div>
          <input type="text" id="openclaw_url" placeholder="http://154.9.252.35:3000/api/chat">
        </div>
      </div>

      <p class="section-title">API 密钥管理</p>
      <div class="card">
        <div id="apikey-list"></div>
        <button class="add-row-btn" onclick="addApiKey()">＋ 添加 API Key</button>
      </div>
      <div class="hint">API Key 用于验证客户端请求。iOS App 需要配置相同的 Key 才能连接。</div>

      <p class="section-title">连接测试</p>
      <div class="card">
        <div class="field" style="flex-direction:column;align-items:stretch;gap:10px;">
          <div style="display:flex;gap:8px;align-items:center;">
            <input type="text" id="test_message" placeholder="输入测试消息..." value="你好，请介绍一下你自己" style="flex:1;">
            <button class="save-btn" onclick="testOpenClaw()" style="padding:8px 20px;">发送测试</button>
          </div>
          <div id="test_result" style="display:none;padding:12px;background:var(--input-bg);border-radius:8px;font-size:13px;line-height:1.6;white-space:pre-wrap;"></div>
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

  // Personas
  personasData = cfg.personas || [];
  selectedPersonaId = cfg.selectedPersonaId || (personasData[0] && personasData[0].id) || '';
  renderPersonas();

  // Content
  document.getElementById('content_auto_generate').checked    = cfg.content.auto_generate    ?? true;
  document.getElementById('content_review_before_post').checked = cfg.content.review_before_post ?? true;
  document.getElementById('content_moments_daily').value = cfg.content.moments_daily ?? 1;
  document.getElementById('content_xhs_daily').value     = cfg.content.xhs_daily     ?? 1;
  document.getElementById('content_oa_weekly').value     = cfg.content.oa_weekly     ?? 1;

  // OpenClaw
  const openclaw = cfg.openclaw || {};
  document.getElementById('openclaw_enabled').checked = openclaw.enabled ?? false;
  document.getElementById('openclaw_url').value = openclaw.url || '';
  apiKeysData = openclaw.api_keys || [];
  renderApiKeys();

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

  // ── Multi-image upload widget ──
  const imgBlock = document.createElement('div');
  const imgLbl = document.createElement('div');
  imgLbl.className = 'sched-field-label';
  imgLbl.textContent = '配图（可多张）';
  imgBlock.appendChild(imgLbl);

  // Grid container holds thumbnail slots + add button
  const imgGrid = document.createElement('div');
  imgGrid.className = 'img-grid';
  imgGrid.dataset.key = 'media_files';

  // Hidden file input (reused for each upload)
  const fileInput = document.createElement('input');
  fileInput.type = 'file';
  fileInput.accept = 'image/*';
  fileInput.multiple = true;
  fileInput.style.display = 'none';
  imgGrid.appendChild(fileInput);

  // Render existing saved images
  const existingFiles = Array.isArray(row.media_files) ? row.media_files
    : (row.media_file ? [row.media_file] : []);

  function addThumb(filename) {
    const thumb = document.createElement('div');
    thumb.className = 'img-thumb';
    thumb.dataset.filename = filename;
    const img = document.createElement('img');
    img.src = '/media/' + filename;
    const delBtn = document.createElement('button');
    delBtn.className = 'img-del';
    delBtn.type = 'button';
    delBtn.textContent = '×';
    delBtn.onclick = () => thumb.remove();
    thumb.appendChild(img);
    thumb.appendChild(delBtn);
    // Insert before the add-slot
    const addSlot = imgGrid.querySelector('.img-add-slot');
    imgGrid.insertBefore(thumb, addSlot);
  }

  existingFiles.filter(Boolean).forEach(addThumb);

  // "+" add slot
  const addSlot = document.createElement('div');
  addSlot.className = 'img-add-slot';
  addSlot.innerHTML = '＋<span>添加图片</span>';
  addSlot.onclick = () => fileInput.click();
  imgGrid.appendChild(addSlot);

  // Status text
  const statusSpan = document.createElement('div');
  statusSpan.className = 'img-name';
  imgGrid.appendChild(statusSpan);

  // Wire file selection → upload (supports multiple files)
  fileInput.onchange = async () => {
    const files = Array.from(fileInput.files);
    if (!files.length) return;
    statusSpan.innerHTML = '<span class="img-uploading">上传中...</span>';
    for (const file of files) {
      const fd = new FormData();
      fd.append('file', file);
      try {
        const res = await fetch('/api/upload', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
          addThumb(data.filename);
        } else {
          statusSpan.textContent = '上传失败：' + (data.error || '');
        }
      } catch(e) {
        statusSpan.textContent = '上传失败';
      }
    }
    statusSpan.textContent = '';
    fileInput.value = '';
  };

  imgBlock.appendChild(imgGrid);
  contentDiv.appendChild(imgBlock);

  // Advanced toggle
  const advToggle = document.createElement('span');
  advToggle.className = 'adv-toggle';
  advToggle.innerHTML = '▸ 配图说明 / 风格备注';

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
     card_summary:'',post_content:'',media_files:[],media_desc:'',style_note:''},
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
    // Collect media_files array from thumbnail data attributes
    const grid = item.querySelector('[data-key="media_files"]');
    const mediaFiles = grid
      ? Array.from(grid.querySelectorAll('.img-thumb')).map(t => t.dataset.filename).filter(Boolean)
      : [];
    rows.push({
      time:         get('time'),
      platform:     get('platform'),
      title:        get('title'),
      enabled:      get('enabled'),
      card_summary: get('card_summary'),
      post_content: get('post_content'),
      media_files:  mediaFiles,
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
    personas: personasData,
    selectedPersonaId: selectedPersonaId,
    content: {
      auto_generate:     document.getElementById('content_auto_generate').checked,
      review_before_post:document.getElementById('content_review_before_post').checked,
      moments_daily:     parseInt(document.getElementById('content_moments_daily').value),
      xhs_daily:         parseInt(document.getElementById('content_xhs_daily').value),
      oa_weekly:         parseInt(document.getElementById('content_oa_weekly').value),
    },
    openclaw: {
      enabled: document.getElementById('openclaw_enabled').checked,
      url: document.getElementById('openclaw_url').value,
      api_keys: apiKeysData,
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

// ── Backup management ─────────────────────────────────────────────────────
async function loadBackups() {
  const res = await fetch('/api/backups');
  const files = await res.json();
  const list = document.getElementById('backup-list');
  if (!files.length) {
    list.innerHTML = '<div style="padding:16px;color:var(--sub);font-size:14px;">暂无备份</div>';
    return;
  }
  list.innerHTML = '';
  files.forEach(filename => {
    // filename format: config_YYYYMMDD_HHMMSS.json
    const m = filename.match(/config_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.json/);
    const label = m ? `${m[1]}-${m[2]}-${m[3]} ${m[4]}:${m[5]}:${m[6]}` : filename;
    const row = document.createElement('div');
    row.className = 'field';
    row.style.justifyContent = 'space-between';
    const span = document.createElement('span');
    span.style.cssText = 'font-size:14px;font-weight:500;';
    span.textContent = label;
    const btn = document.createElement('button');
    btn.className = 'save-btn';
    btn.style.cssText = 'padding:6px 16px;font-size:13px;';
    btn.textContent = '恢复';
    btn.onclick = async () => {
      if (!confirm(`恢复备份 ${label}？当前配置将被覆盖。`)) return;
      const r = await fetch('/api/backups/restore', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({filename}),
      });
      if ((await r.json()).ok) {
        const toast = document.getElementById('toast');
        toast.textContent = '\u2713 \u5DF2\u6062\u590D\u5907\u4EFD';
        toast.classList.add('show');
        setTimeout(() => { toast.classList.remove('show'); toast.textContent='\u2713 \u914D\u7F6E\u5DF2\u4FDD\u5B58'; }, 2200);
        loadConfig();
      }
    };
    row.appendChild(span);
    row.appendChild(btn);
    list.appendChild(row);
  });
}

// ── Persona management ─────────────────────────────────────────────────────
let personasData = [];
let selectedPersonaId = '';
let editingPersonaId = null;

const TONE_LABELS = { professional:'专业严谨', friendly:'亲切温暖', creative:'创意活泼', concise:'简洁高效' };
const TONE_COLORS = { professional:'#7B8CB6', friendly:'#FF8C33', creative:'#CC33CC', concise:'#34C759' };

function genId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = Math.random()*16|0, v = c==='x' ? r : (r&0x3|0x8);
    return v.toString(16);
  });
}

function renderPersonas() {
  const container = document.getElementById('persona-list');
  if (!container) return;
  container.innerHTML = '';
  personasData.forEach(p => {
    if (editingPersonaId === p.id) container.appendChild(makePersonaForm(p));
    else container.appendChild(makePersonaCard(p));
  });
  if (editingPersonaId === 'new') container.appendChild(makePersonaForm(null));
}

function makePersonaCard(p) {
  const isSelected = p.id === selectedPersonaId;
  const div = document.createElement('div');
  div.className = 'persona-card' + (isSelected ? ' persona-selected' : '');

  const emojiDiv = document.createElement('div');
  emojiDiv.className = 'persona-emoji';
  emojiDiv.textContent = p.emoji || '\uD83D\uDC64';

  const info = document.createElement('div');
  info.className = 'persona-info';

  const nameRow = document.createElement('div');
  nameRow.className = 'persona-name-row';
  const nameSpan = document.createElement('span');
  nameSpan.className = 'persona-name';
  nameSpan.textContent = p.name;
  const toneBadge = document.createElement('span');
  toneBadge.className = 'persona-tone-badge';
  toneBadge.style.background = TONE_COLORS[p.tone] || '#888';
  toneBadge.textContent = p.tone || '';
  nameRow.appendChild(nameSpan);
  nameRow.appendChild(toneBadge);
  if (isSelected) {
    const selBadge = document.createElement('span');
    selBadge.className = 'persona-sel-badge';
    selBadge.textContent = '当前使用';
    nameRow.appendChild(selBadge);
  }

  const desc = document.createElement('div');
  desc.className = 'persona-desc';
  desc.textContent = p.description || '';

  const tagsDiv = document.createElement('div');
  tagsDiv.className = 'persona-tags';
  (p.tags || []).forEach(tag => {
    const t = document.createElement('span');
    t.className = 'persona-tag';
    t.textContent = tag;
    tagsDiv.appendChild(t);
  });

  info.appendChild(nameRow);
  info.appendChild(desc);
  info.appendChild(tagsDiv);

  const actions = document.createElement('div');
  actions.className = 'persona-actions';

  const selBtn = document.createElement('button');
  selBtn.className = 'persona-action-btn persona-select-btn' + (isSelected ? ' active' : '');
  selBtn.textContent = isSelected ? '\u2713 \u5DF2\u9009\u4E2D' : '\u8BBE\u4E3A\u5F53\u524D';
  if (!isSelected) selBtn.onclick = () => { selectedPersonaId = p.id; renderPersonas(); };

  const editBtn = document.createElement('button');
  editBtn.className = 'persona-action-btn persona-edit-btn';
  editBtn.textContent = '\u7F16\u8F91';
  editBtn.onclick = () => { editingPersonaId = p.id; renderPersonas(); };

  const delBtn = document.createElement('button');
  delBtn.className = 'persona-action-btn persona-del-btn';
  delBtn.textContent = '\u5220\u9664';
  delBtn.onclick = () => {
    if (personasData.length <= 1) { alert('\u81F3\u5C11\u4FDD\u7559\u4E00\u4E2A\u4EBA\u8BBE'); return; }
    personasData = personasData.filter(x => x.id !== p.id);
    if (selectedPersonaId === p.id) selectedPersonaId = personasData[0]?.id || '';
    renderPersonas();
  };

  actions.appendChild(selBtn);
  actions.appendChild(editBtn);
  actions.appendChild(delBtn);

  div.appendChild(emojiDiv);
  div.appendChild(info);
  div.appendChild(actions);
  return div;
}

function makePersonaForm(p) {
  const isNew = !p;
  const div = document.createElement('div');
  div.className = 'persona-form';

  function formRow(labelText, inputEl) {
    const row = document.createElement('div');
    row.className = 'persona-form-row';
    const label = document.createElement('div');
    label.className = 'persona-form-label';
    label.textContent = labelText;
    row.appendChild(label);
    row.appendChild(inputEl);
    return row;
  }

  const emojiInput = document.createElement('input');
  emojiInput.type = 'text';
  emojiInput.value = p?.emoji || '\uD83D\uDC64';
  emojiInput.className = 'emoji-input';
  emojiInput.placeholder = '\u8868\u60C5';
  const nameInput = document.createElement('input');
  nameInput.type = 'text';
  nameInput.value = p?.name || '';
  nameInput.placeholder = '\u4EBA\u8BBE\u540D\u79F0';
  const emojiNameRow = document.createElement('div');
  emojiNameRow.className = 'persona-form-row';
  const emojiLabel = document.createElement('div');
  emojiLabel.className = 'persona-form-label';
  emojiLabel.textContent = '\u540D\u79F0';
  emojiNameRow.appendChild(emojiLabel);
  emojiNameRow.appendChild(emojiInput);
  emojiNameRow.appendChild(nameInput);
  div.appendChild(emojiNameRow);

  const toneInput = document.createElement('input');
  toneInput.type = 'text';
  toneInput.value = p?.tone || '';
  toneInput.placeholder = '\u4F8B\uFF1A\u4E13\u4E1A\u4E25\u8C28\u3001\u4EB2\u5207\u6E29\u6696\u3001\u521B\u610F\u6D3B\u6CFC\u2026';
  toneInput.setAttribute('list', 'tone-suggestions');
  const datalist = document.createElement('datalist');
  datalist.id = 'tone-suggestions';
  Object.values(TONE_LABELS).forEach(lbl => {
    const opt = document.createElement('option');
    opt.value = lbl;
    datalist.appendChild(opt);
  });
  div.appendChild(datalist);
  div.appendChild(formRow('\u98CE\u683C', toneInput));

  const descInput = document.createElement('textarea');
  descInput.value = p?.description || '';
  descInput.placeholder = '\u4EBA\u8BBE\u7B80\u4ECB';
  descInput.rows = 2;
  div.appendChild(formRow('\u7B80\u4ECB', descInput));

  const tagsInput = document.createElement('input');
  tagsInput.type = 'text';
  tagsInput.value = (p?.tags || []).join(',');
  tagsInput.placeholder = '\u6807\u7B7E\uFF08\u9017\u53F7\u5206\u9694\uFF09';
  div.appendChild(formRow('\u6807\u7B7E', tagsInput));

  const btns = document.createElement('div');
  btns.className = 'persona-form-btns';

  const saveBtn = document.createElement('button');
  saveBtn.className = 'persona-form-save';
  saveBtn.textContent = '\u4FDD\u5B58';
  saveBtn.onclick = () => {
    const newP = {
      id: p?.id || genId(),
      name: nameInput.value.trim() || '\u672A\u547D\u540D',
      emoji: emojiInput.value.trim() || '\uD83D\uDC64',
      description: descInput.value.trim(),
      tone: toneInput.value.trim(),
      tags: tagsInput.value.split(',').map(t => t.trim()).filter(Boolean),
    };
    if (isNew) {
      personasData.push(newP);
      if (!selectedPersonaId) selectedPersonaId = newP.id;
    } else {
      const idx = personasData.findIndex(x => x.id === p.id);
      if (idx >= 0) personasData[idx] = newP;
      if (selectedPersonaId === p.id) selectedPersonaId = newP.id;
    }
    editingPersonaId = null;
    renderPersonas();
  };

  const cancelBtn = document.createElement('button');
  cancelBtn.className = 'persona-form-cancel';
  cancelBtn.textContent = '\u53D6\u6D88';
  cancelBtn.onclick = () => { editingPersonaId = null; renderPersonas(); };

  btns.appendChild(cancelBtn);
  btns.appendChild(saveBtn);
  div.appendChild(btns);
  return div;
}

function addPersona() {
  editingPersonaId = 'new';
  renderPersonas();
}

// ── API Key management ────────────────────────────────────────────────────
let apiKeysData = [];

function renderApiKeys() {
  const container = document.getElementById('apikey-list');
  if (!container) return;
  container.innerHTML = '';
  apiKeysData.forEach((k, idx) => {
    const div = document.createElement('div');
    div.className = 'field';
    div.style.cssText = 'display:grid;grid-template-columns:1fr 1fr 120px auto;gap:8px;align-items:center;';

    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.value = k.name || '';
    nameInput.placeholder = '客户端名称';
    nameInput.style.cssText = 'font-size:13px;padding:6px 10px;';
    nameInput.oninput = () => { apiKeysData[idx].name = nameInput.value; };

    const keyInput = document.createElement('input');
    keyInput.type = 'text';
    keyInput.value = k.key || '';
    keyInput.placeholder = 'API Key';
    keyInput.style.cssText = 'font-size:13px;padding:6px 10px;font-family:monospace;';
    keyInput.oninput = () => { apiKeysData[idx].key = keyInput.value; };

    const dateSpan = document.createElement('span');
    dateSpan.style.cssText = 'font-size:12px;color:var(--sub);';
    dateSpan.textContent = k.created || '';

    const delBtn = document.createElement('button');
    delBtn.className = 'del-btn';
    delBtn.innerHTML = '×';
    delBtn.onclick = () => { apiKeysData.splice(idx, 1); renderApiKeys(); };

    div.appendChild(nameInput);
    div.appendChild(keyInput);
    div.appendChild(dateSpan);
    div.appendChild(delBtn);
    container.appendChild(div);
  });
}

function addApiKey() {
  const today = new Date().toISOString().split('T')[0];
  apiKeysData.push({ key: '', name: '', created: today });
  renderApiKeys();
}

// ── OpenClaw test ─────────────────────────────────────────────────────────
async function testOpenClaw() {
  const resultDiv = document.getElementById('test_result');
  const message = document.getElementById('test_message').value;

  if (!message.trim()) {
    resultDiv.style.display = 'block';
    resultDiv.style.color = 'var(--danger)';
    resultDiv.textContent = '请输入测试消息';
    return;
  }

  resultDiv.style.display = 'block';
  resultDiv.style.color = 'var(--sub)';
  resultDiv.textContent = '发送中...';

  try {
    const res = await fetch('/api/openclaw/test', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: message }),
    });
    const data = await res.json();

    if (data.ok) {
      resultDiv.style.color = 'var(--green)';
      resultDiv.textContent = '✓ 连接成功\n\n回复：' + (data.reply || '');
    } else {
      resultDiv.style.color = 'var(--danger)';
      resultDiv.textContent = '✗ 连接失败\n\n错误：' + (data.error || '未知错误');
    }
  } catch (e) {
    resultDiv.style.color = 'var(--danger)';
    resultDiv.textContent = '✗ 请求失败\n\n' + e.message;
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
        elif path == "/api/backups":
            files = sorted(glob_mod.glob(os.path.join(BACKUP_DIR, "config_*.json")), reverse=True)
            self.send_json([os.path.basename(f) for f in files])
        elif path.startswith("/api/backups/"):
            filename = os.path.basename(path[13:])
            filepath = os.path.join(BACKUP_DIR, filename)
            if filename.startswith("config_") and filename.endswith(".json") and os.path.isfile(filepath):
                with open(filepath, "r", encoding="utf-8") as f:
                    self.send_json(json.load(f))
            else:
                self.send_response(404); self.end_headers()
        elif path == "/api/personas":
            cfg = load_config()
            self.send_json({
                "personas": cfg.get("personas", []),
                "selectedPersonaId": cfg.get("selectedPersonaId", ""),
            })
        elif path.startswith("/media/"):
            filename = os.path.basename(path[7:])
            filepath = os.path.join(MEDIA_DIR, filename)
            if filename and os.path.isfile(filepath):
                mime = mimetypes.guess_type(filepath)[0] or "application/octet-stream"
                with open(filepath, "rb") as f:
                    data = f.read()
                self.send_response(200)
                self.send_header("Content-Type", mime)
                self.send_header("Content-Length", len(data))
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(data)
            else:
                self.send_response(404)
                self.end_headers()
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
        elif path == "/api/backups/restore":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                filename = os.path.basename(data.get("filename", ""))
                filepath = os.path.join(BACKUP_DIR, filename)
                if not (filename.startswith("config_") and filename.endswith(".json") and os.path.isfile(filepath)):
                    self.send_json({"ok": False, "error": "invalid backup"}, status=400)
                    return
                with open(filepath, "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                save_config(cfg)
                self.send_json({"ok": True})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, status=400)
        elif path == "/api/personas":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                cfg = load_config()
                cfg["personas"] = data.get("personas", [])
                cfg["selectedPersonaId"] = data.get("selectedPersonaId", "")
                save_config(cfg)
                self.send_json({"ok": True})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, status=400)
        elif path == "/api/upload":
            try:
                ctype = self.headers.get("Content-Type", "")
                length = int(self.headers.get("Content-Length", 0))
                # cgi.FieldStorage needs environ dict
                environ = {
                    "REQUEST_METHOD": "POST",
                    "CONTENT_TYPE": ctype,
                    "CONTENT_LENGTH": str(length),
                }
                fs = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ=environ,
                )
                item = fs.getvalue("file") if "file" in fs else None
                if item is None:
                    self.send_json({"ok": False, "error": "no file"}, status=400)
                    return
                file_item = fs["file"]
                orig_name = getattr(file_item, "filename", "") or "upload"
                ext = os.path.splitext(orig_name)[1].lower()
                if ext not in (".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic"):
                    ext = ".jpg"
                unique_name = uuid_mod.uuid4().hex[:12] + ext
                dest = os.path.join(MEDIA_DIR, unique_name)
                with open(dest, "wb") as f:
                    f.write(file_item.file.read())
                self.send_json({"ok": True, "filename": unique_name})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, status=500)
        elif path == "/api/openclaw/chat":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                import urllib.request
                data = json.loads(body)
                message = data.get("message", "")
                user_id = data.get("userId", "anonymous")
                session_id = data.get("sessionId")

                cfg = load_config()
                openclaw_cfg = cfg.get("openclaw", {})
                openclaw_url = openclaw_cfg.get("url", "")
                api_keys = openclaw_cfg.get("api_keys", [])

                if not openclaw_url:
                    self.send_json({"ok": False, "error": "OpenClaw URL not configured"}, status=500)
                    return
                if not api_keys:
                    self.send_json({"ok": False, "error": "No API keys configured"}, status=500)
                    return

                api_key = api_keys[0].get("key", "")

                req_data = json.dumps({
                    "message": message,
                    "userId": user_id,
                    "sessionId": session_id
                }).encode('utf-8')

                req = urllib.request.Request(
                    openclaw_url,
                    data=req_data,
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json"
                    }
                )

                with urllib.request.urlopen(req, timeout=30) as response:
                    resp_data = response.read().decode('utf-8')
                    resp_json = json.loads(resp_data)
                    self.send_json(resp_json)
            except urllib.error.HTTPError as e:
                error_body = e.read().decode('utf-8') if e.fp else str(e)
                self.send_json({"ok": False, "error": f"OpenClaw error: {e.code} {error_body}"}, status=502)
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, status=500)
        elif path == "/api/openclaw/test":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                import urllib.request
                data = json.loads(body)
                message = data.get("message", "测试消息")

                cfg = load_config()
                openclaw_cfg = cfg.get("openclaw", {})
                openclaw_url = openclaw_cfg.get("url", "")
                api_keys = openclaw_cfg.get("api_keys", [])

                if not openclaw_url:
                    self.send_json({"ok": False, "error": "未配置 OpenClaw 服务地址"})
                    return
                if not api_keys or not api_keys[0].get("key"):
                    self.send_json({"ok": False, "error": "未配置 API Key"})
                    return

                api_key = api_keys[0].get("key", "")

                req_data = json.dumps({
                    "message": message,
                    "userId": "backend-test",
                    "sessionId": "test-" + str(uuid_mod.uuid4())[:8]
                }).encode('utf-8')

                req = urllib.request.Request(
                    openclaw_url,
                    data=req_data,
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json"
                    }
                )

                with urllib.request.urlopen(req, timeout=30) as response:
                    resp_data = response.read().decode('utf-8')
                    resp_json = json.loads(resp_data)
                    self.send_json({"ok": True, "reply": resp_json.get("reply", ""), "raw": resp_json})
            except urllib.error.HTTPError as e:
                error_body = e.read().decode('utf-8') if e.fp else str(e)
                self.send_json({"ok": False, "error": f"HTTP {e.code}: {error_body}"})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)})
        else:
            self.send_response(404)
            self.end_headers()


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"\n  AgentDigitalTwin 后台配置服务已启动")
    print(f"  访问地址：http://localhost:{PORT}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  已停止。")
        sys.exit(0)
