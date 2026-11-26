if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")

local multiplier = 0.499

local drawVertical = false

local const = require("scripts.ios_deckwind.Deckwind.ci_const")

local gamepadButtons = {
    "A",
    "B",
    "Back",
    "DPadUp",
    "DPadDown",
    "DPadLeft",
    "DPadRight",
    "Guide",
    "LeftShoulder",
    "LeftStick",
    "RightShoulder",
    "RightStick",
    "Start",
    "X",
    "Y",
}

if not const.doesRun then
    return {}
end
local backgroundElement
local bindingsElement
local cursorElement
local buttonTextures = {
    A = "a", B = "b", X = "x", Y = "y", Back = "view", Start = "menu",
    LeftShoulder = "l1", RightShoulder = "r1", LeftStick = "l3", RightStick = "r3",
    TriggerLeft = "l2", TriggerRight = "r2",
}
local function getButtonResource(id)
    local suffix = buttonTextures[id] or "dpad"
    return ui.texture { path = "textures/omw_steam_button_" .. suffix .. ".dds" }
end
local hotKeys = {

}
local function addHotKey(text,button)
    table.insert(hotKeys,{text,button})
end
local function clearHotKeys()
    hotKeys = {

    }
end
local function drawHotKeys(list)
    if list then
        hotKeys = list
    end
    local contentList = {}
    for index, value in ipairs(hotKeys) do
        local text = value[1]
        local binding = value[2]
        if not text and not binding then
        else
        if not binding then
            --print("Nothing for " .. text)
            return
        end
        local contentLs2 = {}
        table.insert(contentLs2, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = text,
                size = util.vector2(50, 30),
                textAlignH = -115,
                textSize = 15,
            }
        })
        table.insert(contentLs2, {
            type = ui.TYPE.Image,
            props = {
                resource = getButtonResource(binding),
                size = util.vector2(30, 30),
            }
        })
        local parentCont =  {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                align = ui.ALIGNMENT.End,
                arrange = ui.ALIGNMENT.Center,
              --  size = v2(ui.layers[1].size.x * multiplier, ui.layers[1].size.y / 35),
            },
            content = ui.content (contentLs2)
        }
        table.insert(contentList,parentCont)
    end
    end
    return contentList
end



local function drawBottomBar(tbl,vertical)
    if vertical ~= nil then
        drawVertical = vertical
    end
    if bindingsElement then
        bindingsElement:destroy()
        bindingsElement = nil
    end
    if not tbl then
        tbl = hotKeys
    end
    if not backgroundElement then
        I.CI_Background.drawBackground(true)
    end
    local horizontal = not drawVertical

    local bindings = drawHotKeys(tbl)
    bindingsElement = ui.create {
        layer = "Bindings",
       -- template = I.MWUI.templates.boxTransparentThick,
        type = ui.TYPE.Container,
        props = {
            relativePosition = v2(1, 01),
            anchor = v2(1, 1),
            vertical = false,
            relativeSize = v2(0.1, 1),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = horizontal,
                    align = ui.ALIGNMENT.End,
                    arrange = ui.ALIGNMENT.Center,
                  --  size = v2(ui.layers[1].size.x * multiplier, ui.layers[1].size.y / 35),
                },
                content = ui.content (bindings)
            }
        }
    }
end

local closeElement
local function updateCloseButton()
    if closeElement then
        closeElement:destroy()
        closeElement = nil
    end
    local mode = I.UI.getMode()
    if mode ~= "Interface" and mode ~= "Barter" and mode ~= "Container" and mode ~= "Companion" then return end
    closeElement = ui.create {
        layer = "Bindings",
        template = I.MWUI.templates.box,
        props = { anchor = v2(1, 1), relativePosition = v2(0.98, 0.98), size = v2(72, 42) },
        content = ui.content {
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                props = { text = "Back", textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center, relativeSize = v2(1, 1) } }
        },
        events = { mouseClick = async:callback(function() I.UI.removeMode(I.UI.getMode()) end) },
    }
end
local function drawBackground(onlyBottom)
    local relativeSize = v2(1, 1)
    local relativePosition = v2(0.5, 0.5)
    local anchor = v2(0.5, 0.5)
    if onlyBottom then
        relativeSize = v2(1, 0.1)
        relativePosition = v2(0.5, 1)
        anchor = v2(0.5, 1)
    end
    if backgroundElement then
        backgroundElement:destroy()
        backgroundElement = nil
    end
    backgroundElement = ui.create {
        layer = "Background",
        type = ui.TYPE.Image,
        props = {
            relativeSize = relativeSize,
            relativePosition = relativePosition,
            anchor =anchor,
            resource = ui.texture { path = 'white' },
            color = util.color.rgb(0, 0, 0),
            alpha = 0.6,
        }
    }
    if not onlyBottom then

        drawBottomBar()
    end
end
local function drawCursorElement(x,y,anchor)
    if cursorElement then
        cursorElement:destroy()
        cursorElement = nil
    end
    cursorElement = ui.create {
        layer = "Windows",
        type = ui.TYPE.Image,
        props = {
           -- relativeSize = v2(1, 1),
            relativePosition = v2(x,y),
            anchor = anchor,
            size = v2(60,60),
            resource = ui.texture { path = 'textures/cursor_drop.dds' },
        --    color = util.color.rgb(0, 0, 0),
         --   alpha = 0.8,
        }
    }
end
local function destroyBackground()
    if bindingsElement ~= nil then
        bindingsElement:destroy()
        bindingsElement = nil
    end
    if backgroundElement then
        backgroundElement:destroy()
        backgroundElement = nil
    end
    if cursorElement then
        cursorElement:destroy()
        cursorElement = nil
    end
end
local function UiModeChanged(data)
    updateCloseButton()
    local newMode = data.newMode
    if not newMode then
        destroyBackground()
    end
end
--I.CI_Background.drawBottomBar()
return {
    interfaceName = "CI_Background",
    interface = {
        version = 1,
        clearHotKeys = clearHotKeys,
        addHotKey = addHotKey,
        drawBackground = drawBackground,
        destroyBackground = destroyBackground,
        drawBottomBar = drawBottomBar,
        drawCursorElement = drawCursorElement,
        setVertical = function (value)
            drawVertical = value
        end,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged
    },
    engineHandlers = {
    }
}
