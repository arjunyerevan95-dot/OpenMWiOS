if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
--local layers = require("scripts.ios_deckwind.Deckwind.ci_layers")
local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local types = require("openmw.types")
local ambient = require('openmw.ambient')
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local Player = require('openmw.types').Player
local windowType = { inventory = 1, magic = 2, map = 3, stats = 4 }
local const = require("scripts.ios_deckwind.Deckwind.ci_const")
local currentWindowType = windowType.inventory
local bindingsWin = nil
local queRedraw = false
local axisPressed = {}
local axisValue = {}
local contextType = {
    inventory = 1,
    container = 2,
    containerActor = 3,
    barter = 4,
    magic = 5,
    map = 6,
    stats = 7,
}
local inputDelay = 0
local currentContext = 0
local nextPress = 0
local repeatRate = 0.15
local repeatRateStart = 0.4
local keyWasPressed = false
local barterInfoWindow = nil
local containerGridSizeX, containerGridSizeY = 10,10
local invGridSizeX, invGridSizeY = 15, 15
local blockInput = false
local tooltipgen = require("scripts.ios_deckwind.Deckwind.ci_tooltipgen")

local key = "SettingsControllerInterface"

local const = require("scripts.ios_deckwind.Deckwind.ci_const")
local settings = storage.globalSection(key)
if not const.doesRun then
    return {}
end
I.Controls.overrideUiControls(true)
local controllerMode = false
local function setBlockInput(state)
    blockInput = state
end
local playerWindow = nil
local containerWindow = nil

local handWindow = nil
local heldItem = nil
local heldContainer = nil

local lastWindowOpened = windowType.inventory

--Settings:

--Allow rollover(per type)
--add additional item filters

local function getBarterAmount()
    local goldAmount = 0
    for index, item in ipairs(playerWindow.itemDataList) do
        if item.pending then --buying
            local value = tooltipgen.getItemValue(item.item) * item.count
            local barterAmount = I.ZackUtilsUI_ci.getBarterOffer(containerWindow.parentObject, value, true)
            goldAmount = goldAmount + barterAmount
        end
    end
    for index, item in ipairs(containerWindow.itemDataList) do
        if item.pending then --selling
            local value = tooltipgen.getItemValue(item.item) * item.count
            local barterAmount = I.ZackUtilsUI_ci.getBarterOffer(containerWindow.parentObject, value, false)
            goldAmount = goldAmount - barterAmount
        end
    end
    return goldAmount
end
local function getMaxCarry()
    local str = types.Actor.stats.attributes.strength(self).modified
    return str * 5
end
local function getEncumburance()
    local carryWeight = 0
    for index, value in pairs(types.Actor.activeEffects(self)) do
        if value.id == "feather" then
            carryWeight = carryWeight - value.magnitude
        elseif value.id == "burden" then
            carryWeight = carryWeight + value.magnitude
        end
    end
    for index, value in ipairs(types.Actor.inventory(self):getAll()) do
        local weight = value.type.record(value).weight * value.count
        carryWeight = carryWeight + weight
    end
    return carryWeight
end
local function exitBarter()
    if not containerWindow then
        return
    end
    if not playerWindow then
        return
    end
    local goldRequired = getBarterAmount()
    local myGoldCount = types.Actor.inventory(self):countOf("gold_001")
    local actorGoldCount = I.Controller_Item_Window.getActorGoldCount(containerWindow.parentObject)
    if myGoldCount >= goldRequired and actorGoldCount >= -goldRequired then
        local soldandBoughtItems = 0
        for index, item in ipairs(playerWindow.itemDataList) do
            if item.pending then --buying
                soldandBoughtItems = soldandBoughtItems + 1
                local restock =  types.Item.isRestocking(item.item)
                core.sendGlobalEvent("CI_moveInto",
                    {
                        sourceObj = containerWindow.parentObject,
                        targetObj = self,
                        invItem = item.item,
                        doCopy = restock,
                        ignoreTheft = true,
                        count = item.count,
                        player = self
                    })
            end
        end
        for index, item in ipairs(containerWindow.itemDataList) do
            if item.pending then --selling
                core.sendGlobalEvent("CI_moveInto",
                    {
                        sourceObj = self,
                        targetObj = containerWindow.parentObject,
                        invItem = item.item,
                        ignoreTheft = true,
                        count = item.count,
                        player = self
                    })
            end
        end
        if goldRequired ~= 0 or soldandBoughtItems > 0 then
            ambient.playSound("item gold up")
            I.CI_ActorGold.incrementActorGold(containerWindow.parentObject,goldRequired)
            --print(goldRequired,soldandBoughtItems)
            ui.showMessage(core.getGMST("sBarterDialog5"))
            core.sendGlobalEvent("incrementPlayerGold", goldRequired)
        end
        return true
    elseif not (actorGoldCount >= -goldRequired) then
        ui.showMessage("The seller can't afford this transaction.")
        return true
    else
            ui.showMessage(core.getGMST("sBarterDialog1"))
        return true
    end
    currentContext = 0
end
local axisToCheck = {}
local inputData = {
    openPlayerMenu = {
        ctrlKey = input.CONTROLLER_BUTTON.B,
        keyboardKey = input.KEY
            .K
    },
    switchInventory = {
        id = 2,
        ctrlKey = input.CONTROLLER_BUTTON.RightStick,
        keyboardKey = input.KEY.Q,
        bindingName = "Switch to Other Inventory", --/Switch to Magic/Items
        validContexts = { contextType.barter, contextType.container, contextType.containerActor }
    },

    toggleMapMode= {
        id = 26,
        ctrlKey = input.CONTROLLER_BUTTON.RightStick,
        keyboardKey = input.KEY.Q,
        bindingName = "Toggle Map Mode", --/Switch to Magic/Items
       validContexts = { contextType.map, }
    },
    centerOnPlayer= {
        id = 26,
        ctrlKey = input.CONTROLLER_BUTTON.LeftStick,
        keyboardKey = input.KEY.F,
        bindingName = "Center", --/Switch to Magic/Items
       validContexts = { contextType.map, }
    },
    nextMenu = {
        -- ctrlKey = input.CONTROLLER_BUTTON.RightStick,
        keyboardKey = input.KEY.U,
        axis = input.CONTROLLER_AXIS.TriggerRight,
        bindingName = "Next Menu",
        validContexts = { contextType.inventory, contextType.magic, contextType.map, contextType.stats },
        -- bindingName = "Switch Menu Mode"
    },
    prevMenu = {
        axis = input.CONTROLLER_AXIS.TriggerLeft,
        bindingName = "Previous Menu",
        validContexts = { contextType.inventory, contextType.magic, contextType.map, contextType.stats },
    },
    favoriteItem = {
        ctrlKey = input.CONTROLLER_BUTTON.Y,
        keyboardKey = input.KEY
            .V,
        bindingName = "Mark Selected Item as Favorite",
        validContexts = { contextType.inventory, }
    },
    favoriteItemSpell = {
        ctrlKey = input.CONTROLLER_BUTTON.Y,
        keyboardKey = input.KEY
            .V,
        bindingName = "Mark Selected Spell as Favorite",
        validContexts = { contextType.magic, }
    },
    upArrow = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadUp,
        keyboardKey = input.KEY
            .UpArrow,
        axis = input.CONTROLLER_AXIS.LeftY,
        axisRange = -1
    },
    downArrow = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadDown,
        keyboardKey = input.KEY
            .DownArrow,
        axis = input.CONTROLLER_AXIS.LeftY,
        axisRange = 1
    },
    leftArrow = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadLeft,
        keyboardKey = input.KEY
            .LeftArrow,
        axis = input.CONTROLLER_AXIS.LeftX,
        axisRange = -1
    },
    rightArrow = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadRight,
        keyboardKey = input.KEY
            .RightArrow,
        axis = input.CONTROLLER_AXIS.LeftX,
        axisRange = 1
    },
    selectButton = {
        ctrlKey = input.CONTROLLER_BUTTON.A,
        keyboardKey = input.KEY
            .Enter,
        bindingName = "Drop Item",
        validContexts = { contextType.inventory }
    },
    transferButton = {
        ctrlKey = input.CONTROLLER_BUTTON.A,
        keyboardKey = input.KEY
            .Enter,
        bindingName = "Transfer Item",
        validContexts = { contextType.barter, contextType.container, contextType.containerActor }
    },
    transferAllButton = {
        ctrlKey = input.CONTROLLER_BUTTON.Y,
        bindingName = "Transfer All Items",
        validContexts = {  contextType.container, contextType.containerActor }
    },
    closeMenu = {
        ctrlKey = input.CONTROLLER_BUTTON.B,
        keyboardKey = input.KEY
            .Escape
    },
    equipItem = {
        ctrlKey = input.CONTROLLER_BUTTON.X,
        keyboardKey = input.KEY
            .E,
        bindingName = "Equip/Use Item",
        validContexts = {  contextType.inventory, contextType.containerActor }
    },
    transferOneItem = {
        ctrlKey = input.CONTROLLER_BUTTON.X,
        keyboardKey = input.KEY
            .E,
        bindingName = "Transfer One Item",
        validContexts = {  contextType.barter }
    },
    equipItemMagic = {
        ctrlKey = input.CONTROLLER_BUTTON.X,
        keyboardKey = input.KEY
            .E,
        bindingName = "Equip/Use Magic",
        validContexts = {  contextType.magic }
    },
    openFavorites = {
        ctrlKey = input.CONTROLLER_BUTTON.DPadDown,
        keyboardKey = nil --input.KEY
        -- .Q
    },
    nextCat = {
        ctrlKey = input.CONTROLLER_BUTTON.RightShoulder,
        keyboardKey = input.KEY
            .Z,
    },
    prevCat = {
        ctrlKey = input.CONTROLLER_BUTTON.LeftShoulder,
        keyboardKey = input.KEY
            .LeftShift,
    },
}
for index, data in pairs(inputData) do
    if data.axis then
        local found = false

        for index, axis in ipairs(axisToCheck) do
            if axis == data.axis then
                found = true
            end
        end
        if not found then
            table.insert(axisToCheck, data.axis)
        end
    end
end
local currentCat = 1
local function onSave(data)
    --should really only do this if it was set to false before, by this script
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
end
local menumode = false
local function setPauseMode(val)
    menumode = val
end

local function getSelectedWindow()
    if playerWindow ~= nil and playerWindow.selected then
        return playerWindow
    elseif containerWindow ~= nil and containerWindow.selected then
        return containerWindow
    end
end
local function getOppositeWindow()
    if playerWindow ~= nil and playerWindow.selected and containerWindow ~= nil then
        return containerWindow
    elseif containerWindow ~= nil and containerWindow.selected then
        return playerWindow
    end
end
local function updateSelectedCategory(cat)

end
local facedObject = nil
local facedObjectUpdateTime = -1
local distanceToFacedObject = -1

local function itemIsEquipped(item, actor)
    --Checks if item record is equipped on the specified actor
    if (actor == nil) then actor = self end
    if (actor.type ~= types.NPC and actor.type ~= types.Creature and actor.type ~=
            types.Player) then
        ----print("invalid type")
        return false
    end
    for slot = 1, 17 do
        if (types.Actor.equipment(actor, slot)) then
            if (item.id == types.Actor.equipment(actor, slot).id) then
                return true
            end
        end
    end
    return false
end
local function updateFacedObject()
    local time = core.getSimulationTime()

    if facedObjectUpdateTime < time then
        facedObjectUpdateTime = time

        local screenPos = util.vector2(0.5, 0.5)
        local worldVector = camera.viewportToWorldVector(screenPos)
        local origin = camera.getPosition()
        local activationDistance = 100
        local cameraDistance = camera.getThirdPersonDistance()
        activationDistance = activationDistance + cameraDistance
        local targetPoint = origin + worldVector * activationDistance
        facedObject = nearby.castRenderingRay(origin, targetPoint)

        if facedObject and facedObject.hit then
            local hitVector = facedObject.hitPos - origin
            distanceToFacedObject = hitVector:length() - cameraDistance
        else
            distanceToFacedObject = -1
        end
    end
end

local function getFacedObject()
    updateFacedObject()
    if (facedObject.hit) then
        return facedObject
    else
        return nil
    end
end
local currKey = -1
local currCtrl = -1
local touchBinding
local function checkKey(keyData)
    if touchBinding then
        return touchBinding == keyData
    end
    local ret = false
    if keyData.keyboardKey and input.isKeyPressed(keyData.keyboardKey) then
        ret = true
    elseif keyData.ctrlKey and input.isControllerButtonPressed( keyData.ctrlKey )then
        ret = true
    elseif keyData.axis and input.getAxisValue(keyData.axis) > 0.1 and not keyData.axisRange then
       ret = true
    elseif keyData.axis and input.getAxisValue(keyData.axis) > 0.1 and keyData.axisRange == 1 then
       ret = true
    elseif keyData.axis and input.getAxisValue(keyData.axis) < -0.1 and keyData.axisRange == -1 then
       ret = true
    end
    if ret then
        keyWasPressed = true
    end
    return ret
end

local itemWindowLocs = {
    TopLeft = {wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil},
    TopRight = {wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0)},
    Right = {wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5)},
    Left = {wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5)},
    BottomLeft = {wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1)},
    BottomRight = {wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1)},
    BottomCenter = {wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1)},
    TopCenter = {wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0)},
    Disabled = {disabled = true}
}
local function getControllerButtonName(fvalue)
    for key, value in pairs(input.CONTROLLER_BUTTON) do
        if value == fvalue then return key end
    end
end
local function getControllerAxisName(fvalue)
    for key, value in pairs(input.CONTROLLER_AXIS) do
        if value == fvalue then return key end
    end
end
local function getKeybindList()
    local list = {}
    for key, value in pairs(inputData) do
        if value.bindingName then
            local line
            if controllerMode then
                local valid = true
                if value.validContexts then
                    valid = false
                    for index, value in ipairs(value.validContexts) do
                        if value == currentContext then
                            valid = true
                        end
                    end
                end
                if valid then

                    line = { value.bindingName, getControllerButtonName(value.ctrlKey) or getControllerAxisName(value.axis) }
                    table.insert(list, line)
                end
            end
        end
    end
    return list
end
local function openPlayerWindow(mode)
    local isMagic = false
    local contextToUse = contextType.inventory
    if mode == windowType.magic then
        isMagic = true
        contextToUse = contextType.magic
    end
    if playerWindow then
        playerWindow:destroy()
        playerWindow = nil
    end
    if bindingsWin then
        bindingsWin:destroy()
    end
    menumode = true
    currentContext = contextToUse
    playerWindow = I.Controller_Item_Window.createItemWindow(self, 0.25, 0.5,nil,nil,nil,isMagic)
    if not isMagic then
        local gridSize = settings:get("gridSizeInventory") or containerGridSizeX
        playerWindow:setGridSize(gridSize, gridSize)
    else
        playerWindow:setGridSize(settings:get("magicListLength"), settings:get("magicListLength"))
    end
    playerWindow.selected = true
    setPauseMode(true)
    ----print("Opening PWindow")
    --playerWindow:drawWindow()
    I.CI_Background.drawBottomBar(getKeybindList(),isMagic)
    --bindingsWin = I.ZackUtilsUI_ci.drawListMenu(getKeybindList(), itemWindowLocs.TopLeft, bindingsWin)
end
local function closePlayerWindow()
    if playerWindow ~= nil then
        if playerWindow.type then
            local check = exitBarter()
            if not check then
            else
                barterInfoWindow:destroy()

             end
        end

        local status = playerWindow:destroy()

        print(status,"complete")
        playerWindow = nil

    end
    if containerWindow then
        containerWindow:destroy()
        containerWindow = nil
    end
    if bindingsWin then
        bindingsWin:destroy()
        bindingsWin = nil
    end
    if handWindow then
        handWindow:destroy()
        heldItem = nil
        handWindow = nil
    end
    menumode = false
end
I.UI.registerWindow("Inventory", function() end, function() end)
--  function() self:sendEvent("closePlayerWindow") end)
I.UI.registerWindow("Trade", function() end, function() closePlayerWindow() end)
--I.UI.registerWindow("Magic", function() end, function() end)
--I.UI.registerWindow("Stats", function() end, function() end)
local validEquipItemTypes = {
    [types.Weapon] = true,
    [types.Clothing] = true,
    [types.Armor] = true,
    [types.Light] = true,
    [types.Lockpick] = true,
    [types.Probe] = true
}
local validUseItemTypes = {
    [types.Apparatus] = true,
    [types.Book] = true,
    [types.Miscellaneous] = true,
    [types.Repair] = true,
    [types.Repair] = true
}
local validConsItemTypes = {
    [types.Ingredient] = true,
    [types.Potion] = true,
}
local function canEquipItem(item)
    local slot = I.ZackUtilsUI_ci.findSlot(item)
    if not slot then
        return false
    end

    return validEquipItemTypes[item.type] == true
end
local function canUseItem(item)
    return validUseItemTypes[item.type] == true
end
local function canConsumeItem(item)
    return validConsItemTypes[item.type] == true
end
local function setSelectedWindow(iw)
    if playerWindow == iw then
        iw.selected = true
        if containerWindow then
            containerWindow.selected = false
            containerWindow:reDraw()
        end
    elseif containerWindow == iw and containerWindow ~= nil then
        containerWindow.selected = true
        if playerWindow then
            playerWindow.selected = false
            playerWindow:reDraw()
        end
    end
end
local function formatNumber(num)
    local threshold = 1000
    local millionThreshold = 1000000

    if num >= millionThreshold then
        local formattedNum = math.floor(num / millionThreshold)
        return string.format("%dm", formattedNum)
    elseif num >= threshold then
        local formattedNum = math.floor(num / threshold)
        return string.format("%dk", formattedNum)
    else
        return tostring(num)
    end
end
local function drawHandIcon(item, px, py, iw)
    if handWindow then
        return
    end
    if not item then return end
    if item.item then
        item = item.item
    end
    heldItem            = item
    heldContainer       = iw.parentObject
    local iconsize      = 40
    local favoriteItems = {}
    local iconsizegrow  = iconsize + 10
    local path          = item.type.records[item.recordId].icon
    local content       = {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(iconsizegrow, iconsizegrow),
            position = v2(0, 0),
            vertical = true,
            arrange = ui.ALIGNMENT.Start,
        },
        external = {
            grow = iconsize + 15
        }
    }
    local text          = ""
    local itemIcon
    if (item) then
        local record = path
        if (item.count > 1) then
            text = formatNumber(item.count)
        end

        if favoriteItems[item.recordId] then
            text = "*" .. text
        end
        itemIcon = I.Controller_Item_Window.getTexture(record)
    end
    handWindow = ui.create {
        layer = 'CursorLayer',
        type = ui.TYPE.Container,
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(-0.5, -0.5),
            position = v2(px, py),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            size = util.vector2(iconsizegrow, iconsizegrow),
            vertical = true,
            name = "HandWindow",
        }, content = ui.content {
        -- I.ZackUtilsUI_ci.imageContent(magicIcon),
        I.ZackUtilsUI_ci.imageContent(itemIcon),
        I.ZackUtilsUI_ci.textContent(tostring(text))
    }
    }
end

local newMapEnabled = false
local function updateActiveWindow(nextWindowType)
    if nextWindowType then
        if nextWindowType == windowType.inventory or
                nextWindowType == windowType.magic or
                nextWindowType == windowType.map or
                nextWindowType == windowType.stats then
            -- cache the last window opened if it is an player-menu window
            lastWindowOpened = nextWindowType
        end

        -- destroy other windows
        if I.Map then I.Map.destroyMap() end

        if nextWindowType == windowType.map then
            closePlayerWindow()
            menumode = true
            currentContext = contextType.map

            if newMapEnabled then
                I.CI_Expirement.openEmptyUIWindow()
                I.Map.drawMap()
                I.CI_Expirement.toggleCursorVisible(false)
            else
                I.UI.setMode('Interface', { windows = { I.UI.WINDOW.Map } })
                I.CI_Expirement.toggleCursorVisible(true)
            end
        elseif nextWindowType == windowType.stats then
            closePlayerWindow()
            menumode = true
            currentContext = contextType.stats
            if settings:get("useNewStatsWindow") then
                I.CI_Expirement.openEmptyUIWindow()
                I.CI_StatsMenu.openNewStatsWin()
                I.CI_Expirement.toggleCursorVisible(false)
            else
                I.UI.setMode('Interface', { windows = { I.UI.WINDOW.Stats } })
                I.CI_Expirement.toggleCursorVisible(true)
            end
        else
            currentContext = (nextWindowType == windowType.inventory and contextType.inventory or contextType.magic)
            I.CI_Expirement.openEmptyUIWindow()
            I.CI_Expirement.toggleCursorVisible(false)

            if playerWindow ~= nil then
                playerWindow:setType(nextWindowType)
                queRedraw = true
            end

            -- playerWindow:setType above may cause the window to be destroyed
            if playerWindow == nil then
                openPlayerWindow(nextWindowType)
            end
        end

        -- draw the bottom bar for every window
        I.CI_Background.drawBottomBar(getKeybindList())
        currentWindowType = nextWindowType
    end
end
local function switchMapMode()
    if not I.Map then return end
    print(4)
    print("switch")
    if  newMapEnabled == false then
        newMapEnabled = true
        I.CI_Expirement.openEmptyUIWindow()
        I.Map.drawMap()
        I.CI_Expirement.toggleCursorVisible(false)
    else
        newMapEnabled = false
        I.Map.destroyMap()
        I.UI.setMode('Interface', { windows = { I.UI.WINDOW.Map } })
        I.CI_Expirement.toggleCursorVisible(true)
    end
end
local function processInput(key, ctrl)
    local keys = input.KEY
    --currKey = key
  keyWasPressed = false
    if blockInput then
        return
    end
  --  currCtrl = ctrl
    if checkKey(inputData.openPlayerMenu) then
        if (playerWindow == nil and input.getControlSwitch(input.CONTROL_SWITCH.Controls) == true and core.isWorldPaused() == false) then
            --()
            --    ----print("Player Window on")
        elseif playerWindow then
            if playerWindow.type then
                local check = exitBarter()
                if not check then return end
                barterInfoWindow:destroy()
            end
            playerWindow:destroy()
            playerWindow = nil
            if (containerWindow) then
                containerWindow:destroy()
                containerWindow = nil
            end
            if bindingsWin then
                bindingsWin:destroy()
            end
            setPauseMode(false)
            --  ----print("Player Window off")
        end
        return true
    end
    if checkKey(inputData.openFavorites) and not menumode and core.isWorldPaused() == false and input.getControlSwitch(input.CONTROL_SWITCH.Controls) == true and core.getSimulationTimeScale() > 0 then
      -- I.UI.setMode('Interface', { windows = {} })
       -- playerWindow = I.Controller_Item_Window.createItemWindow(self, 0.5, 0.5, true)
        --playerWindow.selected = true
       -- playerWindow.listMode = true
       -- playerWindow:setGridSize(1, 6)
       -- setPauseMode(true)
       -- bindingsWin = I.ZackUtilsUI_ci.drawListMenu({ "HellO" }, itemWindowLocs.TopLeft, bindingsWin)
    end
   -- local id = ctrl
    if not containerWindow then
        local nextWindowType

        if checkKey(inputData.nextMenu) then
            if currentWindowType == windowType.inventory and playerWindow ~= nil then
                nextWindowType = windowType.magic     --2
            elseif currentWindowType == windowType.magic and playerWindow ~= nil then
                nextWindowType = windowType.map       --3
            elseif currentWindowType == windowType.map then
                nextWindowType = windowType.stats     --4
            elseif currentWindowType == windowType.stats then
                nextWindowType = windowType.inventory --1
            end
            updateActiveWindow(nextWindowType)
        elseif checkKey(inputData.prevMenu) then
            if currentWindowType == windowType.inventory and playerWindow ~= nil then
                nextWindowType = windowType.stats     --4
            elseif currentWindowType == windowType.magic and playerWindow ~= nil then
                nextWindowType = windowType.inventory --1
            elseif currentWindowType == windowType.map then
                nextWindowType = windowType.magic     --2
            elseif currentWindowType == windowType.stats then
                nextWindowType = windowType.map       --3
            end
            updateActiveWindow(nextWindowType)
        end
    else
        if checkKey(inputData.prevMenu) then
            playerWindow.selected = true
            containerWindow.selected = false
            queRedraw = true
            return true
        elseif checkKey(inputData.nextMenu) then
            playerWindow.selected = false
            containerWindow.selected = true
            queRedraw = true
        end
    end
    if (not menumode) then
        return
    end
    local selectedWindow = getSelectedWindow()
    if not selectedWindow then
    end
    local oppositeWindow = getOppositeWindow()

    if not I.Map and currentContext == contextType.map then return end
    if checkKey(inputData.switchInventory) and currentContext == contextType.map then
        switchMapMode()
    elseif checkKey(inputData.centerOnPlayer) and currentContext == contextType.map then
        I.Map.scrollToPlayer()
    elseif checkKey(inputData.selectButton) and currentContext == contextType.map  and I.Map.getSelectedElement()and I.Map.getMapActive()  then
        if settings:get("devModeEnable") then

        core.sendGlobalEvent("COCEvent",{objectToTeleport = self,cellname =I.Map.getSelectedElement()  })
        I.UI.setMode()
        end
    elseif checkKey(inputData.selectButton) and currentContext == contextType.map  and not I.Map.getSelectedElement() and I.Map.getMapActive()  then
        if settings:get("devModeEnable") then
            local pos = I.Map.getSelectedPosition()
        core.sendGlobalEvent("ZackUtilsTeleportToCell",{item = self,cellname ="",position = pos })
        I.UI.setMode()
        end
    end
    if (selectedWindow == nil) then
        return
    end
    local selectedx = selectedWindow.selectedPosX
    local selectedy = selectedWindow.selectedPosY
    local listMode = selectedWindow.listMode
    if checkKey(inputData.leftArrow) and not listMode then
        print(1)
        if (selectedWindow.selectedPosX > 1 and selectedWindow:getItemAt(selectedWindow.selectedPosX - 1, selectedy) ~= nil) then
            selectedWindow.selectedPosX = selectedx - 1
        else
            if (selectedWindow.scrollOffset > 9) then
                selectedWindow.scrollOffset = (selectedWindow.scrollOffset - 10)
            end
        end
    elseif not containerWindow and playerWindow.windowType == windowType.inventory and (checkKey(inputData.equipItem) or (selectedWindow.listMode and checkKey(inputData.selectButton))) then
        local invItem = selectedWindow:getItemAt(selectedWindow.selectedPosX, selectedWindow.selectedPosY)
        if (playerWindow.windowType == windowType.inventory) then
            if not invItem then
            else
                if currentContext == contextType.barter then
                    selectedWindow:transferSelectedToOtherInventory(oppositeWindow, nil, nil, 1)
                elseif (invItem and not invItem.equipped and canEquipItem(invItem.item)) then
                    --I.ZackUtilsUI_ci.playPickupSound(invItem.item)
                   -- I.ZackUtilsUI_ci.equipItem(invItem.item, selectedWindow.parentObject,selectedWindow)
                    invItem.equipped = true
                    core.sendGlobalEvent('UseItem', { object = invItem.item, actor = self, force = false })

                    queRedraw = true
                elseif (selectedWindow.parentObject == self and invItem.type == types.Book) then
                   -- closePlayerWindow()
                    core.sendGlobalEvent('UseItem', { object = invItem.item, actor = self, force = false })
                elseif (selectedWindow.parentObject == self and canUseItem(invItem.item)) then
                   -- if I.CCC_Player and I.CCC_Player.itemIsCCCont(invItem.item) then
                  --      I.CCC_Player.openCCCont(invItem.item)
                  --  else
                        I.ZackUtilsUI_ci.playPickupSound(invItem.item)
                        core.sendGlobalEvent('UseItem', { object = invItem.item, actor = self, force = false })

                 --   end
                 elseif (selectedWindow.parentObject == self and canConsumeItem(invItem.item)) then
                    I.ZackUtilsUI_ci.playPickupSound(invItem.item)
                    core.sendGlobalEvent('consumeOneItem', { object = invItem.item, actor = self.object, force = true })
                    invItem.count = invItem.count - 1
                elseif (invItem.equipped) then
                    I.ZackUtilsUI_ci.unequipItem(invItem.item, selectedWindow.parentObject)
                    invItem.equipped = false
                end
            end
        end
        queRedraw = true
    elseif checkKey(inputData.switchInventory) and oppositeWindow then

        if (playerWindow ~= nil and containerWindow ~= nil) then
            playerWindow.selected = not playerWindow.selected
            containerWindow.selected = not playerWindow.selected
            queRedraw = true
        end
    elseif checkKey(inputData.switchInventory) and currentContext == contextType.map then
     switchMapMode()
    elseif checkKey(inputData.closeMenu) then
--I.Map.getSelectedElement() if checkKey(inputData.selectButton)
    elseif checkKey(inputData.selectButton) then
        if (selectedWindow.windowType == windowType.inventory and not selectedWindow.listMode) then
            if (selectedWindow ~= nil and oppositeWindow ~= nil) then
                selectedWindow:transferSelectedToOtherInventory(oppositeWindow)
            elseif playerWindow ~= nil and containerWindow == nil then
                local hit = getFacedObject()
                local dropPos = self.position
                if (hit ~= nil and hit.hitPos ~= nil) then
                    dropPos = hit.hitPos
                end
                if not dropPos then
                    dropPos = self.position
                end
                print('drop me')
                selectedWindow:dropSelected(dropPos)
            end
        elseif selectedWindow.windowType == windowType.magic then
            local selectedSpell = selectedWindow:getItemAt(selectedWindow.selectedPosX, selectedWindow.selectedPosY)
            if (selectedSpell ~= nil and selectedSpell.spell.recordId == nil) then
                if (types.Actor.getSelectedSpell(self) == selectedSpell.spell) then
                    types.Actor.clearSelectedCastable(self)
                else
                    types.Actor.clearSelectedCastable(self)
                    types.Actor.setSelectedSpell(self, selectedSpell.spell)
                    ----print("set speel")
                end
            elseif (selectedSpell ~= nil and selectedSpell.spell.recordId ~= nil) then
                if (types.Actor.getSelectedEnchantedItem(self) == selectedSpell.spell) then
                    types.Actor.clearSelectedCastable(self)
                else
                    types.Actor.clearSelectedCastable(self)
                    types.Actor.setSelectedEnchantedItem(self, selectedSpell.spell)
                end
            end
            queRedraw = true

        else
            self:sendEvent("CustomWindowButtonPressed")
        end
    elseif checkKey(inputData.rightArrow) and not listMode then
        if (selectedx < selectedWindow.rowCountX and selectedWindow:getItemAt(selectedx + 1, selectedy) ~= nil) then
            selectedWindow.selectedPosX = selectedx + 1
        elseif selectedWindow.selectedPosX == selectedWindow.rowCountX then
            selectedWindow.scrollOffset = (selectedWindow.scrollOffset + selectedWindow.rowCountY)
        end
    elseif checkKey(inputData.favoriteItem) and not (containerWindow) then
        --selectedWindow.listMode = not selectedWindow.listMode
                print("favorite me")
        local invItem = selectedWindow:getItemAt(selectedWindow.selectedPosX, selectedWindow.selectedPosY)
        if invItem and currentWindowType == windowType.inventory then
            if I.QuickSelect_Hotbar then
                I.UI.setMode()
                I.QuickSelect_Hotbar.selectSlot(invItem.item.recordId)
                return
            end
            I.Controller_Favorites.toggleFavoriteItem(invItem.item.recordId)
        elseif invItem and currentWindowType == windowType.magic then
            local id
            if invItem.spell and invItem.spell.recordId then
                id = invItem.spell.recordId
                print("ench id" ..id)
                if I.QuickSelect_Hotbar then
                    I.UI.setMode()
                  --  print("spell enchant id " ..invItem.enchant)
                    I.QuickSelect_Hotbar.selectSlot(id,nil,invItem.spell.type.record(invItem.spell).enchant)
                    return
                end
            elseif invItem.spell then
                id = invItem.spell.id
                print(id)
                if I.QuickSelect_Hotbar then
                    I.UI.setMode()
                    print("spell id " ..invItem.spell.id)
                    I.QuickSelect_Hotbar.selectSlot(nil,invItem.spell.id)
                    return
                end
            end
            I.Controller_Favorites.toggleFavoriteMagic(id)
        end
        queRedraw = true


    elseif checkKey(inputData.transferAllButton) and (containerWindow and containerWindow.windowType == windowType.inventory ) then

        print(2)
         if (containerWindow and containerWindow.windowType == windowType.inventory ) then
            print("hi")
            local container = containerWindow.parentObject
            for index, value in ipairs(types.Actor.inventory(container):getAll()) do
                I.ZackUtilsUI_ci.playPickupSound(value)
            end
            core.sendGlobalEvent("transferAllInv", { source = container, target = self })
            I.UI.setMode()
         --   containerWindow:transferAllToOtherInventory(playerWindow)
        end
    elseif checkKey(inputData.favoriteItem) and selectedWindow.type then
        closePlayerWindow()
        return
    elseif checkKey(inputData.upArrow) then
        if (selectedWindow.listMode) then
            if (selectedWindow.selectedPosX > 1 and selectedWindow:getItemAt(selectedWindow.selectedPosX - 1, selectedy) ~= nil) then
                selectedWindow.selectedPosX = selectedx - 1
            else
                if (selectedWindow.scrollOffset > 0) then
                    selectedWindow.scrollOffset = (selectedWindow.scrollOffset - 1)
                end
            end
        else
            if (selectedy > 1 and selectedWindow:getItemAt(selectedx, selectedy - 1) ~= nil) then
                selectedWindow.selectedPosY = selectedy - 1
            end
        end
    elseif checkKey(inputData.downArrow) then
        if (selectedWindow.listMode) then
            if (selectedx < selectedWindow.rowCountY and selectedWindow:getItemAt(selectedx + 1, selectedy) ~= nil) then
                selectedWindow.selectedPosX = selectedx + 1
            --    print("down")
            elseif selectedWindow.selectedPosX > selectedWindow.rowCountY - 1 and selectedWindow:getItemAt(selectedx + 1, selectedy) then
                selectedWindow.scrollOffset = (selectedWindow.scrollOffset + 1)
             --   print("down 2")
           -- else
             --   print("Canot down")
            end
        else
            if (selectedy < selectedWindow.rowCountY and selectedWindow:getItemAt(selectedx, selectedy + 1)) then
                selectedWindow.selectedPosY = selectedy + 1
            end
        end
    elseif checkKey(inputData.prevCat) or ( checkKey(inputData.leftArrow) and  listMode ) then
        if selectedWindow.isCustomWindow then
            selectedWindow:selectPrevCat()

        else
            if (currentCat > 1) then
                currentCat = currentCat - 1
            else
                currentCat =  #selectedWindow.catTypes
            end
            selectedWindow:fixCursorPos()
            if (oppositeWindow) then
                oppositeWindow:fixCursorPos()
            end
        end
    elseif checkKey(inputData.nextCat) or ( checkKey(inputData.rightArrow) and  listMode ) then
        if selectedWindow.isCustomWindow then
            selectedWindow:selectNextCat()
        else
            if (currentCat < #selectedWindow.catTypes) then
                currentCat = currentCat + 1
            else
                currentCat = 1
            end
            selectedWindow:fixCursorPos()
            if (oppositeWindow) then
                oppositeWindow:fixCursorPos()
            end
        end
    end
    selectedWindow:reDraw()
    if not  selectedWindow:getItemAt(selectedWindow.selectedPosX , selectedWindow.selectedPosY) then
        selectedWindow.selectedPosX = 1
        selectedWindow.selectedPosY = 1
        selectedWindow.scrollOffset = 0
        selectedWindow:reDraw()
    end
    if (oppositeWindow) then
        oppositeWindow:reDraw()
    end
end
local lastPress = 0
local function onControllerButtonPress(ctrl)
    if (core.getRealTime() < lastPress + 0.002) then
        --  ----print("skip", os.time(), lastPress)
        -- return
    end
    if inputDelay > 0 then
        print("delayed)", inputDelay)
        return
    end
    nextPress = repeatRateStart
    ----print(ctrl)
    controllerMode = true
    processInput(nil, ctrl)
    lastPress = core.getRealTime()
end
local function onControllerButtonRelease(ctrl)

end
local function onKeyPress(key)
    controllerMode = false
    nextPress = repeatRateStart
    if inputDelay > 0 then
        print("delayed)", inputDelay)
        return
    end
    ----print(key.code)
    processInput(key.code)
end

local function checkNotWerewolf()
    if Player.isWerewolf(self) then
        ui.showMessage(core.getGMST('sWerewolfRefusal'))
        return false
    else
        return true
    end
end
local function updateBarterWindow(actor)
    if barterInfoWindow then
        barterInfoWindow:destroy()
    end
    local goldAmount = getBarterAmount()
    ----print("BWUpdate")
    barterInfoWindow = I.Controller_Item_Window.renderBarterWindow(goldAmount,actor)
end
local function CI_openBarterInterface(object)
    currentContext = contextType.barter
    if playerWindow then
        playerWindow:destroy()
    end
    if containerWindow then
        containerWindow:destroy()
    end
    local gridSize = settings:get("gridSizeContainer") or containerGridSizeX
    playerWindow = I.Controller_Item_Window.createItemWindow(self, 0.25, 0.5, false, "barterPlayer", object)
    playerWindow:setGridSize(gridSize,gridSize)
    playerWindow.selected = true
;
    setPauseMode(true)
    ----print("Player Window on")
    blockInput = false
    if I.ControllerInterface_QL then
        I.ControllerInterface_QL.destroyWindow()
    end
    containerWindow = I.Controller_Item_Window.createItemWindow(object, 0.75, 0.5, false, "barterNPC")
    containerWindow.selected = false
    containerWindow.selected = false
    containerWindow:setGridSize(gridSize,gridSize)
    --    bindingsWin = I.ZackUtilsUI_ci.drawListMenu(getKeybindList(), itemWindowLocs.TopLeft, bindingsWin)
    I.CI_Background.drawBottomBar(getKeybindList())
    barterInfoWindow = I.Controller_Item_Window.renderBarterWindow(0,object)
end
local function CI_openContainerInterface(object, skipWin)
    I.Deckwind.setInputDelay(0.1)
    I.Deckwind.setCurrentCat(1)
    if object.type == types.Container then
        currentContext = contextType.container
    elseif object then
        currentContext = contextType.containerActor
    end
    if playerWindow then
        playerWindow:destroy()
    end
    if containerWindow then
        containerWindow:destroy()
    end
    local gridSize = settings:get("gridSizeContainer") or containerGridSizeX
    playerWindow = I.Controller_Item_Window.createItemWindow(self, 0.25, 0.5, nil, nil, nil,nil,false)
    playerWindow:setGridSize(gridSize,gridSize)
    playerWindow.selected = false
    setPauseMode(true)
    ----print("Player Window on")
    blockInput = false
    if I.ControllerInterface_QL then
        I.ControllerInterface_QL.destroyWindow()
    end
    if not skipWin then

    end
    I.CI_Expirement.openEmptyUIWindow()
    containerWindow = I.Controller_Item_Window.createItemWindow(object, 0.75, 0.5)
    containerWindow.selected = true
    containerWindow:setGridSize(gridSize,gridSize)

    I.CI_Background.drawBottomBar(getKeybindList())
    -- bindingsWin = I.ZackUtilsUI_ci.drawListMenu(getKeybindList(), itemWindowLocs.TopLeft, bindingsWin)
    --I.UI.setMode('Interface', { windows = {} })
end

local function CI_openInventoryInterface()

end
local function CI_upDateinvWins()
    if (containerWindow ~= nil) then
        containerWindow:rebuildItemList()
        containerWindow:reDraw()
    end
    if (playerWindow ~= nil) then
        playerWindow:rebuildItemList()
        playerWindow:reDraw()
    end
end
local function registerDefaultBindings()

end
local frameWait = 0
local lastRealTime = 0
local function onFrame(dt)
    local realDelta = core.getRealTime() - lastRealTime

    if inputDelay > 0 then
        inputDelay = inputDelay - realDelta
    end
    if nextPress > 0 then
        nextPress = nextPress - realDelta
        if nextPress <= 0 then
            nextPress = 0
            if keyWasPressed then
                nextPress = repeatRate
                if inputDelay > 0 then
                    print("delayed)", inputDelay)

                else

                    processInput()
                end
               -- print("repeat")
            end
        end
    end
    lastRealTime = core.getRealTime()
    if handWindow then
        local mmy = input.getMouseMoveY()
        local mmx = input.getMouseMoveX()
        local pos = handWindow.layout.props.position
        handWindow.layout.props.position = util.vector2(pos.x + mmx, pos.y + mmy)
        handWindow:update()
    end
    if menumode and I.UI.getMode() then
        for index, value in ipairs(axisToCheck) do
            local pressed = axisPressed[value]
            if not pressed then
                local laxisValue = input.getAxisValue(value)
                if laxisValue > 0.1 or laxisValue < -0.1 then
                    axisPressed[value] = true
                    axisValue[value] = laxisValue
                    if inputDelay <= 0 then

                    processInput()
                    end
                end
            else
                local laxisValue = input.getAxisValue(value)
                if laxisValue < 0.1 and laxisValue > -0.1 then
                    axisPressed[value] = nil
                    axisValue[value] = nil
                end
            end
        end
    end
    local stickPos = input.getAxisValue(input.CONTROLLER_AXIS.LeftX)
    if (stickPos > 0.1 or stickPos < -0.1) and core.isWorldPaused() and not I.CI_MenuSelect.menuSelectActive() and not I.CI_Expirement.isGamepadCursorActive()  then
        I.CI_Expirement.toggleCursorVisible(true,false)
    end
    if queRedraw and frameWait > 3 then

        if playerWindow then
            playerWindow:rebuildItemList()
            playerWindow:reDraw()
        end
        if containerWindow then
            containerWindow:rebuildItemList()
            containerWindow:reDraw()
        end
        queRedraw = false
        frameWait = 0
    elseif queRedraw then
        frameWait = frameWait + 1
    end
end

local function isJournalAllowed()
    -- During chargen journal is not allowed until magic window is allowed
    return I.UI.getWindowsForMode(I.UI.MODE.Interface)[I.UI.WINDOW.Magic]
end

local function onInputAction(action)
    if action == input.ACTION.Inventory then
        if I.UI.getMode() == nil then
            -- If the Skyrim style submenu selection is enabled, we need to open the menu select window
            -- instead of the previously closed window
            if settings:get("useSkyrimStyleSubmenuSelection") then
                I.CI_MenuSelect.drawMenuSelect()
            else
                -- open the last window closed
                I.Deckwind.updateActiveWindow(lastWindowOpened)
            end
        elseif I.UI.getMode() == I.UI.MODE.Interface or I.UI.getMode() == I.UI.MODE.Container then
            I.UI.removeMode(I.UI.getMode())
        end
    elseif action == input.ACTION.Journal then
        if I.UI.getMode() == I.UI.MODE.Journal then
            I.UI.removeMode(I.UI.MODE.Journal)
        elseif isJournalAllowed() then
            I.UI.addMode(I.UI.MODE.Journal)
        end
    elseif action == input.ACTION.QuickKeysMenu then
        if I.UI.getMode() == I.UI.MODE.QuickKeysMenu then
            I.UI.removeMode(I.UI.MODE.QuickKeysMenu)
        elseif checkNotWerewolf() and Player.isCharGenFinished(self) then
            I.UI.addMode(I.UI.MODE.QuickKeysMenu)
        end
    end
end
local function enterBarter(targetActor)
    CI_openBarterInterface(targetActor)
end

local function touchAction(name)
    local binding = inputData[name]
    if not binding then return end
    touchBinding = binding
    local ok, err = pcall(processInput)
    touchBinding = nil
    if not ok then error(err) end
end
I.UI.registerWindow("Container", function() end, function() end)

local function getBarterItems()
    if containerWindow and currentContext == contextType.barter then
        local items = containerWindow.itemDataList
        return items
    end
end
local function buyBarterItem(data)
    if containerWindow and currentContext == contextType.barter then
        data.pending = true
    containerWindow:transferSelectedToOtherInventory(playerWindow,nil,data.item)
    end
end
return {
    interfaceName = "Deckwind",
    interface = {
        version = 1,
        getBarterItems = getBarterItems,
        buyBarterItem = buyBarterItem,
        setPauseMode = setPauseMode,
        switchMapMode = switchMapMode,
        contextType = contextType,
        getCurrentCat = function() return currentCat end,
        setCurrentCat = function(c) currentCat = c end,
        getInvWindow = function() return playerWindow end,
        setBlockInput = setBlockInput,
        getEncumburance = getEncumburance,
        updateActiveWindow = updateActiveWindow,
        setSelectedWindow = setSelectedWindow,
        closePlayerWindow = closePlayerWindow,
        setCustomWindow = function (win)
            menumode = true
            playerWindow = win
        end,
        openPlayerWindow = openPlayerWindow,
        touchAction = touchAction,
        drawHandIcon = drawHandIcon,
        updateBarterWindow = updateBarterWindow,
        getHeldItem = function()
            return heldItem, heldContainer
        end,
        setInputDelay = function (val)
            inputDelay = val
        end,
        clearHeldItem = function()
            heldItem = nil
            handWindow:destroy()
            handWindow = nil
        end

    },
    eventHandlers = {
        CI_openContainerInterface = CI_openContainerInterface,
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        ClickedContainer = ClickedContainer,
        CI_upDateinvWins = CI_upDateinvWins,
        ClickedActor = ClickedActor,
        setPauseMode = setPauseMode,
        openPlayerWindow = openPlayerWindow,
        closePlayerWindow = closePlayerWindow,
        UiModeChanged = function(data)
            if data.newMode == nil and menumode and playerWindow then
                closePlayerWindow()
                menumode = false
            elseif data.newMode == "Interface" and data.oldMode ~= "Interface"
                and not menumode and not I.CI_MenuSelect.menuSelectActive() then
                if settings:get("useSkyrimStyleSubmenuSelection") then
                    I.CI_MenuSelect.drawMenuSelect()
                else
                    updateActiveWindow(lastWindowOpened)
                end
            elseif data.newMode == "Companion" and data.arg ~= nil then
                -- I.UI.setMode('Interface', { windows = {} })
                CI_openContainerInterface(data.arg, true)
                I.CI_Expirement.toggleCursorVisible(false)
            elseif data.newMode == "Barter" and data.arg ~= nil then
                enterBarter(data.arg)
                I.CI_Expirement.toggleCursorVisible(false)
                --elseif data.newMode == "Interface" then
                --    I.UI.setMode('Interface', { windows = {} })
            elseif data.newMode == "Container" then
                CI_openContainerInterface(data.arg)
                I.CI_Expirement.toggleCursorVisible(false)
            elseif data.oldMode == "Interface" and playerWindow and not menumode then
                closePlayerWindow()
                I.CI_Expirement.toggleCursorVisible(false)
            elseif (data.newMode == "Book" or data.newMode == "Scroll" ) and data.newMode then
                closePlayerWindow()
            elseif (data.oldMode == "Book" or data.oldMode == "Scroll" ) and data.newMode then
               -- updateActiveWindow(currentWindowType)
                --I.CI_Expirement.toggleCursorVisible(false)
             --   closePlayerWindow()
             I.UI.setMode()
            end
        end
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onActive = onActive,
        onControllerButtonPress = onControllerButtonPress,
        onInputAction = onInputAction,
        onSave = onSave,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onControllerButtonRelease = onControllerButtonRelease,
    }
}
