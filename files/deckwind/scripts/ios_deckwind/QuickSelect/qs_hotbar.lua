if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local async = require('openmw.async')
local input = require('openmw.input')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

if I.QuickSelect_Hotbar then
    return
end
local qs_bindings = require("scripts.ios_deckwind.QuickSelect.qs_bindings")

local settings = storage.playerSection("SettingsQuickSelect")
local tooltipData = require("scripts.ios_deckwind.QuickSelect.ci_tooltipgen")
local utility = require("scripts.ios_deckwind.QuickSelect.qs_utility")
local hotBarElement
local tooltipElement
local num = 1
local enableHotbar = false       --True if we are showing the hotbar

local pickSlotMode = false       --True if we are picking a slot for saving

local controllerPickMode = false --True if we are picking a slot for equipping OR saving

local selectedNum = 1
local function startPickingMode()
    enableHotbar = true
    controllerPickMode = true
    I.QuickSelect_Hotbar.drawHotbar()
    if settings:get("pauseWhenSelecting") then
        I.UI.setMode("LevelUp", { windows = {} })
    end
end
local function endPickingMode()
    enableHotbar = false
    pickSlotMode = false
    controllerPickMode = false
    I.UI.setMode()
    I.QuickSelect_Hotbar.drawHotbar()
end

local function getToolTipPos()
    local setting = settings:get("hotBarOnTop")
    if setting then
        return utility.itemWindowLocs.BottomCenter
    else
        return utility.itemWindowLocs.TopCenter
    end
end
local function drawToolTip()
    if true then
     --   return
    end
    local inv = types.Actor.inventory(self):getAll()
    local offset = I.QuickSelect.getSelectedPage() * 10
    local data = I.QuickSelect_Storage.getFavoriteItemData(selectedNum + offset)

    local item
    local effect
    local icon
    local spell
    if data.item then
        item = types.Actor.inventory(self):find(data.item)
    elseif data.itemId then
        item = types.Actor.inventory(self):find(data.itemId)
    elseif data.spell  then
        if data.spellType:lower() == "spell" then
            spell = types.Actor.spells(self)[data.spell]
            if spell then
                spell = spell.id
            end
        elseif data.spellType:lower() == "enchant" then
            local enchant = utility.getEnchantment(data.enchantId)
            if enchant then
                spell = enchant
            end
        end
    end

    if item then
        tooltipElement = utility.drawListMenu(tooltipData.genToolTips(item),
        getToolTipPos(), nil, "HUD")
        -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
    elseif spell then
        local spellRecord = core.magic.spells.records[spell]

        tooltipElement = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
        getToolTipPos(), nil, "HUD")
    end
end
local function createHotbarItem(item, xicon, num, data, half)
    local icon
    local isEquipped = I.QuickSelect_Storage.isSlotEquipped(num)
    local sizeX = utility.iconSize
    local sizeY = utility.iconSize
    local drawNumber = settings:get("showNumbersForEmptySlots")
    local offset = I.QuickSelect.getSelectedPage() * 10
    local selected = (num) == (selectedNum + offset)
    if half then
        sizeY = sizeY / 2
    end
    if item and not xicon then
        icon = I.Controller_Icon_QS.getItemIcon(item, half, selected)
    elseif xicon then
        icon = I.Controller_Icon_QS.getSpellIcon(xicon, half, selected)
    elseif num then
        icon = I.Controller_Icon_QS.getEmptyIcon(half, num, selected, drawNumber)
    end
    local boxedIcon = utility.renderItemBoxed(icon, util.vector2(sizeX * 1.5, sizeY * 1.5), nil,
        util.vector2(0.5, 0.5),
        { item = item, num = num, data = data })
    local paddingTemplate = I.MWUI.templates.padding
    if isEquipped then
        paddingTemplate = I.MWUI.templates.borders
    end
    local padding = utility.renderItemBoxed(ui.content { boxedIcon },
        util.vector2(sizeX * 2, sizeY * 2),
        paddingTemplate, util.vector2(0.5, 0.5))
    return padding
end
local function getHotbarItems(half)
    local items = {}
    local inv = types.Actor.inventory(self):getAll()
    local count = num + 10
    while num < count do
        local data = I.QuickSelect_Storage.getFavoriteItemData(num)

        local item
        local effect
        local icon
        if data.item then
            item = types.Actor.inventory(self):find(data.item)
        elseif data.spell or data.enchantId then
            if data.spellType:lower() == "spell" then
                local spell = types.Actor.spells(self)[data.spell]
                if spell then
                    effect = spell.effects[1]
                    icon = effect.effect.icon
                    --    --print("Spell" .. data.spell)
                end
            elseif data.spellType:lower() == "enchant" then
                local enchant = utility.getEnchantment(data.enchantId)
                if enchant then
                    effect = enchant.effects[1]
                    icon = effect.effect.icon
                end
            end
        end
        table.insert(items, createHotbarItem(item, icon, num, data, half))
        num = num + 1
    end
    return items
end
local function drawHotbar()
    if hotBarElement then
        hotBarElement:destroy()
    end
    if tooltipElement then
        tooltipElement:destroy()
        tooltipElement = nil
    end
    if not enableHotbar then
        return
    end
    local xContent         = {}
    local content          = {}
    num                    = 1 + (10 * I.QuickSelect.getSelectedPage())
    --local trainerRow = renderItemBoxed({}, util.vector2((160 * scale) * 7, 400 * scale),
    ---    I.MWUI.templates.padding)
    local showExtraHotbars = settings:get("previewOtherHotbars")
    if showExtraHotbars then
        if I.QuickSelect.getSelectedPage() > 0 then
            num = 1 + (10 * (I.QuickSelect.getSelectedPage() - 1))
            table.insert(content,
                utility.renderItemBoxed(utility.flexedItems(getHotbarItems(true), true, util.vector2(0.5, 0.5)),
                    utility.scaledVector2(600, 100),
                    I.MWUI.templates.padding,
                    util.vector2(0.5, 0.5)))
        end
    end
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(), true, util.vector2(0.5, 0.5)),
            utility.scaledVector2(800, 80),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    if showExtraHotbars then
        if I.QuickSelect.getSelectedPage() < 2 then
            table.insert(content,
                utility.renderItemBoxed(utility.flexedItems(getHotbarItems(true), true, util.vector2(0.5, 0.5)),
                    utility.scaledVector2(900, 100),
                    I.MWUI.templates.padding,
                    util.vector2(0.5, 0.5)))
        end
    end
    content = ui.content(content)

    local anchor = util.vector2(0.5, 1)
    local relativePosition = util.vector2(0.5, 1)
    if settings:get("hotBarOnTop") then
        anchor = util.vector2(0.5, 0)
        relativePosition = util.vector2(0.5, 0)
    end
    if controllerPickMode then
        drawToolTip()
    end
    hotBarElement = ui.create {
        layer = "HUD",
        template = I.MWUI.templates.padding
        ,
        props = {
            anchor = anchor,
            relativePosition = relativePosition,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(380, 40),
                }
            }
        }
    }
end
local data
local function selectSlot(item, spell, enchant)
    enableHotbar = true
    pickSlotMode = true
    controllerPickMode = true
    -- print(item,spell,enchant)
    data = { item = item, spell = spell, enchant = enchant }
    drawHotbar()
end
local function saveSlot()
    if pickSlotMode then
        local selectedSlot = selectedNum + (I.QuickSelect.getSelectedPage() * 10)
        if data.item and not data.enchant then
            I.QuickSelect_Storage.saveStoredItemData(data.item, selectedSlot)
        elseif data.spell then
            I.QuickSelect_Storage.saveStoredSpellData(data.spell, "Spell", selectedSlot)
        elseif data.enchant then
            I.QuickSelect_Storage.saveStoredEnchantData(data.enchant, data.item, selectedSlot)
        end
        enableHotbar = false
        pickSlotMode = false
        data = nil
    end
end
local function UiModeChanged(data)
    if data.newMode then
        if controllerPickMode and not settings:get("persistMode") then
            if settings:get("pauseWhenSelecting") and data.newMode == "LevelUp" then
                return
            end
            controllerPickMode = false
            pickSlotMode = false
            enableHotbar = false
            drawHotbar()
        elseif settings:get("persistMode") then
            enableHotbar = true
            drawHotbar()
        end
    end
end
local function selectNextOrPrevHotBar(dir)
    if dir == "next" then
        if not enableHotbar then
            return
        end
        local num = I.QuickSelect.getSelectedPage() + 1
        if num > 2 then
            num = 0
        end
        I.QuickSelect.setSelectedPage(num)
        I.QuickSelect_Hotbar.drawHotbar()
    elseif dir == "prev" then
        local num = I.QuickSelect.getSelectedPage() - 1
        if num < 0 then
            num = 2
        end
        I.QuickSelect.setSelectedPage(num)

        I.QuickSelect_Hotbar.drawHotbar()
    end
end
local function selectNextOrPrevHotKey(dir)
    if dir == "next" then
        if not enableHotbar or not controllerPickMode then
            startPickingMode()
            return
        end
        selectedNum = selectedNum + 1
        if selectedNum > 10 then
            selectedNum = 1
        end
        I.QuickSelect_Hotbar.drawHotbar()
    elseif dir == "prev" then
        if not enableHotbar or not controllerPickMode then
            startPickingMode()
            return
        end
        selectedNum = selectedNum - 1
        if selectedNum < 1 then
            selectedNum = 10
        end
        I.QuickSelect_Hotbar.drawHotbar()
    end
end
local function getNextKey()
    local status = settings:get("barSelectionMode")
    if status == "-/= Keys" then
        return "="
    elseif status == "[/] Keys" then
        return "["
    end
end
local function getPrevKey()
    local status = settings:get("barSelectionMode")
    if status == "-/= Keys" then
        return "-"
    elseif status == "[/] Keys" then
        return "]"
    end
end
return {
    --I.QuickSelect_Hotbar.drawHotbar()
    interfaceName = "QuickSelect_Hotbar",
    interface = {
        drawHotbar = drawHotbar,
        selectSlot = selectSlot,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    },
    engineHandlers = {
        onLoad = function()
            if settings:get("persistMode") then
                enableHotbar = true
                drawHotbar()
            end
        end,
        onKeyPress = function(key)
            if core.isWorldPaused() and not controllerPickMode then
                return
            end
            local char = key.symbol
            if not char then
                return
            end
            if not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Controls) then
                return
            end
            local nextKey = getNextKey()
            local prevKey = getPrevKey()
            if qs_bindings.isPressed("next",key.code) then
                selectNextOrPrevHotBar("next")
            elseif qs_bindings.isPressed("prev",key.code) then
                selectNextOrPrevHotBar("prev")
            end
            if settings:get("useArrowKeys") then
                if key.code == input.KEY.RightArrow or key.code == input.KEY.PageUp then
                    selectNextOrPrevHotKey("next")
                elseif key.code == input.KEY.LeftArrow or key.code == input.KEY.PageDown  then
                    selectNextOrPrevHotKey("prev")
                elseif key.code == input.KEY.UpArrow then
                    if not enableHotbar then
                        return
                    end
                    selectNextOrPrevHotBar("prev")
                elseif key.code == input.KEY.DownArrow then
                    if not enableHotbar then
                        return
                    end
                    selectNextOrPrevHotBar("next")
                elseif key.code == input.KEY.Enter then
                    if not enableHotbar then
                        return
                    end
                    if pickSlotMode then
                        saveSlot()
                        I.QuickSelect_Hotbar.drawHotbar()
                        return
                    end
                    --  print("EQUP ME"  )
                    I.QuickSelect_Storage.equipSlot(selectedNum + (I.QuickSelect.getSelectedPage() * 10))
                    endPickingMode()
                end
            end
        end,
        onControllerButtonPress = function(btn)
            if core.isWorldPaused() and not controllerPickMode then
                return
            end
            if btn == input.CONTROLLER_BUTTON.LeftShoulder or btn == input.CONTROLLER_BUTTON.DPadLeft then
                selectNextOrPrevHotKey("prev")
            elseif btn == input.CONTROLLER_BUTTON.RightShoulder or btn == input.CONTROLLER_BUTTON.DPadRight then
                selectNextOrPrevHotKey("next")
            elseif btn == input.CONTROLLER_BUTTON.DPadDown and controllerPickMode then
                selectNextOrPrevHotBar("next")
                --  print("down")
            elseif btn == input.CONTROLLER_BUTTON.DPadUp and controllerPickMode then
                if not enableHotbar then
                    return
                end
                selectNextOrPrevHotBar("prev")
            elseif btn == input.CONTROLLER_BUTTON.A and controllerPickMode then
                if not enableHotbar then
                    return
                end
                if pickSlotMode then
                    saveSlot()
                    I.QuickSelect_Hotbar.drawHotbar()
                    return
                end
                --  print("EQUP ME"  )
                I.QuickSelect_Storage.equipSlot(selectedNum + (I.QuickSelect.getSelectedPage() * 10))
                endPickingMode()
            elseif btn == input.CONTROLLER_BUTTON.B then
                if enableHotbar then
                    endPickingMode()
                end
            end
        end
    }
}
