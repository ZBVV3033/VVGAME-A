-- ============================================================================
-- TownPassages_Events.lua - 特殊遭遇 + 治安事件 + 切磋段落
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local BattleSystem = require("systems.BattleSystem")
local U = require("passages.TownNPCUtils")

local handlers = {}

-- ========== 特殊遭遇段落 ==========

handlers["小镇_达里奥合唱"] = U.event { var = "npcDario", aff = 5, time = 15, loc = "十字路口",
    text = "达里奥抱着吉他坐在喷泉边的台阶上，拍了拍身边的位置示意你坐下。\n\n"
        .. "「这首歌叫《码头的月亮》，是我上周刚写的。」\n"
        .. "他拨了几下弦，旋律悠扬地飘荡在傍晚的街道上。\n\n"
        .. "「副歌部分，你跟着我唱——\n"
        .. "啦啦啦~月亮挂在桅杆上，海浪轻轻拍着岸~」\n\n"
        .. "你试着跟上他的节奏。一开始有些跑调，但达里奥毫不在意，反而笑着鼓励你：\n"
        .. "「对对对，就是这个感觉！放松点，音乐不需要完美！」\n\n"
        .. "渐渐地，你的声音和他的吉他融为一体。\n"
        .. "路过的行人纷纷驻足，有人开始鼓掌。\n\n"
        .. "唱完最后一个音符，达里奥满意地拍了拍你的肩膀：\n"
        .. "「嘿，你有天赋！下次我写了新歌再找你！」\n\n"
        .. "（达里奥 好感+5）",
}

handlers["小镇_费利克斯教烤面包"] = U.event { var = "npcFelix", aff = 5, time = 20, loc = "商业区",
    extraAction = function() GameState.modStat("satiety", 8) end,
    text = "费利克斯的面包店后厨热气腾腾。他给你套上一条围裙，递过来一团面粉。\n\n"
        .. "「做面包最重要的是揉面。来，像这样——」\n"
        .. "他双手用力把面团按下去，折起来，再按下去。动作行云流水。\n\n"
        .. "你笨手笨脚地模仿他，面团在你手里像个不听话的孩子。\n"
        .. "费利克斯哈哈大笑：「别急，面团能感觉到你的心情。心急的话，烤出来的面包也会硬邦邦的。」\n\n"
        .. "在他耐心的指导下，你终于揉出了一个像样的形状。\n"
        .. "等面团发酵的间隙，费利克斯给你倒了一杯热牛奶。\n\n"
        .. "「我爷爷教我的——做面包就像做人，急不得。」\n"
        .. "他看着窗外，笑容变得温暖：「这家店传了三代了。我会一直守着的。」\n\n"
        .. "半小时后，你亲手做的面包出炉了。虽然形状歪歪扭扭，但味道出乎意料的好。\n"
        .. "费利克斯切了一大块递给你：「自己做的，特别香吧？」\n\n"
        .. "（费利克斯 好感+5 饱食+8）",
}

handlers["小镇_薇拉魔法"] = U.event { var = "npcGrandmaVera", aff = 5, time = 10, loc = "主城区",
    text = "薇拉奶奶把你拉到教堂广场角落里一棵大树下，确认四下无人后，摊开手掌。\n\n"
        .. "她的掌心里凭空出现了一个小小的光球，像一颗微型的星星。\n"
        .. "光球缓缓升起，在你眼前分裂成数只光蝶，翩翩起舞。\n\n"
        .. "「漂亮吧？」薇拉奶奶的眼睛亮晶晶的，像个得意的小女孩。\n"
        .. "「这是光纹术。很久以前，这可是每个学徒都会的基础魔法呢。」\n\n"
        .. "光蝶在你的头顶盘旋了一圈，然后慢慢消散成细碎的光点。\n\n"
        .. "「现在会这个的人不多了。」她收回手，目光有些黯然。\n"
        .. "「时代变了……不过美丽的东西，总该有人记得。」\n\n"
        .. "她拍拍你的手背：「好了，我的小把戏看完了。去忙你的吧。」\n\n"
        .. "（薇拉奶奶 好感+5）",
}

handlers["小镇_黑帮少主天台"] = function()
    local S = GameState.state
    NPCSystem.addAffection("gangBoss", 5)
    TimeSystem.addMinutes(15)
    return {
        text = "你爬上狭窄的铁梯，推开天台的门。夜风猛地灌了进来。\n\n"
            .. "黑帮少主靠在天台边缘的矮墙上，手里的烟明灭不定。\n"
            .. "他听到脚步声，回过头，先是一惊，随即露出一个无所谓的表情。\n\n"
            .. "「怎么，你也喜欢爬这么高？」\n\n"
            .. "你走到他身边，才发现从这里能看到整个小镇的夜景。\n"
            .. "灯火点点，像撒了一把碎金。远处的海面映着月光。\n\n"
            .. "「我每次心烦的时候就来这。」他吐出一口烟，「站得高了，那些烦心事就显得小了。」\n\n"
            .. "沉默了一会儿，他忽然说：\n"
            .. "「你知道吗，我本来不想当什么少主。」\n"
            .. "他的声音很轻，差点被风吹散。\n"
            .. "「小时候想当厨师来着——别笑！」\n\n"
            .. "他看到你嘴角的弧度，威胁地指了指你：\n"
            .. "「这件事你要是跟任何人说，我就……」\n"
            .. "他说不下去了，自己先笑了出来。\n\n"
            .. "这个夜晚，你看到了他不为人知的一面。\n\n"
            .. "（黑帮少主 好感+5）",
        choices = {
            {
                text = "继续",
                target = "花街",
            },
        },
    }
end

handlers["小镇_老尤金海湾"] = U.event { var = "npcOldYugen", aff = 5, time = 15, loc = "港口",
    text = "老尤金带你穿过码头边一条隐蔽的小路，拨开垂下来的藤蔓。\n\n"
        .. "眼前豁然开朗——一个小小的海湾，三面被礁石环绕。\n"
        .. "夕阳将海面染成橘红色，浪花轻轻拍打着沙滩。\n\n"
        .. "「这是我年轻时候发现的地方。」老尤金坐在一块大石头上，\n"
        .. "「整个镇子知道这里的人，三个手指头数得过来。」\n\n"
        .. "他从怀里掏出一个旧酒壶，晃了晃：「来一口？」\n\n"
        .. "不等你回答，他自己先喝了一大口，然后望着远方。\n"
        .. "「我年轻时候是船长你知道吧？最远到过东边的冰洋。\n"
        .. "那里的冰山啊——比教堂的塔尖还高。蓝得像宝石。」\n\n"
        .. "他的声音变得柔和：「最后一次出航回来那天，\n"
        .. "我老婆就站在那块礁石上等我。风吹着她的裙子。\n"
        .. "我跟自己说，以后哪也不去了。」\n\n"
        .. "海鸥从头顶飞过，叫声在海湾里回荡。\n"
        .. "「现在她走了，但这个海湾还在。」老尤金笑了笑，\n"
        .. "「我把它分享给你。以后想静静的时候，就来这儿坐坐。」\n\n"
        .. "（老尤金 好感+5）",
}

handlers["小镇_莉莉安插花"] = U.event { var = "npcLillian", aff = 5, time = 15, loc = "花园小镇",
    text = "莉莉安在花丛边铺了一块素色的布，上面摆满了刚采的鲜花。\n\n"
        .. "「插花讲究的是意境。」她拿起一枝蓝色的鸢尾，斜斜地插进花瓶。\n"
        .. "「不是越多越好——有时候留白，反而更有韵味。」\n\n"
        .. "她递给你几枝花，让你试试。\n"
        .. "你小心翼翼地把一朵白色雏菊插进去，歪歪斜斜的。\n\n"
        .. "莉莉安没有笑话你，只是轻轻调整了一下角度：\n"
        .. "「你看，这样它就像在仰头看天空了。花和人一样，需要找到舒服的姿态。」\n\n"
        .. "在她的引导下，你慢慢找到了感觉。\n"
        .. "最终完成的花束虽然简单，但有一种朴素的美感。\n\n"
        .. "「不错！第一次能做成这样很有天赋了。」\n"
        .. "她从自己的花堆里挑了一朵最漂亮的粉色玫瑰，别在你的胸前。\n"
        .. "「送你的。今天的谢礼。」\n\n"
        .. "微风拂过花丛，花瓣纷纷扬扬地飘落，像一场温柔的雨。\n\n"
        .. "（莉莉安 好感+5）",
}

-- ========== 城内治安事件 & 切磋 ==========

handlers["城内治安_小偷"] = U.battle { enemy = "小偷", returnTo = "十字路口",
    fleeText = "算了，不管了",
    text = "你拦住了那个鬼鬼祟祟的身影。\n\n"
        .. "那是个瘦小的家伙，手里还攥着一个绣花钱袋。\n"
        .. "他的眼珠子滴溜溜地转，显然在盘算逃跑路线。\n\n"
        .. "「让开！不关你的事！」他恶狠狠地说。\n\n"
        .. "看来不打一架是走不了了。",
}

handlers["城内治安_醉汉"] = U.battle { enemy = "醉汉", returnTo = "商业区",
    fleeText = "绕道走开",
    text = "你挡在了醉汉面前。\n\n"
        .. "他身材魁梧，满脸通红，浑身酒气熏天。\n"
        .. "看到你拦路，他一把推开旁边的人，晃晃悠悠地朝你走来。\n\n"
        .. "「你……你谁啊？让……让开！」\n他挥舞着蒲扇大的拳头。\n\n"
        .. "好言相劝显然没用了。",
}

handlers["城内治安_走私贩"] = U.battle { enemy = "走私贩", returnTo = "港口",
    fightText = "⚔️ 迎战走私贩！",
    fleeText = "装作没看到，快步离开",
    text = "那个男人快步走到你面前，挡住了你的去路。\n\n"
        .. "他身后还有一个同伙，正在手忙脚乱地收拾地上的货物。\n"
        .. "你瞥了一眼——是几个用油布包裹的可疑包裹。\n\n"
        .. "「你要是识相的，就当什么都没看到。」\n"
        .. "他压低声音，手里已经多了一把匕首。\n\n"
        .. "看来只能硬着头皮上了。",
}

handlers["城内治安_混混"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    return {
        text = "你停下脚步，冷冷地看着为首的那个人。\n\n"
            .. "「怎么，不怕？」他嗤笑一声，朝同伙使了个眼色。\n"
            .. "两个人从巷子两侧围了过来。\n\n"
            .. "「敬酒不吃吃罚酒。」为首的人捏了捏拳头，指节咔咔作响。",
        choices = {
            {
                text = "⚔️ 教训这帮混混！",
                action = function()
                    S.battleSource = "town"
                    S.townBattleReturnTo = "贫民窟"
                    S.townBattleToday = (S.townBattleToday or 0) + 1
                    BattleSystem.startBattleWith({ "街头混混" })
                    BattleSystem.processEnemyTurnsUntilPlayer()
                    return "战斗"
                end,
            },
            {
                text = "交出一些钱（-10金币）",
                action = function()
                    if S.money >= 10 then
                        S.money = S.money - 10
                        GameState.addRecentEvent("在贫民窟被混混勒索了10金币")
                        return "贫民窟"
                    else
                        S.battleSource = "town"
                        S.townBattleReturnTo = "贫民窟"
                        S.townBattleToday = (S.townBattleToday or 0) + 1
                        BattleSystem.startBattleWith({ "街头混混" })
                        BattleSystem.processEnemyTurnsUntilPlayer()
                        return "战斗"
                    end
                end,
            },
        },
    }
end

handlers["城内治安_野狗"] = U.battle { enemy = "野狗", returnTo = "贫民窟",
    fightText = "⚔️ 应战！",
    text = "野狗低伏着身体，向你步步逼近。\n\n"
        .. "它的毛发纠结在一起，肋骨清晰可见。\n"
        .. "这不是普通的流浪狗——长期的饥饿让它变得异常凶悍。\n\n"
        .. "它突然发出一声嘶吼，猛地扑了过来！",
}

handlers["切磋_提议"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    local leiderName = S.initialName or "莱德"
    return {
        text = leiderName .. "停下练剑，用袖子擦了擦额头的汗。\n\n"
            .. "「哟，" .. (S.PNN ~= "" and S.PNN or "你") .. "来了。」\n"
            .. "他朝你点了点头，将剑尖指向地面。\n\n"
            .. "你注意到他的剑法比之前又精进了不少。\n"
            .. "一种技痒的感觉涌了上来——\n"
            .. "和他切磋一下，应该会很有意思。\n\n"
            .. "「怎么，是来看我练剑的？还是——」\n"
            .. "他挑了挑眉，似乎读懂了你的心思。",
        choices = {
            {
                text = "⚔️ 「来比划比划？」",
                action = function()
                    S.sparringToday = true
                    S.sparringCount = (S.sparringCount or 0) + 1
                    S.sparringReturnTo = "十字路口"
                    BattleSystem.startSparring()
                    BattleSystem.processEnemyTurnsUntilPlayer()
                    GameState.addRecentEvent("和" .. leiderName .. "切磋了一场")
                    return "战斗"
                end,
            },
            {
                text = "「就是路过，看你练得挺好。」",
                action = function()
                    S.initialNameAffection = (S.initialNameAffection or 0) + 1
                    return "十字路口"
                end,
            },
        },
    }
end

return handlers
