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
local core_aux = require("scripts.ios_deckwind.Deckwind.aux_core")
local renderStatBar = require("scripts.ios_deckwind.Deckwind.renderStatBar")
local debug = require('openmw.debug')
local windowType = { inventory = 1, magic = 2, map = 3, stats = 4 }
local uiElements = {}
local isActive = false

local const = require("scripts.ios_deckwind.Deckwind.ci_const")
local settings = storage.globalSection("SettingsControllerInterface")
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
    Center = { wx = 0.5, wy = 0.5, align = ui.ALIGNMENT.Center, anchor = util.vector2(0.5, 0.5) },
    Disabled = { disabled = true }
}
local destinationWindow = {
    keySet1 = { text = "Keys 1", windowLoc = itemWindowLocs.TopCenter },
    keySet2 = { text = "Keys 2", windowLoc = itemWindowLocs.BottomCenter },
    center = { text = "", windowLoc = itemWindowLocs.Center }
}

local canOpen = true
local function destroyElements(skipBack)
    for index, value in ipairs(uiElements) do
        value:destroy()
    end
    uiElements = {}
    if not skipBack then
        I.CI_Background.destroyBackground()
    end
    isActive = false
end
local selectedText = nil
local function getElementSize(text)
    return 15
end
local mapping = {"-3_-3","-3_-2","-3_-1","-3_0","-3_1","-3_2","-2_-1","-2_2","0_2","1_2","2_2","2_1","2_0","2_-1","2_-2","2_-3","1_-3","0_-3","-1_-1"}
-----

local function renderItemX(item, bold, fontSize)
    if not fontSize then
        fontSize = 10
    end
    --    fontSize = fontSize * 10
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = fontSize,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderUIComponent(items, config, prevWindow, layer, fontSize, extraContent)
    -- Destroy previous window if exists
    if prevWindow then
        prevWindow:destroy()
        prevWindow = nil
    end

    -- Initialize configuration
    local wx, wy, align, anchor = 0, 0, nil, nil
    if config and not config.disabled then
        wx, wy, align, anchor = config.wx or 0, config.wy or 0, config.align, config.anchor
    elseif config and config.disabled then
        -- Handle the disabled case
        --print("Disabled location:", config)
        return
    end

    -- Prepare content based on items
    local content = {}
    for _, item in ipairs(items) do
        local itemLayout
        if type(item) == "string" then
            itemLayout = renderItemX(item, nil, fontSize)
            itemLayout.template = I.MWUI.templates.padding
        elseif type(item) == "table" then
            -- Assuming extraContent or other table structures could be handled here
            -- This is an extension point for handling extraContent or other item types
        end
        if itemLayout then
            table.insert(content, itemLayout)
        end
    end
    if extraContent then
        for index, value in ipairs(extraContent) do
            table.insert(content, value)
        end
    end

    -- Create UI component with consolidated parameters
    return ui.create {
        layer = layer or "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            anchor = anchor,
            relativePosition = v2(wx, wy),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = align,
                }
            }
        }
    }
end

----
local typedText = "Typed Text"
local selectedIndex1 = 1
local selectedIndex2 = 1
local function drawMenuSelect()
    if not canOpen then
        return
    end
    I.CI_Expirement.openEmptyUIWindow()
    for index, value in ipairs(uiElements) do
        value:destroy()
    end
    uiElements = {}
    I.CI_Background.clearHotKeys()
    I.CI_Background.addHotKey("Journal", "X")
    if self.cell:hasTag("NoSleep") then
        I.CI_Background.addHotKey("Wait", "Y")
    else
        I.CI_Background.addHotKey("Rest", "Y")
    end
    if settings:get("devModeEnable") then
        I.CI_Background.addHotKey("Reload Lua", "RightShoulder")
    end
    I.CI_Background.addHotKey("Quicksave", "Back")
    I.CI_Background.drawBackground()
    local x, y = 0.5, 0.5
    local anchor
    if selectedText then
        x, y = selectedText.windowLoc.wx, selectedText.windowLoc.wy
        anchor = selectedText.windowLoc.anchor
    end
    --I.CI_Background.drawCursorElement(x, y, anchor)
    isActive = true

    --  local armor = "Armor: " .. tostring(core_aux.getArmorRating(self))
    local heldItem = types.Actor.getEquipment(self)[types.Actor.EQUIPMENT_SLOT.CarriedRight]

    local keys1char = {'a','b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm','1','2','3'}
    local keys2char = {'n','o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}

    local keys1 = ""
    local keys2 = ""
    for i,x in ipairs(keys1char) do
        if i == selectedIndex1 then
            keys1 = keys1 .. " " .. string.upper(x)
        else

            keys1 = keys1 .. " " .. (x)
        end
    end
    for i,x in ipairs(keys2char) do
        if i == selectedIndex2 then
            keys2 = keys2 .. " " .. string.upper(x)
        else

            keys2 = keys2 .. " " .. (x)
        end
    end
    table.insert(uiElements, renderUIComponent({ destinationWindow.keySet1.text, keys2 },
        destinationWindow.keySet1.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.keySet1),
        {}))



    table.insert(uiElements, renderUIComponent({ destinationWindow.keySet2.text, keys1 },
        destinationWindow.keySet2.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.keySet2),
        {  }))

    table.insert(uiElements, renderUIComponent({typedText},
        destinationWindow.center.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.center),
        {  }))
end
local inputData = {
    openPlayerMenu = {
        ctrlKey = input.CONTROLLER_BUTTON.A,
        keyboardKey = input.KEY.K
    },
    dpadLeft = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadLeft,
        keyboardKey = input.KEY.LeftArrow
    },
    dpadRight = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadRight,
        keyboardKey = input.KEY.RightArrow
    },
    dpadDown = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadDown,
        keyboardKey = input.KEY.DownArrow
    },
    dpadUp = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadUp,
        keyboardKey = input.KEY.UpArrow
    },
    xButton = {
        ctrlKey = input.CONTROLLER_BUTTON.X,
        keyboardKey = nil
    },
    yButton = {
        ctrlKey = input.CONTROLLER_BUTTON.Y,
        keyboardKey = nil
    },
    backButton = {
        ctrlKey = input.CONTROLLER_BUTTON.Back,
        keyboardKey = nil
    },
    bButton = {
        ctrlKey = input.CONTROLLER_BUTTON.B,
        keyboardKey = nil
    },
    RightShoulder = {
        ctrlKey = input.CONTROLLER_BUTTON.RightShoulder,
        keyboardKey = nil
    },
    LeftShoulder = {
        ctrlKey = input.CONTROLLER_BUTTON.LeftShoulder,
        keyboardKey = nil
    }
}
local function bindingPressed(binding, key, ctrl)
    if ctrl then
        return binding.ctrlKey == ctrl
    elseif key then
        return binding.keyboardKey == key
    end
    return false
end
local delayLength = 0.1
local function checkBinding(id, key)

end
local function onControllerButtonPress(id)
    --checkBinding(id)
end
local function onKeyPress(key)
    local keyId = key.code
    checkBinding(nil, keyId)
end
local AxisState = {
    atRest = 0,
    positive = 1,
    negative = 2,
}
local stickState = {
    atRest = 0,
    left = 1,
    leftDown = 2,
    leftLeftDown = 3,
    down = 4,
    downDownRight = 5,
    downRight = 6,
    right = 7,
    rightRightUp = 8,
    rightUp = 9,
    up = 10,
    leftUp = 11,
    leftLeftUp = 12,
}
local thresthold = 0.1
local function getAxisState(value)

    return math.floor(value * 3)
end
local function getStickState(v1, v2)
    if v1 == AxisState.atRest and v2 == AxisState.atRest then
        selectedText = nil
        return stickState.atRest
    elseif v2 == AxisState.negative then
        selectedText = destinationWindow.inventory
        return stickState.up
    elseif v2 == AxisState.positive then
        selectedText = destinationWindow.map
        return stickState.down
    elseif v1 == AxisState.positive then
        selectedText = destinationWindow.stats
        return stickState.right
    elseif v1 == AxisState.negative then
        selectedText = destinationWindow.magic
        return stickState.left
    end
    return stickState.atRest
end
local lastStickState
local function UiModeChanged(data)
    local newMode = data.newMode
    if not newMode then
        destroyElements(true)
    end
end
local vals = {{0,1},{1,1},{1,0},{1,2},{0,2},{2,2},{2,0},{2,1},{0,2}}
local combos = {}
local function onFrame(dt)
    if not isActive then return end
   -- print(selectedIndex1)
    local v1 = getAxisState(input.getAxisValue(input.CONTROLLER_AXIS.LeftX))
    local xv2 = getAxisState(input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
    local stateString = tostring(xv2) .. "_" ..tostring(v1)
    print(stateString)
    if v1 == 0 and xv2 == 0 then
        selectedIndex1 = 0
    else
        for i,x in ipairs(mapping)  do
            if x == stateString then
                if selectedIndex1 ~= i then
                    selectedIndex1 = i
                    drawMenuSelect()
                    return
                end
            end
        end
    end
--print(xv2,v1)
   -- print(xv2)
   local found = false
   for i,x in ipairs(combos) do
    if x.string == stateString then
        found = true
    end
   end
    if not found then
        combos[#combos+1] = {string = stateString,x = v1, y = xv2}
    end
    local stickState = getStickState(v1, v2)
    if stickState ~= lastStickState then
        lastStickState = stickState
        drawMenuSelect()
    end
end
local function menuSelectActive()
    return isActive
end
local function printVars()
    local count = 0
    local string = ""
    for i,x in pairs(combos) do
        string = string ..'"'   .. x.string .. "\","
        count = count + 1
    end
    print(string)
    print("count",count)
end
return {
    interfaceName = "CI_InputText",
    interface = {
        version = 1,
        drawMenuSelect = drawMenuSelect,
        destroyElements = destroyElements,
        onControllerButtonPress = onControllerButtonPress,
        menuSelectActive = menuSelectActive,
        printVars = printVars,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    },
    engineHandlers = {
        onControllerButtonPress = onControllerButtonPress,
        onFrame = onFrame,
        onKeyPress = onKeyPress,
    }
}
