if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local settings = require("scripts.ios_deckwind.QuickSelect.qs_settings")
local function getIconSize()
    return 40
end
if I.QuickSelect then
    return
end
local selectedPage = 0
local function getIconSizeGrow()
    local ret = 20
    return (40) + ret * 0.25
end
local function createHotbarItem(item, spell)
    local icon = I.Controller_Icon_QS.getItemIcon(item)
    local boxedIcon = { --box around the titem
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(getIconSize(), getIconSize()),
        },
        events = {
        },
        content = {
            {
                template = I.MWUI.templates.boxSolid,
                alignment = ui.ALIGNMENT.Center,
                content = icon
            }
        }
    }
    return boxedIcon
end
local function getHotbarItems()
    local items = {}
    for index, value in ipairs(types.Actor.inventory(self):getAll()) do
        if index < 10 then
            table.insert(items, createHotbarItem(value))
        end
    end
    return items
end
local function drawHotbar()
    I.QuickSelect_Win1.drawQuickSelect()
    if true then
        return
    end
    local items = getHotbarItems()
    local itemFlex = {
        type = ui.TYPE.Flex,
        layer = "HUD",
        content = items,
        props = {
            size = util.vector2(450, 300),
            horizontal = false,
            vertical = false,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        },
    }
    local pos = 0
    for index, value in ipairs(items) do
        pos = pos + 0.1
    end
    ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxSolid,
        events = {
        },
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(pos, .1),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = false,
            vertical = true,
            size = util.vector2(450, 300),
        },
        content = itemFlex
    }
end

local function onInputAction(action)
    if action >= input.ACTION.QuickKey1 and action <= input.ACTION.QuickKey9 then
        local slot = action - input.ACTION.QuickKey1 + 1
        if slot then
            if slot > 0 and slot < 4 and input.isShiftPressed() then
                selectedPage = slot - 1
                I.QuickSelect_Hotbar.drawHotbar()
                return
            end
            I.QuickSelect_Storage.equipSlot(slot + (selectedPage * 10))
            I.QuickSelect_Hotbar.drawHotbar()
        end
    end
end
return {

    interfaceName = "QuickSelect",
    interface = {
        drawHotbar = drawHotbar,
        getSelectedPage = function()
            return selectedPage
        end,
        setSelectedPage = function(num)
             selectedPage = num
        end,
    },
    engineHandlers = {
        onInputAction = onInputAction,
    }
}
