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
    inventory = { text = "Inventory", windowLoc = itemWindowLocs.TopCenter },
    magic = { text = "Magic", windowLoc = itemWindowLocs.Left },
    map = { text = "Map", windowLoc = itemWindowLocs.BottomCenter },
    stats = { text = "Stats", windowLoc = itemWindowLocs.Right },
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
local function renderUIComponent(items, config, prevWindow, layer, fontSize, extraContent, onTap)
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
        events = onTap and { mouseClick = async:callback(onTap) } or nil,
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
local function openDestination(mode)
    return function()
        destroyElements()
        I.Deckwind.updateActiveWindow(mode)
        I.Deckwind.setInputDelay(0.1)
    end
end

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
    I.CI_Background.drawCursorElement(x, y, anchor)
    isActive = true

  --  local armor = "Armor: " .. tostring(core_aux.getArmorRating(self))
    local heldItem = types.Actor.getEquipment(self)[types.Actor.EQUIPMENT_SLOT.CarriedRight]

    local heldItemText = ""
    if heldItem then
        heldItemText = heldItem.type.record(heldItem).name
    end
    table.insert(uiElements, renderUIComponent({ destinationWindow.inventory.text,heldItemText },
        destinationWindow.inventory.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.inventory),
        {  renderStatBar.renderStat(
            self, "encumbrance") }, openDestination(windowType.inventory)))

            local selectedSpell = ""
            if types.Actor.getSelectedSpell(self) ~= nil and types.Actor.getSelectedSpell(self).id  then
                selectedSpell = types.Actor.getSelectedSpell(self).name
            elseif types.Actor.getSelectedEnchantedItem(self) ~= nil and types.Actor.getSelectedEnchantedItem(self).id  then
                   local item = types.Actor.getSelectedEnchantedItem(self)
                   selectedSpell = item.type.records[item.recordId].name
            end

    table.insert(uiElements, renderUIComponent({ destinationWindow.magic.text ,selectedSpell},
        destinationWindow.magic.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.magic), nil, openDestination(windowType.magic)))

        local level = "Level " .. tostring(types.Actor.stats.level(self).current)

    table.insert(uiElements, renderUIComponent({ destinationWindow.stats.text,level },
        destinationWindow.stats.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.stats),{renderStatBar.renderStat(
            self, "level") }, openDestination(windowType.stats)))

    table.insert(uiElements, renderUIComponent({ destinationWindow.map.text, self.cell.name },
        destinationWindow.map.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.map), nil, openDestination(windowType.map)))



        table.insert(uiElements, renderUIComponent({  },
        destinationWindow.center.windowLoc, nil, "InfoTips", getElementSize(destinationWindow.center),{renderStatBar.renderStat(
            self, "health"),renderStatBar.renderStat(
                self, "magicka"),renderStatBar.renderStat(
                    self, "fatigue") }))
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
    if not isActive then return end

    if bindingPressed(inputData.dpadLeft, key, id) or (bindingPressed(inputData.openPlayerMenu, key, id) and selectedText == destinationWindow.magic) then
        destroyElements()
        I.Deckwind.updateActiveWindow(windowType.magic)
        I.Deckwind.setInputDelay(delayLength)
    elseif bindingPressed(inputData.dpadRight, key, id) or (bindingPressed(inputData.openPlayerMenu, key, id) and selectedText == destinationWindow.stats) then
        if settings:get("useNewStatsWindow") then
            destroyElements()
--            I.CI_StatsMenu.openStatsMenu()
            I.CI_StatsMenu.openNewStatsWin()
        else
            destroyElements()
            I.Deckwind.updateActiveWindow(windowType.stats)
        end
    elseif bindingPressed(inputData.dpadDown, key, id) or (bindingPressed(inputData.openPlayerMenu, key, id) and selectedText == destinationWindow.map) then
        destroyElements()
        I.Deckwind.updateActiveWindow(windowType.map)
    elseif bindingPressed(inputData.dpadUp, key, id) or (bindingPressed(inputData.openPlayerMenu, key, id) and selectedText == destinationWindow.inventory) then
        destroyElements()
        I.Deckwind.setInputDelay(delayLength)
        I.Deckwind.updateActiveWindow(windowType.inventory)
    elseif bindingPressed(inputData.xButton, key, id) then
        destroyElements()
        I.Deckwind.setInputDelay(delayLength)
        I.UI.setMode("Journal")
    elseif bindingPressed(inputData.yButton, key, id) then
        destroyElements()
        I.Deckwind.setInputDelay(delayLength)
        I.UI.setMode("Rest")
    elseif bindingPressed(inputData.bButton, key, id) then
        canOpen = false
        destroyElements()
        I.UI.setMode()
        isActive = false
        async:newUnsavableSimulationTimer(0.01, function()
            canOpen = true
        end)
    elseif bindingPressed(inputData.backButton, key, id) then
        destroyElements()
        I.UI.setMode()
        isActive = false
        types.Player.sendMenuEvent(self, "iosDeckwindQuickSave")
    elseif bindingPressed(inputData.RightShoulder, key, id) then

        if settings:get("devModeEnable") then
        canOpen = false
        destroyElements()
        I.UI.setMode()
        isActive = false
        async:newUnsavableSimulationTimer(0.01, function()
            canOpen = true
            debug.reloadLua()
            ui.showMessage("Reloading")
        end)
    end

    else
        -- Handle other bindings here
    end
end
local function onControllerButtonPress(id)
    checkBinding(id)
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
    right = 2,
    down = 3,
    up = 4,
}
local thresthold = 0.3
local function getAxisState(value)
    if value < thresthold and value > -thresthold then
        return AxisState.atRest
    elseif value > thresthold then
        return AxisState.positive
    elseif value < -thresthold then
        return AxisState.negative
    end
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
local function onFrame(dt)
    if not isActive then return end

    local v1 = getAxisState(input.getAxisValue(input.CONTROLLER_AXIS.LeftX))
    local v2 = getAxisState(input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
    local stickState = getStickState(v1, v2)
    if stickState ~= lastStickState then
        lastStickState = stickState
        drawMenuSelect()
    end
end
local function menuSelectActive()
    return isActive
end
return {
    interfaceName = "CI_MenuSelect",
    interface = {
        version = 1,
        drawMenuSelect = drawMenuSelect,
        destroyElements = destroyElements,
        onControllerButtonPress = onControllerButtonPress,
        menuSelectActive = menuSelectActive,
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
