if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local util = require("openmw.util")
local self = require("openmw.self")
local ui = require("openmw.ui")
local input = require("openmw.input")
local ambient = require("openmw.ambient")

local tooltipData = require("scripts.ios_deckwind.Deckwind.ci_tooltipgen")
local scale = 0.8
local selectedIndex = 1
local tooltipElement
local startOffset = 0
local talkedToPerson
local sellBuyWindow
local boughtSpells = {}
local cachedGold
local waitUntil = 0

local const = require("scripts.ios_deckwind.Deckwind.ci_const")
if not const.doesRun then
    return {}
end


local itemWindowLocs = {
    TopLeft = { wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil },
    TopRight = { wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0) },
    Right = { wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5) },
    Left = { wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5) },
    BottomLeft = { wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1) },
    BottomRight = { wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1) },
    BottomCenter = { wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1) },
    TopCenter = { wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0) },
    Disabled = { disabled = true }
}

local function playerHasSpell(id)
    for index, value in ipairs(types.Actor.spells(self)) do
        if value.id == id then
            return true
        end
    end
    for index, value in ipairs(boughtSpells) do
        if value == id then
            return true
        end
    end
    return false
end
local function sortSpells(spellA, spellB)
    return spellA.name < spellB.name
end
local function closeWindow()
    if sellBuyWindow then
        sellBuyWindow:destroy()
    end
    if tooltipElement then
        tooltipElement:destroy()
    end
    tooltipElement = nil
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
local function getSpellsAndPrices(enpeecee)
    local spellList = {}
    for index, value in ipairs(types.Actor.spells(enpeecee)) do
        if value.type == core.magic.SPELL_TYPE.Spell and not playerHasSpell(value.id) then
            table.insert(spellList, value)
        end
    end
    table.sort(spellList, function(a, b) return sortSpells(a, b) end)
    local spellDataLs = {}
    for index, value in ipairs(spellList) do
        local cost = value.cost * core.getGMST("fSpellValueMult")
        local offeredCost = I.ZackUtilsUI_ci.getBarterOffer(enpeecee, cost, true)
        --print(value.id, offeredCost)
        table.insert(spellDataLs, { id = value.id, name = value.name, cost = offeredCost })
    end
    return spellDataLs
end


local function drawSpellBuy(actor)
    if not actor then
        actor = talkedToPerson

    end
    if not talkedToPerson then
        error("No target")
    end
    local spellsToSell = getSpellsAndPrices(actor)
    talkedToPerson = actor
    local myClass = types.NPC.classes.record(types.NPC.record(self).class)
    if sellBuyWindow then
        sellBuyWindow:destroy()
    end
    if tooltipElement then
        tooltipElement:destroy()
    end
    local content    = {}
    local xContent   = {}

    --major skills

    local myName     = types.NPC.record(self).name
    local headerText = renderItemBold(myName, true)

    table.insert(content, renderItemBold(core.getGMST("sServiceSpellsTitle"), true))
    table.insert(content, renderItemBold(core.getGMST("sSpellServiceTitle"), false))
    --print(#miscSkills)


    xContent = {}
    local spellList = {}
    if not spellsToSell[selectedIndex] then
        selectedIndex = #spellsToSell
        startOffset = #spellsToSell - 20
    end
    for i = 1, 20, 1 do
        if spellsToSell[i + startOffset] then
            table.insert(spellList,
                renderItemBold(spellsToSell[i + startOffset].name .. " - " .. spellsToSell[i + startOffset].cost, false,
                    spellsToSell[i + startOffset].id, i + startOffset))
        end
    end
    local secondRow = I.CI_StatsMenu.renderItemBoxed(I.CI_StatsMenu.flexedItems(spellList, false),
        util.vector2((100 * scale) * 7, 500 * scale),
        I.MWUI.templates.padding)
    table.insert(content, secondRow)
    local goldString =  core.getGMST("sGold")..": " .. tostring(types.Actor.inventory(self):countOf("gold_001"))
    if cachedGold then
        goldString = core.getGMST("sGold")..": " .. tostring(cachedGold)
    end
    local tooltipLs = {}
    local selectedSpell = spellsToSell[selectedIndex]
    if selectedSpell then
        local spellRecord = core.magic.spells.records[selectedSpell.id]
        local text =  tooltipData.genMagicTooltips(tooltipLs,spellRecord,nil)
        tooltipElement = I.ZackUtilsUI_ci.drawListMenu(tooltipLs,
        itemWindowLocs.BottomCenter, nil, "InfoTips")
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
    drawSpellBuy(talkedToPerson)
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
    drawSpellBuy(talkedToPerson)
end
local function enterKey()
    if core.getRealTime() < waitUntil then
        return
    end
    local spell = getSpellsAndPrices(talkedToPerson)[selectedIndex]
    if spell then
        local cost = spell.cost
        if types.Actor.inventory(self):countOf("gold_001") >= cost then
            types.Actor.spells(self):add(spell.id)
            table.insert(boughtSpells, spell.id)
            cachedGold = types.Actor.inventory(self):countOf("gold_001") - cost
            ambient.playSound("item gold up")
            I.CI_ActorGold.incrementActorGold(talkedToPerson,math.abs(cost))
            --print(goldRequired,soldandBoughtItems)
            core.sendGlobalEvent("incrementPlayerGold", cost)
            drawSpellBuy(talkedToPerson)
        end
    end
end
I.UI.registerWindow("SpellBuying",function ()
    waitUntil = core.getRealTime() + 1
    drawSpellBuy()
end, function ()
    closeWindow()
end)
return {
    interfaceName = "SpellBuy",
    interface = {
        getSpellsAndPrices = getSpellsAndPrices,
        drawSpellBuy = drawSpellBuy,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if not data.newMode then
                closeWindow()
            elseif data.newMode == I.UI.MODE.Dialogue then
                talkedToPerson = data.arg
            elseif data.newMode == I.UI.MODE.SpellBuying then
                talkedToPerson = data.arg
            end
        end,
    },
    engineHandlers = {
        onControllerButtonPress = function (ctrl)
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
