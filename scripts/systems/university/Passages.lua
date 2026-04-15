-- systems/university/Passages.lua
-- Extracted passage logic from UniversitySystem

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local WorkSystem = require("systems.WorkSystem")

local Passages = {}

function Passages.getPassage(passageName, UniSystem)
    local S = GameState.state
    UniSystem.ensureInit(S)

    -- ==================== 大学校门 ====================

    if passageName == "大学校门" or passageName == "十字路口_社区大学" then
        local dayName = DAY_NAMES[((S.day - 1) % 7) + 1] or "?"
        local timeStr = string.format("%02d:%02d", S.hour, S.minute)

        local lines = {
            "社区大学\n",
            "一座由青石砌成的拱门矗立在道路尽头，上方刻着：",
            "「艾瑟顿社区大学 —— 知识改变命运」\n",
            "穿过拱门，是一片开阔的校园。左边是几栋教学楼，",
            "右边有一片翠绿的花园，远处还能看到社团活动室的屋顶。",
            "门口的公告栏上贴满了课程表和社团招新海报。\n",
            "📅 今天是" .. dayName .. "  🕐 " .. timeStr,
        }

        -- 显示今日课表摘要
        if S.uniEnrolled and #S.uniMajors > 0 then
            local todayClasses = UniSystem.getTodaySchedule()
            if #todayClasses > 0 then
                table.insert(lines, "\n── 今日课表 ──")
                local currentMin = S.hour * 60 + S.minute
                for _, tc in ipairs(todayClasses) do
                    local tStr = string.format("%02d:%02d", tc.cls.hour, tc.cls.minute)
                    local classStart = tc.cls.hour * 60 + tc.cls.minute
                    local classEnd = classStart + tc.cls.duration
                    local status
                    if tc.graduated then
                        status = "（已毕业）"
                    elseif tc.attended then
                        status = " ✅"
                    elseif currentMin >= classEnd then
                        status = "（已结束）"
                    elseif currentMin >= classStart then
                        status = " 🔴上课中"
                    else
                        status = ""
                    end
                    table.insert(lines, tc.majorIcon .. " " .. tStr .. " " .. tc.cls.name .. " @" .. tc.cls.location .. status)
                end
            else
                table.insert(lines, "\n今天没有课程安排。")
            end

            -- 已报名专业概况
            table.insert(lines, "\n── 我的专业（" .. #S.uniMajors .. "/" .. MAX_MAJORS .. "）──")
            for _, majorId in ipairs(S.uniMajors) do
                local major = UniSystem.getMajorInfo(majorId)
                local mData = UniSystem.getMajorData(majorId)
                local levelName = UniSystem.getLevelName(mData.level)
                local nextExp = UniSystem.getExpToNext(mData.level)
                local expText = mData.level >= 5 and "已毕业!" or (mData.exp .. "/" .. nextExp)
                table.insert(lines, (major and major.icon or "📚") .. " " .. (major and major.name or majorId) .. " " .. levelName .. " (" .. expText .. ")")
            end
        end

        local choices = {}

        table.insert(choices, { text = "🏫 去教学楼", target = "大学_教学楼" })
        table.insert(choices, { text = "📋 看公告栏", target = "大学_公告栏" })
        table.insert(choices, { text = "🌿 去花园散步", target = "大学_花园" })
        table.insert(choices, { text = "🏢 去教师办公室", target = "大学_教师办公室" })
        table.insert(choices, { text = "🎭 去社团活动室", target = "大学_社团室" })

        if S.uniEnrolled then
            table.insert(choices, { text = "🗣️ 和同学聊天", target = "大学_聊天" })
        end

        table.insert(choices, { text = "🔙 离开大学", target = "十字路口" })

        return { text = table.concat(lines, "\n"), choices = choices }
    end

    -- ==================== 公告栏（课表 + 报名入口）====================

    if passageName == "大学_公告栏" then
        local lines = {
            "📋 公告栏\n",
            "公告栏上贴着整齐的课程表和招生信息：\n",
            "══ 本学期课程表 ══",
        }

        -- 按星期几合并所有专业课程
        local daySlots = {} -- daySlots[day] = { {hour, minute, majorIcon, majorName, clsName, location}, ... }
        for _, major in ipairs(UniSystem.MAJORS) do
            local schedule = UniSystem.SCHEDULE[major.id]
            if schedule then
                for _, cls in ipairs(schedule) do
                    if not daySlots[cls.day] then daySlots[cls.day] = {} end
                    table.insert(daySlots[cls.day], {
                        hour = cls.hour, minute = cls.minute,
                        icon = major.icon, majorName = major.name,
                        clsName = cls.name, location = cls.location,
                    })
                end
            end
        end
        -- 按天遍历（周一~周日）
        for day = 1, 7 do
            local slots = daySlots[day]
            if slots then
                -- 按时间排序
                table.sort(slots, function(a, b)
                    return a.hour * 60 + a.minute < b.hour * 60 + b.minute
                end)
                table.insert(lines, "\n" .. DAY_NAMES[day] .. "：")
                for _, s in ipairs(slots) do
                    local timeStr = string.format("%02d:%02d", s.hour, s.minute)
                    table.insert(lines, "  " .. timeStr .. " " .. s.icon .. " " .. s.clsName .. "（" .. s.majorName .. "）@" .. s.location)
                end
            end
        end

        table.insert(lines, "\n💰 学费：每节课" .. CLASS_COST .. "金币")
        table.insert(lines, "📝 每位学生最多同时报名" .. MAX_MAJORS .. "个专业")

        local choices = {}
        local enrolledCount = #S.uniMajors

        if enrolledCount < MAX_MAJORS then
            table.insert(choices, {
                text = "📝 报名入学（已报" .. enrolledCount .. "/" .. MAX_MAJORS .. "）",
                target = "大学_报名",
            })
        else
            table.insert(choices, {
                text = "📝 专业已满（" .. enrolledCount .. "/" .. MAX_MAJORS .. "）",
                action = function()
                    GameState.showNotification("你已经报满了" .. MAX_MAJORS .. "个专业。想换专业需要先退学一个。")
                    return "大学_公告栏"
                end,
            })
        end

        if enrolledCount > 0 then
            table.insert(choices, { text = "🚪 退学（取消某个专业）", target = "大学_退学" })
        end

        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })
        return { text = table.concat(lines, "\n"), choices = choices }
    end

    -- ==================== 报名 ====================

    if passageName == "大学_报名" then
        local choices = {}

        for _, major in ipairs(UniSystem.MAJORS) do
            if not UniSystem.isEnrolled(major.id) then
                local mData = S.uniMajorData[major.id]
                local extra = ""
                if mData and mData.level > 0 then
                    extra = "（保留进度：" .. UniSystem.getLevelName(mData.level) .. "）"
                end
                table.insert(choices, {
                    text = major.icon .. " " .. major.name .. extra,
                    action = function()
                        S._selectedMajor = major.id
                        return "大学_专业介绍"
                    end,
                })
            else
                local mData = UniSystem.getMajorData(major.id)
                table.insert(choices, {
                    text = major.icon .. " " .. major.name .. "（已报名·" .. UniSystem.getLevelName(mData.level) .. "）",
                    action = function()
                        GameState.showNotification("你已经在学" .. major.name .. "了。")
                        return "大学_报名"
                    end,
                })
            end
        end

        table.insert(choices, { text = "🔙 返回公告栏", target = "大学_公告栏" })

        return {
            text = "招生老师热情地接待了你：\n\n"
                .. "「欢迎！我们开设四个专业，每个都能学到实用技能。\n"
                .. "每位同学最多可以同时修读" .. MAX_MAJORS .. "个专业。\n"
                .. "选一个你感兴趣的吧！」",
            choices = choices,
        }
    end

    -- ==================== 专业介绍 ====================

    if passageName == "大学_专业介绍" then
        local majorId = S._selectedMajor
        local major = UniSystem.getMajorInfo(majorId)
        if not major then
            return {
                text = "好像出了什么问题……",
                choices = { { text = "🔙 返回", target = "大学_报名" } },
            }
        end

        -- 属性加成描述
        local statNames = { LL = "力量", LG = "灵感", ML = "魅力", NL = "耐力", JQ = "技巧" }
        local bonusParts = {}
        if major.fiveStats then
            for stat, val in pairs(major.fiveStats) do
                table.insert(bonusParts, (statNames[stat] or stat) .. "+" .. val)
            end
        end
        if major.combatBonus then
            local bonusNames = { phys = "物理伤害", magic = "魔法伤害", mdef = "魔法抗性" }
            table.insert(bonusParts, (bonusNames[major.combatBonus.type] or major.combatBonus.type) .. "+" .. math.floor(major.combatBonus.perLevel * 100 + 0.5) .. "%")
        end
        if major.cookingExpPerClass then
            table.insert(bonusParts, "每节课额外获得烹饪经验")
        end
        local bonusText = #bonusParts > 0 and table.concat(bonusParts, "、") or "无"

        -- 课表描述
        local scheduleLines = {}
        local schedule = UniSystem.SCHEDULE[majorId]
        if schedule then
            for _, cls in ipairs(schedule) do
                local dayStr = DAY_NAMES[cls.day] or "?"
                local timeStr = string.format("%02d:%02d", cls.hour, cls.minute)
                table.insert(scheduleLines, "  " .. dayStr .. " " .. timeStr .. " " .. cls.name .. " @" .. cls.location)
            end
        end

        return {
            text = major.icon .. " " .. major.name .. "\n\n"
                .. major.desc .. "\n\n"
                .. "── 课程安排 ──\n"
                .. table.concat(scheduleLines, "\n") .. "\n\n"
                .. "── 详细信息 ──\n"
                .. "学费: 每节课" .. CLASS_COST .. "金币\n"
                .. "每周课时: 3节（每节90分钟）\n"
                .. "升级加成: 每升一级" .. bonusText .. "\n\n"
                .. "确定选这个专业吗？",
            choices = {
                {
                    text = "✅ 报名" .. major.name .. "！",
                    action = function()
                        table.insert(S.uniMajors, majorId)
                        -- 恢复旧进度或创建新数据
                        if not S.uniMajorData[majorId] then
                            S.uniMajorData[majorId] = { level = 0, exp = 0, totalClasses = 0 }
                        end
                        S.uniEnrolled = true
                        -- 兼容旧字段
                        if #S.uniMajors == 1 then
                            S.uniMajor = majorId
                            S.uniMajorName = major.name
                        end
                        local mData = S.uniMajorData[majorId]
                        if mData.level > 0 then
                            GameState.showNotification("欢迎回来！你继续" .. major.name .. "的学业（" .. UniSystem.getLevelName(mData.level) .. "）。")
                        else
                            GameState.showNotification("恭喜入学！你成为了" .. major.name .. "专业的新生！")
                        end
                        GameState.addDateLog("社区大学", "入学", "报名了" .. major.name .. "专业")
                        return "大学校门"
                    end,
                },
                { text = "🔙 看看其他专业", target = "大学_报名" },
            },
        }
    end

    -- ==================== 退学 ====================

    if passageName == "大学_退学" then
        local choices = {}
        for _, majorId in ipairs(S.uniMajors) do
            local major = UniSystem.getMajorInfo(majorId)
            local mData = UniSystem.getMajorData(majorId)
            local levelName = UniSystem.getLevelName(mData.level)
            table.insert(choices, {
                text = (major and major.icon or "📚") .. " 退出" .. (major and major.name or majorId) .. "（当前" .. levelName .. "）",
                action = function()
                    S._dropMajor = majorId
                    return "大学_退学确认"
                end,
            })
        end
        table.insert(choices, { text = "🔙 算了，不退了", target = "大学_公告栏" })

        return {
            text = "退学申请\n\n"
                .. "⚠️ 退学后该专业的等级和经验会保留，\n"
                .. "重新报名后可以继续学习。\n\n"
                .. "选择要退出的专业：",
            choices = choices,
        }
    end

    if passageName == "大学_退学确认" then
        local majorId = S._dropMajor
        local major = UniSystem.getMajorInfo(majorId)
        local majorName = major and major.name or majorId

        return {
            text = "确定要退出" .. majorName .. "吗？\n\n学业进度会保留，以后可以重新报名继续学。",
            choices = {
                {
                    text = "✅ 确定退学",
                    action = function()
                        for i, id in ipairs(S.uniMajors) do
                            if id == majorId then
                                table.remove(S.uniMajors, i)
                                break
                            end
                        end
                        if #S.uniMajors == 0 then
                            S.uniEnrolled = false
                            S.uniMajor = ""
                            S.uniMajorName = ""
                        else
                            S.uniMajor = S.uniMajors[1]
                            local m = UniSystem.getMajorInfo(S.uniMajors[1])
                            S.uniMajorName = m and m.name or ""
                        end
                        GameState.showNotification("你已退出" .. majorName .. "专业。学业进度已保留。")
                        GameState.addDateLog("社区大学", "退学", "退出了" .. majorName .. "专业")
                        return "大学_公告栏"
                    end,
                },
                { text = "🔙 再想想", target = "大学_退学" },
            },
        }
    end

    -- ==================== 教学楼 ====================

    if passageName == "大学_教学楼" then
        if not S.uniEnrolled or #S.uniMajors == 0 then
            return {
                text = "🏫 教学楼\n\n"
                    .. "你走进教学楼，长长的走廊两侧是一间间教室。\n"
                    .. "门牌上标注着各专业的教室号：101战术教室、201魔法教室、\n"
                    .. "301神学教室、401食材教室、训练场、魔法实验室、烹饪教室……\n\n"
                    .. "你还没有报名任何专业，无法上课。\n"
                    .. "去公告栏看看有什么专业可以报名吧。",
                choices = {
                    { text = "📋 去公告栏", target = "大学_公告栏" },
                    { text = "🔙 回到校门", target = "大学校门" },
                },
            }
        end

        local dayName = DAY_NAMES[((S.day - 1) % 7) + 1] or "?"
        local timeStr = string.format("%02d:%02d", S.hour, S.minute)
        local currentMin = S.hour * 60 + S.minute

        local lines = {
            "🏫 教学楼\n",
            "走廊里回荡着粉笔在黑板上书写的声音。\n"
            .. "透过教室门上的小窗，能看到正在上课的师生。\n",
            "📅 " .. dayName .. " " .. timeStr .. "\n",
        }

        -- 当前可上的课
        local availableClasses = UniSystem.getAvailableClasses()
        -- 今日课表
        local todayClasses = UniSystem.getTodaySchedule()
        local upcomingClasses = {}
        local pastClasses = {}

        for _, tc in ipairs(todayClasses) do
            local classStart = tc.cls.hour * 60 + tc.cls.minute
            local classEnd = classStart + tc.cls.duration
            if tc.attended then
                table.insert(pastClasses, tc)
            elseif currentMin < classStart then
                table.insert(upcomingClasses, tc)
            elseif currentMin >= classEnd then
                table.insert(pastClasses, tc)
            end
        end

        if #availableClasses > 0 then
            table.insert(lines, "── 🔴 正在上课 ──")
            for _, ac in ipairs(availableClasses) do
                local endMin = ac.cls.hour * 60 + ac.cls.minute + ac.cls.duration
                local endH = math.floor(endMin / 60)
                local endM = endMin % 60
                local timeEndStr = string.format("%02d:%02d", endH, endM)
                table.insert(lines, ac.majorIcon .. " " .. ac.cls.name .. " @" .. ac.cls.location .. "（至" .. timeEndStr .. "）")
            end
        end

        if #upcomingClasses > 0 then
            table.insert(lines, "\n── 📅 今日待上 ──")
            for _, uc in ipairs(upcomingClasses) do
                local tStr = string.format("%02d:%02d", uc.cls.hour, uc.cls.minute)
                local statusTag = uc.graduated and "（已毕业）" or ""
                table.insert(lines, uc.majorIcon .. " " .. tStr .. " " .. uc.cls.name .. " @" .. uc.cls.location .. statusTag)
            end
        end

        if #pastClasses > 0 then
            table.insert(lines, "\n── ✅ 已完成/已过 ──")
            for _, pc in ipairs(pastClasses) do
                local tStr = string.format("%02d:%02d", pc.cls.hour, pc.cls.minute)
                local mark = pc.attended and "✅" or "❌缺课"
                if pc.graduated then mark = "🎓毕业" end
                table.insert(lines, pc.majorIcon .. " " .. tStr .. " " .. pc.cls.name .. " " .. mark)
            end
        end

        if #availableClasses == 0 and #upcomingClasses == 0 and #pastClasses == 0 then
            table.insert(lines, "今天没有你的课。")
        end

        local choices = {}

        for _, ac in ipairs(availableClasses) do
            local costText = S.money >= CLASS_COST and (CLASS_COST .. "金币") or "金币不足"
            table.insert(choices, {
                text = "📚 上课：" .. ac.cls.name .. "（" .. costText .. "）",
                action = function()
                    S._attendClass = {
                        majorId = ac.majorId,
                        slotIndex = ac.slotIndex,
                        slotKey = ac.slotKey,
                        cls = ac.cls,
                    }
                    return "大学_上课"
                end,
            })
        end

        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })

        return { text = table.concat(lines, "\n"), choices = choices }
    end

    -- ==================== 上课 ====================

    if passageName == "大学_上课" then
        local classInfo = S._attendClass
        if not classInfo then
            return {
                text = "现在没有可以上的课。",
                choices = { { text = "🔙 返回", target = "大学_教学楼" } },
            }
        end

        if S.money < CLASS_COST then
            S._attendClass = nil
            return {
                text = "学费不够了……需要" .. CLASS_COST .. "金币。",
                choices = { { text = "🔙 返回", target = "大学_教学楼" } },
            }
        end

        local majorId = classInfo.majorId
        local cls = classInfo.cls
        local slotKey = classInfo.slotKey
        local slotIndex = classInfo.slotIndex
        local major = UniSystem.getMajorInfo(majorId)
        local mData = UniSystem.getMajorData(majorId)

        if mData.level >= 5 then
            S._attendClass = nil
            return {
                text = "你已经从" .. (major and major.name or majorId) .. "专业毕业了！",
                choices = { { text = "🔙 返回", target = "大学_教学楼" } },
            }
        end

        -- 扣费 & 标记出勤
        S.money = S.money - CLASS_COST
        S.uniAttendedToday[slotKey] = true
        mData.totalClasses = mData.totalClasses + 1
        S.uniTotalClasses = (S.uniTotalClasses or 0) + 1

        -- 推进时间到课程结束
        local classEndMin = cls.hour * 60 + cls.minute + cls.duration
        local currentMin = S.hour * 60 + S.minute
        local timeAdvance = math.max(30, classEndMin - currentMin)
        TimeSystem.addMinutes(timeAdvance)

        -- 学业经验
        local expGain = major and major.expPerClass or 15

        -- 烹饪额外经验
        local cookingExpGain = 0
        if major and major.cookingExpPerClass then
            cookingExpGain = major.cookingExpPerClass
            local ok, CookingSystem = pcall(require, "systems.CookingSystem")
            if ok and CookingSystem.addCookingExp then
                CookingSystem.addCookingExp(cookingExpGain)
            end
        end

        UniSystem.addMajorExp(majorId, expGain)

        -- 首次上课赠送教材
        local textbookMap = {
            warrior  = { var = "hasTacticsText",  name = "《战术学教材》" },
            mage     = { var = "hasMagicText",    name = "《魔法理论概论》" },
            theology = { var = "hasTheologyText", name = "《神学经典诠释》" },
            cooking  = { var = "hasCookText",     name = "《烹饪学原理》" },
        }
        local tbInfo = textbookMap[majorId]
        if tbInfo and not S[tbInfo.var] then
            S[tbInfo.var] = true
            GameState.showNotification("获得教材" .. tbInfo.name .. "！可以在家中阅读增加知识经验。")
        end

        -- 上课也增加对应知识经验
        local knowledgeMap = {
            warrior  = "tactics",
            mage     = "magicTheory",
            theology = "theology",
            cooking  = "cookTheory",
        }
        local kId = knowledgeMap[majorId]
        if kId then
            local ok2, WS = pcall(require, "systems.WorkSystem")
            if ok2 and WS.addKnowledgeExp then
                WS.addKnowledgeExp(kId, 10)
            end
        end

        -- 关键词收集
        local kwOk, KW = pcall(require, "systems.KeywordSystem")
        if kwOk and KW.collectKeyword then
            if majorId == "warrior" then KW.collectKeyword("guild_mission")
            elseif majorId == "mage" then KW.collectKeyword("magic_theory")
            elseif majorId == "theology" then
                KW.collectKeyword("history_class")
                if math.random() < 0.2 then KW.collectKeyword("ancient_text") end
            elseif majorId == "cooking" then KW.collectKeyword("rare_ingredient")
            end
        end

        -- 消耗
        GameState.modStat("fatigue", 8)
        GameState.modStat("stress", -2)

        -- 课堂场景
        local scenes = UniSystem.CLASS_SCENES[majorId]
        local sceneText = "上课结束了。"
        if scenes and scenes[slotIndex] then
            local pool = scenes[slotIndex]
            sceneText = pool[math.random(#pool)]
        end

        -- 结果信息
        local levelName = UniSystem.getLevelName(mData.level)
        local nextExp = UniSystem.getExpToNext(mData.level)
        local expBar = mData.level >= 5 and "已毕业!" or (mData.exp .. "/" .. nextExp)
        local lifeExpInfo = "生活等级: Lv." .. S.lifeLevel .. " (" .. S.lifeExp .. "/150)"

        local resultText = (major and major.icon or "📚") .. " " .. (major and major.name or majorId)
            .. " · " .. cls.name .. "\n"
            .. "📍 " .. cls.location .. "\n\n"
            .. sceneText .. "\n\n"
            .. "── 本节收获 ──\n"
            .. "学业经验 +" .. expGain .. " (" .. expBar .. ")\n"
            .. "疲劳 +8\n"
            .. (cookingExpGain > 0 and ("烹饪经验 +" .. cookingExpGain .. "\n") or "")
            .. "学业等级: " .. levelName .. "\n"
            .. lifeExpInfo

        local choices = {}

        -- 检查是否还有课可上
        S._attendClass = nil
        local nextAvailable = UniSystem.getAvailableClasses()
        for _, ac in ipairs(nextAvailable) do
            table.insert(choices, {
                text = "📚 继续上课：" .. ac.cls.name,
                action = function()
                    S._attendClass = {
                        majorId = ac.majorId,
                        slotIndex = ac.slotIndex,
                        slotKey = ac.slotKey,
                        cls = ac.cls,
                    }
                    return "大学_上课"
                end,
            })
        end

        table.insert(choices, { text = "🏫 回到教学楼", target = "大学_教学楼" })
        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })

        return { text = resultText, choices = choices }
    end

    -- ==================== 花园 ====================

    if passageName == "大学_花园" then
        local gardenScenes = {
            "校园花园里种满了各色花卉，一条碎石小径蜿蜒其中。\n阳光透过树叶洒下斑驳的光影，几只蝴蝶在花丛间飞舞。",
            "花园中央有一座小喷泉，水声潺潺。\n几个学生坐在长椅上看书，气氛宁静而美好。",
            "花园一角有几棵老橡树，巨大的树冠撑起一片阴凉。\n树下放着几张石桌，适合静静地坐一会儿。",
        }
        local sceneText = gardenScenes[math.random(#gardenScenes)]

        local choices = {
            {
                text = "🪑 在长椅上坐一会儿（15分钟）",
                action = function()
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -5)
                    GameState.showNotification("你在花园的长椅上坐了一会儿，听着鸟鸣和风声，心情放松了不少。(压力-5)")
                    return "大学_花园"
                end,
            },
            {
                text = "🌸 沿小径散步（20分钟）",
                action = function()
                    TimeSystem.addMinutes(20)
                    GameState.modStat("stress", -8)
                    GameState.modStat("fatigue", 2)
                    local walkScenes = {
                        "你沿着花间小径慢慢走着，空气中弥漫着花香。偶尔遇到同学打招呼，感觉很惬意。",
                        "散步时发现花园深处有一小片草药田，是烹饪系学生种的。各种香草长势喜人。",
                        "你在大橡树下站了一会儿，看着树上的松鼠追逐嬉戏，不禁露出微笑。",
                    }
                    GameState.showNotification(walkScenes[math.random(#walkScenes)] .. "(压力-8)")
                    return "大学_花园"
                end,
            },
        }

        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })

        return {
            text = "🌿 校园花园\n\n" .. sceneText,
            choices = choices,
        }
    end

    -- ==================== 教师办公室 ====================

    if passageName == "大学_教师办公室" then
        local lines = {
            "🏢 教师办公室\n",
            "走廊尽头是教师办公室，门口挂着各位教授的名牌。",
            "空气中飘着淡淡的墨水和茶叶的气味。\n",
        }

        local choices = {}

        if S.uniEnrolled and #S.uniMajors > 0 then
            -- 查看成绩
            table.insert(choices, {
                text = "📊 查看学业成绩",
                action = function()
                    local msgs = {}
                    for _, majorId in ipairs(S.uniMajors) do
                        local major = UniSystem.getMajorInfo(majorId)
                        local mData = UniSystem.getMajorData(majorId)
                        local levelName = UniSystem.getLevelName(mData.level)
                        local nextExp = UniSystem.getExpToNext(mData.level)
                        local expText = mData.level >= 5 and "已毕业" or (mData.exp .. "/" .. nextExp)
                        table.insert(msgs, (major and major.icon or "📚") .. " " .. (major and major.name or majorId) .. ": " .. levelName .. " (" .. expText .. ") 累计" .. mData.totalClasses .. "节课")
                        if major and major.combatBonus then
                            local bonusKey = "uniCombatBonus_" .. major.combatBonus.type
                            local total = S[bonusKey] or 0
                            if total > 0 then
                                local bonusNames = { phys = "物理伤害", magic = "魔法伤害", mdef = "魔法抗性" }
                                table.insert(msgs, "  └ " .. (bonusNames[major.combatBonus.type] or "") .. "+" .. math.floor(total * 100 + 0.5) .. "%")
                            end
                        end
                    end
                    GameState.showNotification("── 学业报告 ──\n" .. table.concat(msgs, "\n"))
                    return "大学_教师办公室"
                end,
            })

            -- 请教老师（额外获得少量经验，花钱+时间）
            for _, majorId in ipairs(S.uniMajors) do
                local major = UniSystem.getMajorInfo(majorId)
                local mData = UniSystem.getMajorData(majorId)
                if mData.level < 5 then
                    table.insert(choices, {
                        text = "📖 请教" .. (major and major.name or majorId) .. "老师（10金币·30分钟）",
                        action = function()
                            if S.money >= 10 then
                                S.money = S.money - 10
                                TimeSystem.addMinutes(30)
                                local tutorExp = 5
                                UniSystem.addMajorExp(majorId, tutorExp)
                                GameState.modStat("fatigue", 3)
                                local advices = {
                                    "老师耐心地解答了你的疑问，你豁然开朗。",
                                    "老师推荐了几本参考书，还在你的笔记上做了批注。",
                                    "老师给你布置了一道课外练习题，做完后感觉功力增进不少。",
                                }
                                GameState.showNotification(advices[math.random(#advices)] .. "（学业经验+" .. tutorExp .. "）")
                            else
                                GameState.showNotification("金币不足！课外辅导需要10金币。")
                            end
                            return "大学_教师办公室"
                        end,
                    })
                end
            end
        else
            table.insert(lines, "你还没有报名任何专业。\n教授们正在各自忙碌，不便打扰。")
        end

        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })

        return { text = table.concat(lines, "\n"), choices = choices }
    end

    -- ==================== 社团活动室 ====================

    if passageName == "大学_社团室" then
        local lines = {
            "🎭 社团活动室\n",
            "这是一间宽敞的大厅，墙上贴满了各个社团的海报和活动照片。",
            "角落里摆着棋盘、书架和各种活动道具。\n",
        }

        local choices = {}

        -- 读书会（所有人可参加）
        table.insert(choices, {
            text = "📖 参加读书会（30分钟）",
            action = function()
                TimeSystem.addMinutes(30)
                GameState.modStat("stress", -5)
                GameState.modStat("fatigue", 2)
                if #S.uniMajors > 0 then
                    local randMajor = S.uniMajors[math.random(#S.uniMajors)]
                    local mData = UniSystem.getMajorData(randMajor)
                    if mData.level < 5 then
                        UniSystem.addMajorExp(randMajor, 3)
                        local major = UniSystem.getMajorInfo(randMajor)
                        GameState.showNotification("读书会上讨论了有趣的话题，你对" .. (major and major.name or randMajor) .. "有了新的理解。(经验+3，压力-5)")
                    else
                        GameState.showNotification("读书会的讨论很有趣，虽然你已毕业，但还是学到了新东西。(压力-5)")
                    end
                else
                    GameState.showNotification("读书会上大家讨论了各种话题，旁听也很有收获。(压力-5)")
                end
                return "大学_社团室"
            end,
        })

        -- 棋艺社
        table.insert(choices, {
            text = "♟️ 去棋艺社下棋（30分钟）",
            action = function()
                TimeSystem.addMinutes(30)
                GameState.modStat("stress", -3)
                local results = {
                    "你和一个神学系的同学下了一盘棋，虽然输了，但学到了不少战术思维。",
                    "你连赢了三盘！周围的同学都对你刮目相看。",
                    "和对手下了一盘平局，双方都很尽兴。「下次再来！」",
                }
                GameState.showNotification(results[math.random(#results)] .. "(压力-3)")
                return "大学_社团室"
            end,
        })

        -- 美食社（需要报名烹饪学）
        if UniSystem.isEnrolled("cooking") then
            table.insert(choices, {
                text = "🍳 去美食社做点心（30分钟）",
                action = function()
                    TimeSystem.addMinutes(30)
                    GameState.modStat("satiety", 10)
                    local ok, CookingSystem = pcall(require, "systems.CookingSystem")
                    if ok and CookingSystem.addCookingExp then
                        CookingSystem.addCookingExp(5)
                    end
                    GameState.showNotification("在美食社做了一份小甜点，顺便自己尝了几口。(饱食度+10，烹饪经验+5)")
                    return "大学_社团室"
                end,
            })
        end

        -- 剑术社（需要报名战士学）
        if UniSystem.isEnrolled("warrior") then
            table.insert(choices, {
                text = "⚔️ 去剑术社练习（30分钟）",
                action = function()
                    TimeSystem.addMinutes(30)
                    GameState.modStat("fatigue", 5)
                    local mData = UniSystem.getMajorData("warrior")
                    if mData.level < 5 then
                        UniSystem.addMajorExp("warrior", 3)
                        GameState.showNotification("在剑术社和学长切磋了一番，虽然有点累但很有收获。(战士学经验+3)")
                    else
                        GameState.showNotification("作为毕业生，你给后辈们做了示范指导，学弟学妹们很崇拜你。")
                    end
                    return "大学_社团室"
                end,
            })
        end

        table.insert(choices, { text = "🔙 回到校门", target = "大学校门" })

        return { text = table.concat(lines, "\n"), choices = choices }
    end

    -- ==================== 和同学聊天 ====================

    if passageName == "大学_聊天" then
        local chats = {
            {
                text = "一个胖胖的烹饪系同学递给你一块饼干：\n\n「尝尝？是我今天课上做的！」\n\n味道意外地不错。",
                effect = function()
                    GameState.modStat("satiety", 5)
                    GameState.modStat("stress", -3)
                end,
            },
            {
                text = "战士系的学长拍了拍你的肩膀：\n\n「别看这里是社区大学，毕业出去的人可不少\n当上了冒险者公会的骨干。好好学，前途光明！」",
                effect = function()
                    GameState.modStat("stress", -3)
                end,
            },
            {
                text = "一个神学系的女同学正在看书，见你过来微微一笑：\n\n「最近课业怎么样？感觉能跟上吗？\n有不懂的可以来问我哦，互相帮助嘛。」",
                effect = function()
                    GameState.modStat("stress", -5)
                end,
            },
            {
                text = "魔法系的同学正在走廊里偷偷练习火球术，\n结果把告示栏烧了个洞。\n\n被路过的教授抓个正着，罚抄咒语词典三遍。\n\n你默默捂着嘴走开了。",
                effect = function()
                    GameState.modStat("stress", -3)
                end,
            },
            {
                text = "几个同学围在一起讨论下周的考试范围。\n\n你凑过去听了一会儿，虽然不是你的专业，\n但也增长了不少见识。",
                effect = function()
                    GameState.modStat("stress", -2)
                end,
            },
            {
                text = "食堂门口，一个烹饪系的同学在推销自制三明治：\n\n「烹饪系出品，品质保证！只要3金币！」\n\n你买了一个，确实不错。",
                effect = function()
                    if S.money >= 3 then
                        S.money = S.money - 3
                        GameState.modStat("satiety", 10)
                        GameState.showNotification("三明治很好吃！(饱食度+10，-3金币)")
                    else
                        GameState.showNotification("可惜你身上没带够钱。")
                    end
                end,
            },
        }

        local chat = chats[math.random(#chats)]
        if chat.effect then chat.effect() end
        TimeSystem.addMinutes(15)

        return {
            text = chat.text,
            choices = {
                { text = "🔙 回到校门", target = "大学校门" },
            },
        }
    end

    return nil
end

return Passages
