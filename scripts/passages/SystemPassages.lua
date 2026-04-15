-- passages/SystemPassages.lua
-- Split into sub-modules under passages/system/

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local WorkSystem = require("systems.WorkSystem")
local HomeSystem = require("systems.HomeSystem")
local BattleSystem = require("systems.BattleSystem")
local ChangelogData = require("systems.ChangelogData")
local SaveSystem = require("systems.SaveSystem")
local MainQuest = require("systems.MainQuest")
local MainQuestCh2 = require("systems.MainQuestCh2")
local MainQuestCh3 = require("systems.MainQuestCh3")
local CookingSystem = require("systems.CookingSystem")
local FarmingSystem = require("systems.FarmingSystem")
local UniSystem = require("systems.UniversitySystem")
local TownLife = require("systems.TownLife")
local RandomEvents = require("systems.RandomEvents")
local KeywordSystem = require("systems.KeywordSystem")
local SideQuests = require("systems.SideQuests")
local CommonUtils = require("utils.CommonUtils")
local PassageDeps = require("passages.PassageDeps")

local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog
local addOamelAffection = PassageDeps.addOamelAffection
local addMeifeiAffection = PassageDeps.addMeifeiAffection
local topicDialogues = PassageDeps.topicDialogues
local handlers = {}

local handlers = {}

local deps = {
    GameState = GameState,
    TimeSystem = TimeSystem,
    WorkSystem = WorkSystem,
    HomeSystem = HomeSystem,
    BattleSystem = BattleSystem,
    ChangelogData = ChangelogData,
    SaveSystem = SaveSystem,
    MainQuest = MainQuest,
    MainQuestCh2 = MainQuestCh2,
    MainQuestCh3 = MainQuestCh3,
    CookingSystem = CookingSystem,
    FarmingSystem = FarmingSystem,
    UniSystem = UniSystem,
    TownLife = TownLife,
    RandomEvents = RandomEvents,
    KeywordSystem = KeywordSystem,
    SideQuests = SideQuests,
    CommonUtils = CommonUtils,
    PassageDeps = PassageDeps,
    addAffection = addAffection,
    addDateLog = addDateLog,
    addOamelAffection = addOamelAffection,
    addMeifeiAffection = addMeifeiAffection,
    topicDialogues = topicDialogues,
    handlers = handlers,
}

require("passages.system.SkillBattle")(handlers, deps)
require("passages.system.StatusRelations")(handlers, deps)
require("passages.system.InventoryLog")(handlers, deps)
require("passages.system.MapNavigation")(handlers, deps)
require("passages.system.SettingsSave")(handlers, deps)

return handlers
