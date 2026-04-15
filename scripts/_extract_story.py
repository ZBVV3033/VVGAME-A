#!/usr/bin/env python3
"""
从 Lua 源码中提取所有剧情/对话文本，按分类输出到 docs/story/ 目录。
提取逻辑：找到每个段落（handler 或 passageName 分支），收集其中的字符串文本。
"""

import os, re, sys

SCRIPTS = "/workspace/scripts"
OUT_DIR = "/workspace/docs/story"

# === 分类映射 ===
CATEGORIES = [
    ("01-主线剧情-第一章", [
        "systems/mainquest/Ch1Passages.lua",
    ]),
    ("02-主线剧情-第二章", [
        "systems/MainQuestCh2.lua",
    ]),
    ("03-主线剧情-第三章", [
        "systems/MainQuestCh3.lua",
    ]),
    ("04-支线任务", [
        "systems/sidequests/Passages.lua",
    ]),
    ("05-NPC对话-基础", [
        "passages/TownPassages_Base.lua",
        "passages/TownPassages_Batch3.lua",
    ]),
    ("06-NPC对话-特殊", [
        "passages/TownPassages_Special.lua",
        "passages/TownPassages_Events.lua",
    ]),
    ("07-NPC事件-妖精与宴会", [
        "passages/npc_event/FairyInvitation.lua",
        "passages/npc_event/BanquetCat.lua",
    ]),
    ("08-NPC事件-相遇与约会", [
        "passages/npc_event/MeetAndRename.lua",
        "passages/npc_event/DateAppearance.lua",
    ]),
    ("09-城镇生活事件", [
        "systems/townlife/Events.lua",
    ]),
    ("10-打工事件", [
        "data/WorkEventData.lua",
    ]),
    ("11-家庭事件", [
        "data/HomeEventData.lua",
        "passages/HomePassages_Events.lua",
    ]),
    ("12-家庭房间互动", [
        "passages/HomePassages_Rooms.lua",
    ]),
    ("13-随机事件-属性检定", [
        "data/RandomEventData_StatCheck.lua",
    ]),
    ("14-随机事件-通用", [
        "passages/RandomPassages.lua",
    ]),
    ("15-地点-商业区", [
        "passages/location/CommercialDistrict.lua",
    ]),
    ("16-地点-贫民窟", [
        "passages/location/Slums.lua",
    ]),
    ("17-地点-港口与主城", [
        "passages/location/Harbor.lua",
        "passages/location/MainCity.lua",
    ]),
    ("18-大学系统", [
        "systems/university/Passages.lua",
    ]),
    ("19-战斗文本", [
        "systems/battle/BattlePassages.lua",
        "passages/system/SkillBattle.lua",
    ]),
    ("20-烹饪与种植", [
        "systems/CookingSystem.lua",
        "systems/FarmingSystem.lua",
    ]),
    ("21-序章", [
        "passages/ProloguePassages.lua",
    ]),
]


def extract_passages_handler_style(content, filepath):
    """提取 handlers["段落名"] = function() ... end 风格"""
    passages = []
    # 匹配 handlers["XXX"] = function() 或 handlers["XXX"] = U.xxx {
    pattern = r'handlers\["([^"]+)"\]\s*='
    matches = list(re.finditer(pattern, content))

    for i, m in enumerate(matches):
        name = m.group(1)
        start = m.start()
        # 找到下一个 handler 或文件末尾
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        block = content[start:end]
        passages.append((name, block))

    return passages


def extract_passages_if_style(content, filepath):
    """提取 if passageName == "段落名" then ... end 风格"""
    passages = []
    pattern = r'if passageName\s*==\s*"([^"]+)"\s*then'
    matches = list(re.finditer(pattern, content))

    for i, m in enumerate(matches):
        name = m.group(1)
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        block = content[start:end]
        passages.append((name, block))

    return passages


def extract_event_blocks(content, filepath):
    """提取 townlife/Events.lua 和 RandomEventData 中的事件块"""
    passages = []
    # 匹配注释标记的事件块
    pattern = r'--\s*(?:============\s*)?(.+?)(?:\s*============)?(?:\s*\(.+\))?\s*$'
    lines = content.split('\n')

    current_name = None
    current_block = []

    for line in lines:
        # 检测章节注释
        cm = re.match(r'\s*--\s*={3,}\s*(.+?)\s*(?:={3,})?\s*$', line)
        if cm:
            section = cm.group(1).strip()
            # 跳过纯分隔线
            if section and not all(c == '=' for c in section):
                if current_name and current_block:
                    passages.append((current_name, '\n'.join(current_block)))
                current_name = section
                current_block = []
                continue

        if current_name:
            current_block.append(line)

    if current_name and current_block:
        passages.append((current_name, '\n'.join(current_block)))

    return passages


def extract_work_events(content, filepath):
    """专用解析器：WorkEventData.lua（按职业×事件分段）"""
    JOB_NAMES = {
        'waiter': '酒馆服务员',
        'cleric': '教堂助手',
        'blacksmith': '铁匠',
        'laborer': '劳工',
        'butler': '管家',
    }
    passages = []
    lines = content.split('\n')
    current_job = None
    current_event = None
    current_block = []

    for line in lines:
        # 检测职业分类: waiter = {
        jm = re.match(r'\s*(waiter|cleric|blacksmith|laborer|butler)\s*=\s*\{', line)
        if jm:
            if current_event and current_block:
                passages.append((current_event, '\n'.join(current_block)))
            current_job = JOB_NAMES.get(jm.group(1), jm.group(1))
            current_event = None
            current_block = []
            continue

        # 检测事件注释: -- 事件N: 事件名
        em = re.match(r'\s*--\s*事件\d+[:：]\s*(.+)', line)
        if em and current_job:
            if current_event and current_block:
                passages.append((current_event, '\n'.join(current_block)))
            current_event = f"{current_job} - {em.group(1).strip()}"
            current_block = []
            continue

        if current_event:
            current_block.append(line)

    if current_event and current_block:
        passages.append((current_event, '\n'.join(current_block)))

    return passages


def extract_data_entries(content, filepath):
    """提取数据表风格（HomeEventData 等）的条目"""
    passages = []
    lines = content.split('\n')

    current_name = None
    current_block = []

    for line in lines:
        # 匹配 -- 事件N: 名称 或 -- ===名称=== 风格
        em = re.match(r'\s*--\s*事件\d+[:：]\s*(.+)', line)
        cm = re.match(r'\s*--\s*[-=]{3,}\s*(.+?)\s*[-=]*\s*$', line)
        match = em or cm
        if match:
            section = match.group(1).strip()
            if section and not all(c in '-= ' for c in section):
                if current_name and current_block:
                    passages.append((current_name, '\n'.join(current_block)))
                current_name = section
                current_block = []
                continue
        if current_name:
            current_block.append(line)

    if current_name and current_block:
        passages.append((current_name, '\n'.join(current_block)))

    # 如果没找到注释分段，整个文件作为一个块
    if not passages:
        passages = [("全部内容", content)]

    return passages


def extract_strings_from_block(block):
    """从代码块中提取所有字符串文本"""
    strings = []

    # 匹配双引号字符串（包括多行拼接）
    # 收集所有 "..." 内容
    raw_strings = re.findall(r'"((?:[^"\\]|\\.)*)"', block)

    for s in raw_strings:
        # 过滤纯代码字符串（路径、模块名、事件名等）
        if any(skip in s for skip in [
            'require', 'systems.', 'passages.', 'data.', 'utils.', 'editor.',
            'Models/', 'Techniques/', 'Fonts/', 'Textures/', 'Sounds/',
            '.lua', '.xml', '.json', '.md', '.fsm',
            'urhox-libs', 'LuaScripts/',
            'PBR/', 'NoTexture',
        ]):
            continue

        # 过滤 UI 元素文本（发型/颜色选择列表、变量名等）
        if s in ('color', 'street_performance', 'music_theory',
                 'afternoon', 'morning', 'evening', 'night'):
            continue
        # 过滤纯颜色/发型名称（序章角色创建 UI）
        if re.match(r'^(黑色|棕色|金色|淡黄色|红色|白色|灰色|蓝色|赤色|翠绿|紫色|银色|琥珀|短发|长发|及肩长发|马尾|寸头|卷发|编发|披肩发)$', s):
            continue
        # 过滤纯变量名/标识符（camelCase 或 snake_case，无中文）
        if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', s):
            continue

        # 处理转义
        s = s.replace('\\n', '\n').replace('\\t', '\t').replace('\\"', '"')

        # 过滤太短的（按钮文字等保留，但纯英文短标识符跳过）
        has_cn = bool(re.search(r'[\u4e00-\u9fff]', s))
        if not has_cn and len(s) < 5:
            continue

        strings.append(s)

    return strings


def format_passage(name, block, passage_names=None):
    """格式化一个段落的输出"""
    strings = extract_strings_from_block(block)
    # 过滤掉段落名/跳转目标
    if passage_names:
        strings = [s for s in strings if s.strip() not in passage_names]
    if not strings:
        return None

    lines = []
    lines.append(f"### {name}")
    lines.append("")

    # 合并相邻短字符串为连续段落，然后输出
    # 策略：相邻的短字符串（<80字、无换行）合并为一段，长文本或含换行的独立成段
    merged = []
    buf = []

    def flush_buf():
        if not buf:
            return
        # 将短字符串拼接，但如果前一个以句末标点结尾且下一个是新句子则换行
        result_parts = [buf[0]]
        for i in range(1, len(buf)):
            prev = buf[i-1]
            cur = buf[i]
            # 前一个以叙事标点结尾，或当前以引号/括号开头 → 换行
            if prev and prev[-1] in '。！？」】）…—' and len(prev) > 10:
                result_parts.append('\n' + cur)
            else:
                result_parts.append(cur)
        merged.append(''.join(result_parts))
        buf.clear()

    for s in strings:
        s = s.strip()
        if not s:
            continue
        if '\n' in s or len(s) > 80:
            # 长文本或含换行 → 独立成段
            flush_buf()
            merged.append(s)
        else:
            buf.append(s)

    flush_buf()

    for text in merged:
        lines.append(text)
        lines.append("")

    lines.append("---")
    lines.append("")
    return '\n'.join(lines)


def count_cn_chars(text):
    """统计中文字符数"""
    return len(re.findall(r'[\u4e00-\u9fff\u3000-\u303f\uff01-\uff5e]', text))


def process_category(cat_name, files):
    """处理一个分类"""
    all_output = []
    total_chars = 0

    for rel_path in files:
        full_path = os.path.join(SCRIPTS, rel_path)
        if not os.path.exists(full_path):
            continue

        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 选择提取策略
        if 'WorkEventData' in rel_path:
            passages = extract_work_events(content, rel_path)
        elif 'handlers[' in content:
            passages = extract_passages_handler_style(content, rel_path)
        elif 'passageName ==' in content:
            passages = extract_passages_if_style(content, rel_path)
        elif 'EventData' in rel_path or 'Data' in rel_path:
            passages = extract_data_entries(content, rel_path)
        else:
            passages = extract_event_blocks(content, rel_path)

        if not passages:
            # fallback: 整个文件作为一个块
            passages = [("全部内容", content)]

        # 收集所有段落名 + 文件内所有 target 引用，用于过滤跳转目标
        passage_names = set(pname for pname, _ in passages)
        # 也收集 target = "xxx" 中的目标名
        for t in re.findall(r'target\s*=\s*"([^"]+)"', content):
            passage_names.add(t)
        # 收集 handler 键名
        for h in re.findall(r'handlers\["([^"]+)"\]', content):
            passage_names.add(h)

        file_output = []
        file_output.append(f"## {os.path.basename(rel_path)}")
        file_output.append(f"> 源文件: `{rel_path}`")
        file_output.append("")

        has_content = False
        for name, block in passages:
            formatted = format_passage(name, block, passage_names)
            if formatted:
                file_output.append(formatted)
                has_content = True

        if has_content:
            file_text = '\n'.join(file_output)
            total_chars += count_cn_chars(file_text)
            all_output.append(file_text)

    if not all_output:
        return None, 0

    header = f"# {cat_name}\n\n"
    header += f"**总字数: ~{total_chars} 字**\n\n---\n\n"
    return header + '\n'.join(all_output), total_chars


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    summary = []
    grand_total = 0

    for cat_name, files in CATEGORIES:
        output, chars = process_category(cat_name, files)
        if output and chars > 0:
            out_path = os.path.join(OUT_DIR, f"{cat_name}.md")
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(output)
            summary.append((cat_name, chars, out_path))
            grand_total += chars
            print(f"  ✅ {cat_name}: {chars:,} 字")

    # 写总目录
    idx_lines = ["# 悠闲悠哉life - 剧情文本总览\n"]
    idx_lines.append(f"**总字数: {grand_total:,} 字** (约 {grand_total // 500} 页 A4)\n")
    idx_lines.append("")
    idx_lines.append("| 编号 | 分类 | 字数 |")
    idx_lines.append("|------|------|------|")
    for cat_name, chars, _ in summary:
        idx_lines.append(f"| {cat_name[:2]} | {cat_name[3:]} | {chars:,} 字 |")
    idx_lines.append(f"| | **合计** | **{grand_total:,} 字** |")
    idx_lines.append("")

    idx_path = os.path.join(OUT_DIR, "00-目录.md")
    with open(idx_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(idx_lines))

    print(f"\n📚 总计: {grand_total:,} 字，{len(summary)} 个分类文件")
    print(f"📁 输出目录: {OUT_DIR}/")


if __name__ == "__main__":
    main()
