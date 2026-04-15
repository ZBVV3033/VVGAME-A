// ==================== 工具函数 ====================
window.modStat = function(stat, delta) {
    var cur = State.variables[stat];
    if (typeof cur !== 'number' || isNaN(cur)) cur = 0;
    var newVal = cur + delta;
    State.variables[stat] = Math.max(0, Math.min(999, newVal));
};

window.addDateLog = function(person, type, content) {
    var dateStr = State.variables.year + "年" + State.variables.month + "月" + State.variables.day + "日";
    State.variables.dateLogs.push({ date: dateStr, person: person, type: type, content: content });
    if (State.variables.dateLogs.length > 50) State.variables.dateLogs.shift();
};

window.showNotification = function(msg, duration) {
    var div = document.createElement('div');
    div.className = 'notification';
    div.textContent = msg;
    document.body.appendChild(div);
    setTimeout(function() { div.remove(); }, duration || 3000);
};

// ==================== 礼仪/历史经验与等级 ====================
window.addMannerExp = function(amount) {
    var exp = State.variables.mannerExp + amount;
    var level = State.variables.mannerLevel;
    var upgraded = false;
    while (exp >= 100) {
        exp -= 100;
        level++;
        upgraded = true;
        State.variables.ML += 1;
        addLifeExp(50);
        addDateLog("礼仪", "等级提升", `礼仪等级提升到 ${level}，魅力+1。`);
        showNotification(`礼仪等级提升到 ${level}！魅力+1。`);
    }
    State.variables.mannerExp = exp;
    State.variables.mannerLevel = level;
};

window.addHistoryExp = function(amount) {
    var exp = State.variables.historyExp + amount;
    var level = State.variables.historyLevel;
    var upgraded = false;
    while (exp >= 100) {
        exp -= 100;
        level++;
        upgraded = true;
        State.variables.LG += 1;
        addLifeExp(50);
        addDateLog("历史", "等级提升", `历史等级提升到 ${level}，灵感+1。`);
        showNotification(`历史等级提升到 ${level}！灵感+1。`);
    }
    State.variables.historyExp = exp;
    State.variables.historyLevel = level;
};

window.addMannerLevel = function(amount) {
    for (var i = 0; i < amount; i++) {
        State.variables.mannerLevel++;
        State.variables.ML += 1;
        addLifeExp(50);
        addDateLog("礼仪", "等级提升", `礼仪等级提升到 ${State.variables.mannerLevel}，魅力+1。`);
        showNotification(`礼仪等级提升到 ${State.variables.mannerLevel}！魅力+1。`);
    }
};

window.addHistoryLevel = function(amount) {
    for (var i = 0; i < amount; i++) {
        State.variables.historyLevel++;
        State.variables.LG += 1;
        addLifeExp(50);
        addDateLog("历史", "等级提升", `历史等级提升到 ${State.variables.historyLevel}，灵感+1。`);
        showNotification(`历史等级提升到 ${State.variables.historyLevel}！灵感+1。`);
    }
};

// ==================== 好感度系统 ====================
window.affectionUpgrade = function(character, addAmount) {
    var msg = "";
    if (character === "initialName") {
        var aff = State.variables.initialNameAffection;
        var level = State.variables.initialNameLevel;
        if (aff >= 100) {
            level++;
            aff -= 100;
            State.variables.initialName_LL += 1;
            State.variables.initialName_LG += 1;
            State.variables.initialName_ML += 1;
            State.variables.initialName_NL += 1;
            State.variables.initialName_JQ += 1;
            msg = `${State.variables.initialName} 的好感度等级提升到 ${level}！`;
            addDateLog(State.variables.initialName, "好感提升", `好感度等级提升到 ${level}，五维各+1。`);
            showNotification(msg);
        }
        State.variables.initialNameAffection = aff;
        State.variables.initialNameLevel = level;
        return msg;
    } 
    else if (character === "k") {
        var aff = State.variables.kAffection;
        var level = State.variables.kLevel;
        if (aff >= 100) {
            level++;
            aff -= 100;
            State.variables.K_LL += 1;
            State.variables.K_LG += 1;
            State.variables.K_ML += 1;
            State.variables.K_NL += 1;
            State.variables.K_JQ += 1;
            msg = `K 的好感度等级提升到 ${level}！`;
            addDateLog("K", "好感提升", `好感度等级提升到 ${level}，五维各+1。`);
            showNotification(msg);
        }
        State.variables.kAffection = aff;
        State.variables.kLevel = level;
        return msg;
    }
    return "";
};

window.addAffection = function(character, amount) {
    if (character === "initialName") {
        State.variables.initialNameAffection += amount;
        affectionUpgrade("initialName", 0);
    } else if (character === "k") {
        State.variables.kAffection += amount;
        affectionUpgrade("k", 0);
    }
};

// ==================== 小奥好感度 ====================
window.addOamelAffection = function(amount) {
    var newAff = State.variables.oamelAffection + amount;
    var oldLevel = Math.floor(State.variables.oamelAffection / 50) + 1;
    var newLevel = Math.floor(newAff / 50) + 1;
    State.variables.oamelAffection = newAff;
    if (newLevel > oldLevel) {
        for (var i = oldLevel + 1; i <= newLevel; i++) {
            var bonus = i === 2 ? 5 : (i === 3 ? 10 : 0);
            if (bonus > 0) {
                State.variables.oamelSkillActive = true;
                State.variables.oamelSkillBonus = bonus;
                addDateLog("奥梅尔·罗斯巴特", "技能解锁", `获得「贵族的手腕」：打工工资+${bonus}%。`);
                showNotification(`罗斯巴特少爷对你的态度变了：「贵族的手腕」技能解锁，打工工资+${bonus}%！`);
            }
        }
        addDateLog("奥梅尔·罗斯巴特", "好感提升", `好感度等级提升到 ${newLevel}。`);
        showNotification(`你与奥梅尔·罗斯巴特的关系加深了！好感等级${newLevel}。`);
    }
};

// ==================== 梅菲斯好感度 ====================
window.addMeifeiAffection = function(amount) {
    var newAff = State.variables.meifeiAffection + amount;
    var oldLevel = State.variables.meifeiLevel;
    var newLevel = Math.floor(newAff / 50) + 1;
    State.variables.meifeiAffection = newAff;
    if (newLevel > oldLevel) {
        var levelGain = newLevel - oldLevel;
        State.variables.meifeiWageBonus += levelGain * 10;
        addMannerExp(levelGain);
        addDateLog("梅菲斯", "好感提升", `好感度等级提升到 ${newLevel}，时薪+${levelGain*10}，礼仪经验+${levelGain}。`);
        showNotification(`梅菲斯对你的好感加深了！时薪+${levelGain*10}，礼仪经验+${levelGain}。`);
    }
};

// ==================== 职业系统 ====================
window.addLifeExp = function(exp) {
    var newExp = State.variables.lifeExp + exp;
    var level = State.variables.lifeLevel;
    if (newExp >= 150) {
        level += Math.floor(newExp / 150);
        newExp = newExp % 150;
        var pointsGain = level - State.variables.lifeLevel;
        State.variables.attrPoints += pointsGain * 2;
        addDateLog("生活等级", "等级提升", `等级提升到 ${level}，获得 ${pointsGain * 2} 点属性点。`);
        showNotification(`生活等级提升到 ${level}！获得 ${pointsGain * 2} 属性点。`);
    }
    State.variables.lifeExp = newExp;
    State.variables.lifeLevel = level;
};

window.addJobExp = function(job, exp) {
    var expVar, levelVar, wageVar, stat;
    switch(job) {
        case "waiter":
            expVar = "jobWaiterExp";
            levelVar = "jobWaiterLevel";
            wageVar = "waiterWage";
            stat = "LL";
            break;
        case "cleric":
            expVar = "jobClericExp";
            levelVar = "jobClericLevel";
            wageVar = "clericWage";
            stat = "LG";
            break;
        case "blacksmith":
            expVar = "jobBlacksmithExp";
            levelVar = "jobBlacksmithLevel";
            wageVar = "blacksmithWage";
            stat = "NL";
            break;
        case "laborer":
            expVar = "jobLaborerExp";
            levelVar = "jobLaborerLevel";
            wageVar = "laborerWage";
            stat = "LL";
            break;
        case "butler":
            expVar = "butlerExp";
            levelVar = "butlerLevel";
            wageVar = "butlerWage";
            stat = "ML";
            break;
        default: return;
    }
    var newExp = State.variables[expVar] + exp;
    var level = State.variables[levelVar];
    var upgraded = false;
    while (newExp >= 100) {
        level++;
        newExp -= 100;
        upgraded = true;
        if (job === "butler") {
            modStat(stat, 1);
            State.variables[wageVar] += 15;
        } else {
            modStat(stat, 1);
            State.variables[wageVar] += 10;
        }
    }
    if (upgraded) {
        var jobName = job === "waiter" ? "服务员" : job === "cleric" ? "见习教士" : job === "blacksmith" ? "铁匠学徒" : job === "laborer" ? "港口杂工" : "侍从";
        addDateLog(jobName, "职业升级", `${jobName}等级提升到 ${level}，时薪+${job==='butler'?15:10}，${stat==='ML'?'魅力':stat==='LG'?'灵感':'力量'}+1。`);
        showNotification(`${jobName}等级提升到 ${level}！`);
        addLifeExp(50);
    }
    State.variables[expVar] = newExp;
    State.variables[levelVar] = level;
};

window.addInitialNameJobExp = function(job, exp) {
    var expVar, levelVar, wageVar;
    switch(job) {
        case "laborer":
            expVar = "initialNameLaborerExp";
            levelVar = "initialNameLaborerLevel";
            wageVar = "initialNameLaborerWage";
            break;
        case "waiter":
            expVar = "initialNameWaiterExp";
            levelVar = "initialNameWaiterLevel";
            wageVar = "initialNameWaiterWage";
            break;
        case "cleric":
            expVar = "initialNameClericExp";
            levelVar = "initialNameClericLevel";
            wageVar = "initialNameClericWage";
            break;
        case "blacksmith":
            expVar = "initialNameBlacksmithExp";
            levelVar = "initialNameBlacksmithLevel";
            wageVar = "initialNameBlacksmithWage";
            break;
        default: return 0;
    }
    var newExp = State.variables[expVar] + exp;
    var level = State.variables[levelVar];
    var upgraded = false;
    while (newExp >= 100) {
        level++;
        newExp -= 100;
        upgraded = true;
        State.variables.initialName_LL += 1;
        State.variables[wageVar] += 10;
    }
    if (upgraded) {
        var jobName = job === "laborer" ? "港口杂工" : job === "waiter" ? "服务员" : job === "cleric" ? "见习教士" : "铁匠学徒";
        addDateLog(State.variables.initialName, "职业升级", `${jobName}等级提升到 ${level}，时薪+10。`);
        showNotification(`${State.variables.initialName}的${jobName}等级提升到 ${level}！`);
    }
    State.variables[expVar] = newExp;
    State.variables[levelVar] = level;
    return State.variables[wageVar];
};

// ==================== 打工函数（含加成） ====================
window.doWork = function(job) {
    var wageVar = job === "waiter" ? "waiterWage" : job === "cleric" ? "clericWage" : job === "blacksmith" ? "blacksmithWage" : job === "butler" ? "butlerWage" : "laborerWage";
    var moneyGain = State.variables[wageVar];
    if (State.variables.oamelSkillActive) {
        moneyGain = Math.floor(moneyGain * (1 + State.variables.oamelSkillBonus / 100));
    }
    moneyGain += State.variables.meifeiWageBonus || 0;
    
    addJobExp(job, 20);
    State.variables.money += moneyGain;
    addMinutes(60);
    return `你忙碌了一小时，赚了${moneyGain}金币。`;
};

window.workWithLeiDe = function(job) {
    var wageVar = job === "waiter" ? "waiterWage" : job === "cleric" ? "clericWage" : job === "blacksmith" ? "blacksmithWage" : job === "butler" ? "butlerWage" : "laborerWage";
    var wage = State.variables[wageVar];
    if (State.variables.oamelSkillActive) {
        wage = Math.floor(wage * (1 + State.variables.oamelSkillBonus / 100));
    }
    wage += State.variables.meifeiWageBonus || 0;
    
    State.variables.money += wage;
    addJobExp(job, 20);
    
    var leiDeWage = addInitialNameJobExp(job, 20);
    var share = Math.floor(leiDeWage / 2);
    State.variables.initialNameSavings += leiDeWage;
    State.variables.money += share;
    State.variables.initialNameSavings -= share;
    addAffection("initialName", 3);
    
    var jobName = job === "laborer" ? "港口杂工" : job === "waiter" ? "服务员" : job === "cleric" ? "见习教士" : job === "blacksmith" ? "铁匠学徒" : "侍从";
    return `你和莱德一起做${jobName}一小时，你赚了${wage}金币，莱德赚了${leiDeWage}金币，分给你${share}金币。`;
};

window.doWorkWithEvent = function(job, withLeiDe) {
    var wageVar = job === "waiter" ? "waiterWage" : job === "cleric" ? "clericWage" : job === "blacksmith" ? "blacksmithWage" : job === "butler" ? "butlerWage" : "laborerWage";
    var moneyGain = State.variables[wageVar];
    if (State.variables.oamelSkillActive) {
        moneyGain = Math.floor(moneyGain * (1 + State.variables.oamelSkillBonus / 100));
    }
    moneyGain += State.variables.meifeiWageBonus || 0;
    
    addJobExp(job, 20);
    State.variables.money += moneyGain;
    addMinutes(60);
    
    var msg = `你忙碌了一小时，赚了${moneyGain}金币。`;
    
    if (withLeiDe && job !== "butler") {
        var leiDeWage = addInitialNameJobExp(job, 20);
        var share = Math.floor(leiDeWage / 2);
        State.variables.initialNameSavings += leiDeWage;
        State.variables.money += share;
        State.variables.initialNameSavings -= share;
        msg += `<br>莱德也和你一起工作，他赚了${leiDeWage}金币，分给你${share}金币。`;
        addAffection("initialName", 3);
    }
    
    // 随机事件（简化版）
    if (Math.random() < 0.8) {
        var events = {
            waiter: ["一位常客认出了你，多给了小费。", "客人嫌你上菜慢，但没发脾气。", "一个神秘人打听消息，你装作没听见。"],
            cleric: ["一位富商捐了一大笔钱，分给你一些。", "一个醉汉闯进教堂，你劝走了他。", "一个孩子迷路了，你帮他找到妈妈。"],
            blacksmith: ["一个冒险者对你打的剑赞不绝口。", "一个贵族嫌你手艺差，但没计较。", "一个神秘人拿发光矿石要打造武器，你婉拒了。"],
            laborer: ["一个货主看你搬货利索，多给了小费。", "一个工人诬陷你弄倒箱子，黑胡子帮你解围。", "一个水手问你要不要搬特殊货，你拒绝了。"],
            butler: ["一位贵族夫人夸你服务周到，多给了小费。", "你打翻了酒杯，罗斯巴特少爷皱眉但没扣你工资。", "一位商人向你打听罗斯巴特家族的消息，你巧妙回避了。", "罗斯巴特少爷亲自教你怎么倒酒，说“别丢我的脸”。"]
        };
        var eventList = events[job] || ["什么也没发生。"];
        var eventText = eventList[Math.floor(Math.random() * eventList.length)];
        msg += `<br><div class="event-box">✨ ${eventText}</div>`;
    }
    return msg;
};

// ==================== NPC好感度 ====================
window.getNpcLevel = function(val) {
    if (val < 15) return 0;
    if (val < 30) return 1;
    if (val < 50) return 2;
    if (val < 70) return 3;
    if (val < 90) return 4;
    return 5;
};

window.giveFurniture = function(npc) {
    var furniture = "";
    switch(npc) {
        case "sinchi": furniture = "furnitureCoffee"; break;
        case "clarice": furniture = "furnitureBible"; break;
        case "macnana": furniture = "furnitureDummy"; break;
        case "blackbeard": furniture = "furnitureSeagull"; break;
        default: return;
    }
    State.variables[furniture] = true;
    addDateLog(npc === "sinchi" ? "辛奇" : npc === "clarice" ? "克丽丝" : npc === "macnana" ? "麦拿拿" : "黑胡子", "赠送家具", `送来了${furniture === "furnitureCoffee" ? "咖啡机" : furniture === "furnitureBible" ? "圣典" : furniture === "furnitureDummy" ? "训练铁人" : "小海鸥装饰"}。`);
    showNotification(`你收到了${npc === "sinchi" ? "辛奇" : npc === "clarice" ? "克丽丝" : npc === "macnana" ? "麦拿拿" : "黑胡子"}送的礼物！`);
};

window.addNpcAffection = function(npc, amount) {
    var varName = "npc" + npc.charAt(0).toUpperCase() + npc.slice(1);
    var current = State.variables[varName] || 0;
    var newVal = current + amount;
    var oldLevel = getNpcLevel(current);
    var newLevel = getNpcLevel(newVal);
    State.variables[varName] = newVal;
    if (newLevel > oldLevel) {
        var npcName = npc === "sinchi" ? "辛奇" : npc === "clarice" ? "克丽丝" : npc === "macnana" ? "麦拿拿" : "黑胡子";
        var logMsg = "";
        switch(npc) {
            case "sinchi":
                logMsg = `和辛奇的关系加深了。他塞给你一杯酒：“好好干。”`;
                break;
            case "clarice":
                logMsg = `和克丽丝的关系加深了。她微笑着说：“愿太阳神保佑你。”`;
                break;
            case "macnana":
                logMsg = `和麦拿拿的关系加深了。他拍着你肩膀：“小子，有前途！”`;
                break;
            case "blackbeard":
                logMsg = `和黑胡子的关系加深了。他咧嘴一笑：“以后跟我混。”`;
                break;
        }
        addDateLog(npcName, "好感提升", logMsg);
        showNotification(logMsg);
        if (newLevel === 1 && oldLevel === 0) giveFurniture(npc);
    }
};

// ==================== 莱德在家判断与状态 ====================
window.isLeiDeHome = function() {
    if (!State.variables.initialNameAtHome) return false;
    var hour = State.variables.hour;
    return (hour >= 19 || hour < 6) || (hour >= 11 && hour < 13);
};

window.getLeiDeStatusDesc = function() {
    var hour = State.variables.hour;
    var candles = State.variables.candles;
    var sleepTogether = State.variables.initialNameSleepTogether;
    var name = State.variables.initialName;
    if (hour >= 22 || hour < 6) {
        if (sleepTogether) {
            return `<p>${name} 已经睡着了。他侧躺着，黑发散在枕上，呼吸平稳。月光从窗帘缝隙透进来，勾勒出他安静的轮廓。</p>`;
        } else {
            return `<p>${name} 已经躺在沙发上睡着了。他蜷缩着，呼吸均匀，睡得很沉。</p>`;
        }
    }
    if (hour >= 21 && hour < 22) {
        var light = candles > 0 ? "蜡烛的光" : "窗外的月光";
        return `<p>${name} 靠在${sleepTogether ? "床头" : "沙发上"}，借着${light}翻阅一本厚重的魔法书。${candles > 0 ? "烛火在他脸上投下跳动的影子，" : "光线很暗，但他似乎并不在意，"}他看得专注，连你进来都没察觉。</p>`;
    }
    return `<p>${name} 坐在桌边，面前摊着厚厚的魔法书籍和论文草稿。他眉头微蹙，笔尖在纸上沙沙作响，偶尔停下来沉思。</p>`;
};

// ==================== 话题系统 ====================
window.topicData = {
    "港口": { name: "港口", desc: "港口的渔船和海风", interest: { leiDe: true, k: false }, affection: 10 },
    "主城区": { name: "主城区", desc: "主城区的书店和广场", interest: { leiDe: true, k: true }, affection: 10 },
    "花街": { name: "花街", desc: "花街的霓虹灯", interest: { leiDe: false, k: false }, affection: 10 },
    "花园小镇": { name: "花园小镇", desc: "花园小镇的野花田", interest: { leiDe: false, k: true }, affection: 10 },
    "教堂": { name: "教堂", desc: "教堂的彩色玻璃", interest: { leiDe: false, k: true }, affection: 10 },
    "铁匠铺": { name: "铁匠铺", desc: "铁匠铺的炉火", interest: { leiDe: true, k: false }, affection: 10 },
    "酒馆": { name: "酒馆", desc: "酒馆里K调的酒", interest: { leiDe: false, k: true }, affection: 10 },
    "服务员": { name: "服务员", desc: "在酒馆端盘子的经历", interest: { leiDe: false, k: true }, affection: 10 },
    "教士": { name: "教士", desc: "在教堂整理经书的经历", interest: { leiDe: false, k: true }, affection: 10 },
    "铁匠": { name: "铁匠学徒", desc: "打铁的经历", interest: { leiDe: true, k: false }, affection: 10 },
    "杂工": { name: "港口杂工", desc: "搬货的经历", interest: { leiDe: true, k: false }, affection: 10 },
    "莱恩": { name: "莱恩", desc: "在花园小镇遇到的受伤青年", interest: { leiDe: false, k: false }, affection: 10 },
    "小奥": { name: "小奥", desc: "花街的调酒师", interest: { leiDe: false, k: false }, affection: 10 },
    "小猫": { name: "小猫", desc: "在酒馆收养的小猫", interest: { leiDe: true, k: true }, affection: 10 }
};

window.topicDialogues = {
    "小猫": {
        interest: { leiDe: true, k: true },
        start: {
            text: function(name) { return `“你很喜欢那只小猫？”${name} 看着你。`; },
            options: [
                { text: "“嗯，它很可爱。”", next: "node_like" },
                { text: "“还好，只是觉得可怜。”", next: "node_pity" }
            ]
        },
        node_like: {
            text: function(name) { return `${name} 点点头：“确实。它很黏你。”`; },
            options: [
                { text: "“你要不要也养一只？”", next: "node_adopt" },
                { text: "“它更喜欢你。”", next: "node_end" }
            ]
        },
        node_pity: {
            text: function(name) { return `${name} 沉默了一下：“...以前没人管它。”`; },
            options: [
                { text: "“现在有了。”", next: "node_end" },
                { text: "“它很坚强。”", next: "node_end" }
            ]
        },
        node_adopt: {
            text: function(name) { return `${name} 嘴角动了一下：“...不了。它已经有家了。”`; },
            next: "end"
        },
        node_end: {
            text: function(name) { return `${name} 没再说话，但你感觉他心情不错。`; },
            next: "end"
        }
    },
    "铁匠铺": {
        interest: { leiDe: true, k: false },
        start: {
            text: function(name) { return `“铁匠铺的炉火很旺。”你随口说。${name} 看了一眼你：“...你常去？”`; },
            options: [
                { text: "“偶尔去打打下手。”", next: "node_work" },
                { text: "“只是路过。”", next: "node_pass" }
            ]
        },
        node_work: {
            text: function(name) { return `${name} 难得问了一句：“学到什么了？”`; },
            options: [
                { text: "“打铁比想象中难。”", next: "node_hard" },
                { text: "“麦拿拿教了不少。”", next: "node_teacher" }
            ]
        },
        node_hard: {
            text: function(name) { return `${name} 点点头：“慢慢来。”`; },
            next: "end"
        },
        node_teacher: {
            text: function(name) { return `${name} 微微点头：“麦拿拿...是矮人那个？”`; },
            options: [
                { text: "“你认识他？”", next: "node_know" },
                { text: "“他很厉害。”", next: "node_end" }
            ]
        },
        node_know: {
            text: function(name) { return `${name} 没回答，只说：“...有机会去学学。”`; },
            next: "end"
        },
        node_pass: {
            text: function(name) { return `${name} “嗯”了一声，没再接话。`; },
            next: "end"
        }
    }
};

window.addTopic = function(topicId, isFirstTime) {
    var arr = State.variables.recentTopics;
    var idx = arr.indexOf(topicId);
    if (idx !== -1) arr.splice(idx, 1);
    arr.unshift(topicId);
    if (arr.length > 10) arr.pop();
    
    if (isFirstTime && window.topicDialogues && window.topicDialogues[topicId]) {
        var unlocked = State.variables.unlockedSpecialTopics;
        if (!unlocked.includes(topicId)) unlocked.push(topicId);
    }
};

// ==================== 读书函数 ====================
window.readBook = function(book) {
    var bookVar = book + "BookReadCount";
    var firstRewardVar = book + "FirstReward";
    var addExpFunc = (book === "manner" ? addMannerExp : addHistoryExp);
    var rewardStat = (book === "manner" ? "ML" : "LG");
    
    var count = State.variables[bookVar];
    count = (count || 0) + 1;
    State.variables[bookVar] = count;
    
    addExpFunc(20);
    
    if (count >= 4 && !State.variables[firstRewardVar]) {
        State.variables[firstRewardVar] = true;
        State.variables[rewardStat] += 1;
        addDateLog(book === "manner" ? "礼仪书" : (book === "history" ? "历史书" : "奥丝米娅史"), "首次读完", `${book === "manner" ? "《贵族礼仪入门》" : (book === "history" ? "《日轮王国贵族名录》" : "《奥丝米娅时代的历史》")} 读完，${book === "manner" ? "魅力" : "灵感"}+1。`);
        showNotification(`你读完了《${book === "manner" ? "贵族礼仪入门" : (book === "history" ? "日轮王国贵族名录" : "奥丝米娅时代的历史")}》，${book === "manner" ? "魅力" : "灵感"}+1！`);
    }
    
    var texts = {
        manner: ["“问候他人时，目光应落在对方眉间，既不卑不亢，又显尊重……”",
                 "“用餐时，刀叉由外向内使用，面包需手撕成小块，切勿直接咬……”",
                 "“进入房间前，应先敲门三下，得到允许后方可入内……”",
                 "“真正的贵族风度，不在于出身，而在于让他人感到舒适。”"],
        history: ["“瓦勒姆公爵家，封地北境，以暗魔法与太阳神契约闻名……”",
                  "“罗斯巴特家族，前朝皇族后裔，现居花街，家主奥梅尔·罗斯巴特……”",
                  "“辛奇家族，商业世家，经营酒馆与贸易……”",
                  "“血脉终会淡去，但荣耀需自己争取。”"],
        osmia: ["“奥丝米娅国王登基时年仅十六，却以铁腕整合了分裂的贵族……”",
                "“他大兴土木，修建图书馆与剧院，鼓励学者与艺术家……”",
                "“晚年却沉溺魔法研究，将政务交由心腹，最终导致皇权旁落……”",
                "“历史没有对错，只有选择。”"]
    };
    var idx = (count - 1) % 4;
    return texts[book][idx];
};

// ==================== 约会数据 ====================
window.dateScenes = {
    leiDe: {
        "十字路口": {
            desc: function(name) { return `你们并肩走在街上，夕阳把影子拉得很长。${name}走在你旁边，不远不近。`; },
            options: [
                { text: "“以后多陪我。”", affection: 8, reply: "他沉默了一下：“...好。”" },
                { text: "“谢谢你愿意出来。”", affection: 5, reply: "他脚步停了一下：“...谢什么。”" },
                { text: "“和你走在一起，好像时间变慢了。”", affection: 10, reply: "他沉默了很久，然后轻轻说：“...嗯。”" }
            ]
        },
        "主城区": {
            desc: function(name) { return `主城区的街道比平时热闹。${name}跟在你身后，目光扫过两旁的店铺。`; },
            options: [
                { text: "“买本书吧。”", affection: 8, reply: "他摇头：“看过了，记住了。”" },
                { text: "“下次我帮你借。”", affection: 6, reply: "他看了你一眼：“...图书馆能借？”" },
                { text: "“你喜欢看什么书？”", affection: 10, reply: "他沉默了一会儿：“什么都看。最近在看魔法理论。”" }
            ]
        },
        "港口": {
            desc: function(name) { return `海风很大，${name}的头发被吹乱了。他伸手拨了一下，动作有点笨拙。`; },
            options: [
                { text: "“以后常来。”", affection: 8, reply: "他转头看你：“...好。”" },
                { text: "“谢谢你陪我看海。”", affection: 10, reply: "“不用谢。”他低声说，“...我也想看。”" },
                { text: "“海和你，都很安静。”", affection: 12, reply: "他愣了一下，然后低下头：“...心跳的时候。”" }
            ]
        },
        "咖啡厅": {
            desc: function(name) { return `你们坐在靠窗的位置，${name}盯着杯子里的咖啡，像在研究什么。`; },
            options: [
                { text: "“下次给你多点糖。”", affection: 6, reply: "他抬头看你：“...嗯。”" },
                { text: "“原来你喜欢甜的。”", affection: 10, reply: "他没说话，但耳朵红了。" },
                { text: "“以后常来？”", affection: 8, reply: "他放下杯子，看着窗外：“...嗯。”" }
            ]
        },
        "在家": {
            desc: function(name, candles) { return `家里很安静。${name}坐在桌边，面前摊着书，但好像没在看。`; },
            options: [
                { text: "“今天想做什么？”", affection: 10, reply: "他想了想：“...坐着。”" },
                { text: "“要不要听我弹琴？”", affection: 8, reply: "他愣了一下：“你会？”" },
                { text: "“想看看你练剑。”", affection: 12, reply: "他犹豫了一下，拿起靠在墙边的剑。" }
            ]
        }
    },
    k: {
        "港口": {
            desc: function(name) { return `你们并肩走在码头上，海风把${name}的长发吹得微微飘起。`; },
            options: [
                { text: "“偶尔来，心情不好的时候。”", affection: 10, reply: "K愣了一下，然后轻轻笑了：“那现在呢？心情好吗？”" },
                { text: "“第一次觉得海这么好看。”", affection: 12, reply: "“因为有人一起看吧。”K说完，自己先愣了一下。" },
                { text: "“不常来。以后可以多来。”", affection: 8, reply: "“以后？”K重复了一遍，眼睛亮亮的，“那...下次还一起？”" }
            ]
        },
        "花园": {
            desc: function(name) { return `花园小镇比往日安静。${name}走在前面，忽然蹲下来：“上次种的，发芽了。”`; },
            options: [
                { text: "“因为这里有你喜欢的事？”", affection: 12, reply: "K想了想：“...因为有你。”" },
                { text: "“因为你自由了。”", affection: 10, reply: "K沉默了一下，然后轻轻点头：“嗯。自由了。”" },
                { text: "“因为有人陪你一起看？”", affection: 15, reply: "K转头看你，眼神亮亮的：“...嗯。”" }
            ]
        },
        "咖啡店": {
            desc: function(name) { return `你们坐在靠窗的位置，阳光透过玻璃洒在桌面上。${name}捧着杯子，小口小口地喝：“还是热的。”`; },
            options: [
                { text: "“喜欢热的？”", affection: 10, reply: "“嗯。”她点头，“热的比较...有人的味道。”" },
                { text: "“以后都给你倒热的。”", affection: 12, reply: "K愣了一下，然后笑了：“那说好了。”" },
                { text: "“你以前过得很苦吧。”", affection: 15, reply: "K沉默了一会儿：“不算苦。只是...没什么味道。”" }
            ]
        },
        "漫步": {
            desc: function(name) { return `你们没有目的地，只是并肩走着。${name}的脚步很轻，像怕惊扰了什么。`; },
            options: [
                { text: "“那就一直走下去。”", affection: 15, reply: "她愣了一下，然后笑得很开心：“好。一直走下去。”" },
                { text: "“你喜欢散步？”", affection: 10, reply: "“喜欢。因为可以看很多东西。”她指着路边。" },
                { text: "“和你走在一起，去哪都好。”", affection: 12, reply: "K的脚步停了一下。她转头看你，眼睛亮亮的：“...真的？”" }
            ]
        }
    }
};

// ==================== 晚宴数据 ====================
window.banquetThemes = {
    masquerade: {
        name: "假面舞会",
        desc: "大厅被装点成神秘的夜空，到处都是戴着半脸面具的贵族。面具下只露出一双双或审视、或好奇的眼睛。空气中飘着香槟和玫瑰的气息，乐师在角落演奏着轻快的圆舞曲。",
        outfits: {
            black: { name: "黑色礼服", matchDesc: "低调而神秘，很符合今晚的气氛。", failDesc: "太朴素了，在这种场合显得格格不入。", matchBonus: 100, failBonus: 50 },
            gold: { name: "金色礼服", matchDesc: "华丽耀眼，但你似乎抢了主人的风头。", failDesc: "过于张扬，不少贵族投来异样的目光。", matchBonus: 100, failBonus: 50 },
            white: { name: "白色礼服", matchDesc: "纯洁典雅，与面具形成微妙反差。", failDesc: "太素了，在假面舞会上毫无存在感。", matchBonus: 100, failBonus: 50 },
            hunt: { name: "猎装", matchDesc: "英气勃发，但你更像来狩猎的。", failDesc: "格格不入，你觉得自己走错了地方。", matchBonus: 100, failBonus: 50 }
        },
        events: [
            { name: "帮小奥招待客人", condition: "State.variables.ML >= 8 and State.variables.mannerLevel >= 2", successText: "你端着酒走过去，自然地加入对话。你引用了几句礼仪课上学到的祝酒词，几位客人对你刮目相看。罗斯巴特少爷难得对你露出赞许的神色。", successEffect: { tip: 150, oamel: 5 }, failText: "你笨拙地插话，不小心说错了某个贵族的姓氏。气氛尴尬了一瞬，罗斯巴特少爷替你解围：“他新来的，各位别介意。”等客人走后，他低声说：“别添乱。”", failEffect: { tip: -50 } },
            { name: "讨好贵族", condition: "State.variables.historyLevel >= 3 and State.variables.mannerLevel >= 2", successText: "你找到几位正在谈论艺术的中年贵族，从画作聊到音乐，又巧妙地引到奥丝米娅时代的宫廷轶事。他们听得津津有味，临别时一人塞给你一张金票。", successEffect: { tip: 300, oamel: 3 }, midText: "你试着和一位子爵搭话，虽然说得磕磕绊绊，但他还是给了你一点小费。", midEffect: { tip: 100 }, failText: "你结结巴巴地自我介绍，对方敷衍地点点头就转身离开。", failEffect: {} },
            { name: "观察学习", condition: null, successText: "你安静地坐在角落，观察贵族们的言谈举止。罗斯巴特少爷偶尔路过，给你带一杯酒：“学学怎么站，怎么笑。下次别穿错衣服。”", successEffect: { mannerExp: "random(30,50)" }, failText: "", failEffect: {} }
        ]
    },
    revelry: {
        name: "纵情声色",
        desc: "今晚的妖精的邀请格外喧嚣。红丝绒沙发上躺着慵懒的贵妇人，水晶吊灯下有人划拳赌酒，角落里传出暧昧的窃窃私语。空气中混着浓烈的香水味和葡萄酒气。",
        outfits: {
            gold: { name: "金色礼服", matchDesc: "耀眼夺目，你成了众人焦点。", failDesc: "过于张扬，反而显得轻浮。", matchBonus: 100, failBonus: 50 },
            black: { name: "黑色礼服", matchDesc: "沉稳低调，与这喧嚣格格不入。", failDesc: "太沉闷了，没人注意你。", matchBonus: 100, failBonus: 50 },
            white: { name: "白色礼服", matchDesc: "清新淡雅，像一朵白莲花。", failDesc: "太素净，被酒色淹没。", matchBonus: 100, failBonus: 50 },
            hunt: { name: "猎装", matchDesc: "英气勃勃，女宾们多看你几眼。", failDesc: "与酒色无关，你像个局外人。", matchBonus: 100, failBonus: 50 }
        },
        events: [
            { name: "帮小奥招待客人", condition: "State.variables.ML >= 8 and State.variables.mannerLevel >= 2", successText: "你端着酒走过去，自然地加入对话。你引用了几句礼仪课上学到的祝酒词，几位客人对你刮目相看。罗斯巴特少爷难得对你露出赞许的神色。", successEffect: { tip: 150, oamel: 5 }, failText: "你笨拙地插话，不小心说错了某个贵族的姓氏。气氛尴尬了一瞬，罗斯巴特少爷替你解围：“他新来的，各位别介意。”等客人走后，他低声说：“别添乱。”", failEffect: { tip: -50 } },
            { name: "讨好贵族", condition: "State.variables.ML >= 6", successText: "你试着和一位子爵搭话，虽然说得磕磕绊绊，但他还是给了你一点小费。", successEffect: { tip: 100 }, failText: "你结结巴巴地自我介绍，对方敷衍地点点头就转身离开。", failEffect: {} },
            { name: "观察学习", condition: null, successText: "你安静地坐在角落，观察贵族们的言谈举止。罗斯巴特少爷偶尔路过，给你带一杯酒：“学学怎么站，怎么笑。下次别穿错衣服。”", successEffect: { mannerExp: "random(30,50)" }, failText: "", failEffect: {} }
        ]
    },
    flower: {
        name: "赏花宴",
        desc: "大厅被鲜花装点得如同春日花园。玫瑰、百合、雏菊簇拥着每一张桌子，连吊灯上都缠绕着藤蔓。几位贵族小姐正在比较谁收到的花束更名贵。",
        outfits: {
            white: { name: "白色礼服", matchDesc: "与花相映，你像画中走出来的人。", failDesc: "太素了，被花海淹没。", matchBonus: 100, failBonus: 50 },
            black: { name: "黑色礼服", matchDesc: "沉稳大气，与花形成反差。", failDesc: "太暗了，和花不搭。", matchBonus: 100, failBonus: 50 },
            gold: { name: "金色礼服", matchDesc: "华丽耀眼，比花还夺目。", failDesc: "太张扬，抢了花的风头。", matchBonus: 100, failBonus: 50 },
            hunt: { name: "猎装", matchDesc: "英气勃发，与花形成奇妙对比。", failDesc: "格格不入，你像个闯入花园的猎人。", matchBonus: 100, failBonus: 50 }
        },
        events: [
            { name: "帮小奥招待客人", condition: "State.variables.ML >= 8 and State.variables.mannerLevel >= 2", successText: "你端着酒走过去，自然地加入对话。你引用了几句礼仪课上学到的祝酒词，几位客人对你刮目相看。罗斯巴特少爷难得对你露出赞许的神色。", successEffect: { tip: 150, oamel: 5 }, failText: "你笨拙地插话，不小心说错了某个贵族的姓氏。气氛尴尬了一瞬，罗斯巴特少爷替你解围：“他新来的，各位别介意。”等客人走后，他低声说：“别添乱。”", failEffect: { tip: -50 } },
            { name: "讨好贵族", condition: "State.variables.ML >= 8", successText: "你找到几位正在谈论花卉的夫人，你对花语的了解让她们刮目相看。", successEffect: { tip: 200, oamel: 3 }, failText: "你笨拙地插话，夫人礼貌地笑笑就走开了。", failEffect: {} },
            { name: "观察学习", condition: null, successText: "你安静地坐在角落，观察贵族们的言谈举止。罗斯巴特少爷偶尔路过，给你带一杯酒：“学学怎么站，怎么笑。下次别穿错衣服。”", successEffect: { mannerExp: "random(30,50)" }, failText: "", failEffect: {} }
        ]
    },
    hunt: {
        name: "狩猎夜",
        desc: "墙上挂着鹿头标本和猎枪，男宾们穿着猎装，女宾们则戴着羽毛头饰。角落里摆着棋牌桌，有人在下注赌明天的猎场谁能打到最多的野兔。",
        outfits: {
            hunt: { name: "猎装", matchDesc: "英姿飒爽，你像经验丰富的猎人。", failDesc: "猎装是基本，但你穿得不够利落。", matchBonus: 100, failBonus: 50 },
            black: { name: "黑色礼服", matchDesc: "沉稳大气，与狩猎主题意外契合。", failDesc: "太正式了，和周围格格不入。", matchBonus: 100, failBonus: 50 },
            gold: { name: "金色礼服", matchDesc: "华丽耀眼，像个来打猎的贵族。", failDesc: "太张扬，猎物都被你吓跑了。", matchBonus: 100, failBonus: 50 },
            white: { name: "白色礼服", matchDesc: "纯洁典雅，像林中的精灵。", failDesc: "太显眼，不适合狩猎。", matchBonus: 100, failBonus: 50 }
        },
        events: [
            { name: "帮小奥招待客人", condition: "State.variables.ML >= 8 and State.variables.mannerLevel >= 2", successText: "你端着酒走过去，自然地加入对话。你引用了几句礼仪课上学到的祝酒词，几位客人对你刮目相看。罗斯巴特少爷难得对你露出赞许的神色。", successEffect: { tip: 150, oamel: 5 }, failText: "你笨拙地插话，不小心说错了某个贵族的姓氏。气氛尴尬了一瞬，罗斯巴特少爷替你解围：“他新来的，各位别介意。”等客人走后，他低声说：“别添乱。”", failEffect: { tip: -50 } },
            { name: "讨好贵族", condition: "State.variables.LL >= 6", successText: "你和几位男宾聊起打猎技巧，他们很感兴趣。", successEffect: { tip: 150, oamel: 3 }, failText: "你笨拙地插话，他们礼貌地笑笑就走开了。", failEffect: {} },
            { name: "观察学习", condition: null, successText: "你安静地坐在角落，观察贵族们的言谈举止。罗斯巴特少爷偶尔路过，给你带一杯酒：“学学怎么站，怎么笑。下次别穿错衣服。”", successEffect: { mannerExp: "random(30,50)" }, failText: "", failEffect: {} }
        ]
    }
};