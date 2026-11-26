if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local util = require("openmw.util")
local self = require("openmw.self")
local ui = require("openmw.ui")
local input = require("openmw.input")
local ambient = require("openmw.ambient")
local scale = 0.8
local selectedIndex = 1
local startOffset = 0
local talkedToPerson
local sellBuyWindow
local boughtRepairs = {}
local cachedGold
local waitUntil = 0


local const = require("scripts.ios_deckwind.Deckwind.ci_const")
if not const.doesRun then
    return {}
end


local function playerHasRepair(id)
    for index, value in ipairs(types.Actor.Repairs(self)) do
        if value.id == id then
            return true
        end
    end
    for index, value in ipairs(boughtRepairs) do
        if value == id then
            return true
        end
    end
    return false
end
local function sortRepairs(RepairA, RepairB)
    return RepairA.name < RepairB.name
end
local function closeWindow()
    if sellBuyWindow then
        sellBuyWindow:destroy()
    end
    sellBuyWindow = nil
end

local function renderItemBold(item, bold, id, index)
    if not id then id = item end
    local textTemplate = I.MWUI.templates.textNormal
    if bold then
        textTemplate = I.MWUI.templates.textHeader
    end
    if index == selectedIndex then
        textTemplate = I.MWUI.templates.textHeader
    end
    return {
        type = ui.TYPE.Container,
        id = id,
        tooltipData = tooltipData,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        events = {
            --  mouseMove = async:callback(mouseMove),
            --  mousePress = async:callback(mouseClick),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = textTemplate,
                        props = {
                            text = item,
                            textSize = 20 * scale,
                            relativePosition = util.vector2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function getRepairsAndPrices(enpeecee)
    local RepairList = {}
    for index, value in ipairs(types.Actor.inventory(self):getAll()) do
        if value.type == types.Weapon or value.type == types.Armor then
            local alreadyFixed = false
            for index, rep in ipairs(boughtRepairs) do
                if rep == value.id then
                    alreadyFixed = true
                end
            end
            local currentCondition = types.Item.itemData(value).condition
            local record = value.type.record(value)
            if not alreadyFixed and  currentCondition ~= nil and currentCondition < value.type.record(value).health and record.name then
                table.insert(RepairList, { obj = value, recordId = value.recordId, name = record.name })
            end
        end
    end
    table.sort(RepairList, function(a, b) return sortRepairs(a, b) end)
    local RepairDataLs = {}
    for index, value in ipairs(RepairList) do
        local record = value.obj.type.records[value.recordId]
        if record.name then
            local basePrice        = record.value
            local mult             = core.getGMST("fRepairMult")
            local currentCondition = types.Item.itemData(value.obj).condition
            local maxCondition     = value.obj.type.records[value.obj.recordId].health
            local p                = math.max(1, basePrice)
            local r                = math.max(1, math.floor(maxCondition / p))

            local x                = math.floor((maxCondition - currentCondition) / r)
            x                      = math.floor(mult * x)
            x                      = math.max(1, x)
            local offeredCost      = I.ZackUtilsUI_ci.getBarterOffer(enpeecee, x, true)
           -- print(value.name, offeredCost)
            table.insert(RepairDataLs, { id = value.obj.id, name = record.name, cost = offeredCost })
        end
    end
    return RepairDataLs
end


local function drawRepairBuy(actor)
    if not actor then
        actor = talkedToPerson
    end
    local RepairsToSell = getRepairsAndPrices(actor)
    talkedToPerson = actor
    if sellBuyWindow then
        sellBuyWindow:destroy()
    end
    local content    = {}
    local xContent   = {}

    --major skills

    local myName     = types.NPC.record(self).name
    local headerText = renderItemBold(myName, true)

    table.insert(content, renderItemBold(core.getGMST("sRepair"), true))
    table.insert(content, renderItemBold(core.getGMST("sRepairServiceTitle"), false))
    --print(#miscSkills)


    xContent = {}
    local RepairList = {}
    if not RepairsToSell[selectedIndex] then
        selectedIndex = #RepairsToSell
        startOffset = #RepairsToSell - 20
    end
    for i = 1, 20, 1 do
        if RepairsToSell[i + startOffset] then
            table.insert(RepairList,
                renderItemBold(RepairsToSell[i + startOffset].name .. " - " .. RepairsToSell[i + startOffset].cost, false,
                    RepairsToSell[i + startOffset].id, i + startOffset))
        end
    end
    local secondRow = I.CI_StatsMenu.renderItemBoxed(I.CI_StatsMenu.flexedItems(RepairList, false),
        util.vector2((100 * scale) * 7, 500 * scale),
        I.MWUI.templates.padding)
    table.insert(content, secondRow)
    local goldString = core.getGMST("sGold")..": " .. tostring(types.Actor.inventory(self):countOf("gold_001"))
    if cachedGold then
        goldString = core.getGMST("sGold")..": " .. tostring(cachedGold)
    end
    table.insert(content, renderItemBold(goldString, false))
    -- table.insert(content, imageContent(resource, size))
    sellBuyWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(0, 0),
                }
            }
        }
    }
end
local function DownArrow()
    selectedIndex = selectedIndex + 1
    drawRepairBuy(talkedToPerson)
    if selectedIndex >= 20 then
        startOffset = startOffset + 1
    end
end
local function upArrow()
    if selectedIndex < 2 then
        return
    end
    local uiPos = selectedIndex - startOffset
    if uiPos == 1 then
        startOffset = startOffset - 1
    end
    selectedIndex = selectedIndex - 1
    drawRepairBuy(talkedToPerson)
end
local function enterKey()
    if core.getRealTime() < waitUntil then
        return
    end
    local Repair = getRepairsAndPrices(talkedToPerson)[selectedIndex]
    if Repair then
        local cost = Repair.cost
        if types.Actor.inventory(self):countOf("gold_001") >= cost then
            table.insert(boughtRepairs, Repair.id)
            for index, value in ipairs(types.Actor.inventory(self):getAll()) do
                if value.id == Repair.id then
                      core.sendGlobalEvent("CI_SetCondition", { object = value, condition = value.type.record(value).health })
                end
            end
            cachedGold = types.Actor.inventory(self):countOf("gold_001") - cost
            ambient.playSound("Repair")
            --print(goldRequired,soldandBoughtItems)
            core.sendGlobalEvent("incrementPlayerGold", cost)
            I.CI_ActorGold.incrementActorGold(talkedToPerson,math.abs(cost))
            drawRepairBuy(talkedToPerson)
        end
    end
end
I.UI.registerWindow("MerchantRepair", function()
    waitUntil = core.getRealTime() + 1
    drawRepairBuy()
end, function()
    closeWindow()
end)
--
return {
    interfaceName = "CI_RepairBuy",
    interface = {
        getRepairsAndPrices = getRepairsAndPrices,
        drawRepairBuy = drawRepairBuy,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if not data.newMode then
                closeWindow()
            elseif data.newMode == I.UI.MODE.Dialogue then
                talkedToPerson = data.arg
            end
        end,
    },
    engineHandlers = {
        onControllerButtonPress = function(ctrl)
            if not sellBuyWindow then
                return
            end
            if ctrl == input.CONTROLLER_BUTTON.DPadDown or ctrl == input.CONTROLLER_BUTTON.RightShoulder then
                DownArrow()
            elseif ctrl == input.CONTROLLER_BUTTON.DPadUp or ctrl == input.CONTROLLER_BUTTON.LeftShoulder then
                upArrow()
            elseif ctrl == input.CONTROLLER_BUTTON.A then
                enterKey()
            elseif ctrl == input.CONTROLLER_BUTTON.B then
                closeWindow()
            end
        end,
        onKeyPress = function(key)
            if not sellBuyWindow then
                return
            end
            if key.code == input.KEY.DownArrow then
                DownArrow()
            elseif key.code == input.KEY.UpArrow and selectedIndex > 1 then
                upArrow()
            elseif key.code == input.KEY.Enter then
                enterKey()
            end
        end
    }
}
