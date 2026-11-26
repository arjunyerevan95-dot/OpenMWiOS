if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local storedQuests = {}
local core = require("openmw.core")
local types = require("openmw.types")
local self = require("openmw.self")
local logMenu = require("scripts.ios_deckwind.Deckwind.ci_questmenu")
local cal = require("openmw_aux.calendar")
local function getQuestName(id)
    return core.dialogue.journal.records[id].questName
end
local function onQuestUpdate(questId, stage)
    if not storedQuests[questId] then
        storedQuests[questId] = { currentStage = stage, stageUpdates = {}, lastUpdated = core.getGameTime(), finished = false, pinned = false }
    end
    local questInfo = types.Player.quests(self)[questId]
    storedQuests[questId].currentStage = stage
    storedQuests[questId].finished = questInfo.finished
    storedQuests[questId].lastUpdated = core.getGameTime()
    for index, value in ipairs(storedQuests[questId].stageUpdates) do
        if value.stage == stage then
            return
        end
    end
    local data = { stage = stage, time = core.getGameTime(), cell = self.cell.name }

    table.insert(storedQuests[questId].stageUpdates, data)
end

local function onSave()
    return { storedQuests = storedQuests }
end
local function onLoad(data)
    if not data then
        return
    end
    storedQuests = data.storedQuests
end
local function printData()
    for questId, questData in pairs(storedQuests) do
        print("Quest: " .. questId)
        print("Current stage: " .. questData.currentStage)
        for index, value in ipairs(questData.stageUpdates) do
            print("Stage: " .. value.stage .. " Time: " .. value.time)
            local infos = core.dialogue.journal.records[questId].infos
            for infoIndex, infovalue in ipairs(infos) do
                if infovalue.questStage == value.stage then
                    print("Info: " .. infovalue.text)
                end
            end
        end
    end
end
local function openQuestMenu()
    logMenu.drawMenu()
end
local function getQuestList()
    local ls = {}

    for questId, questData in pairs(storedQuests) do
        table.insert(ls,
            { name = getQuestName(questId), id = questId, finished = questData.finished, pinned = questData.pinned })
    end
    return ls
end
local function splitLines(inputString, maxLen)
    local lines = {}
    local line = ""

    -- Loop over each word in the input string
    if not inputString then
        return { "No description available" }
    end
    if #inputString < maxLen then
        return { inputString }
    end
    for word in inputString:gmatch("%S+") do
        -- Check if adding this word would exceed the maximum length
        if #line + #word + 1 > maxLen then
            -- If line is not empty, add it to the lines table
            if #line > 0 then
                table.insert(lines, line)
            end
            -- Start a new line with the current word
            line = word
        else
            -- If the line is not empty, add a space before the word
            if #line > 0 then
                line = line .. " " .. word
            else
                line = word
            end
        end
    end

    -- Add the last line if it contains any text
    if #line > 0 then
        table.insert(lines, line)
    end

    return lines
end
local function getQuestText(questId)
    local questData = storedQuests[questId]
    local ret = {}
    for index, value in ipairs(questData.stageUpdates) do
        --    print("Stage: " .. value.stage .. " Time: " .. value.time)
        print(questId)
        local infos = core.dialogue.journal.records[questId].infos
        table.insert(ret,cal.formatGameTime(nil, value.time))
        for infoIndex, infovalue in ipairs(infos) do
            if infovalue.questStage == value.stage then
                --print("Info: " .. infovalue.text)
                local lines = splitLines(infovalue.text, 50)
                for index, value in ipairs(lines) do
                    table.insert(ret, value)
                end
            end
        end
        table.insert(ret, " ")
    end
    return ret
end
return {
    interfaceName = "CI_questlog",
    interface = {
        printData = printData,
        openQuestMenu = openQuestMenu,
        getQuestList = getQuestList,
        getQuestText = getQuestText,
    },
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onControllerButtonPress = logMenu.onControllerButtonPress,
    }
}
