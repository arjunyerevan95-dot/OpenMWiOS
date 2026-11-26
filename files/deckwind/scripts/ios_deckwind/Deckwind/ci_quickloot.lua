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
local quickLootMenu = nil

local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
if true then-- playerSettings:get("enableMod") ~= true or playerSettings:get("enableQuickloot") ~= true  then
    return
end
local function getInventory(object)
    --Gets the inventory of an object, actor or container.
    if (object.type == types.NPC or object.type == types.Creature or object.type ==
            types.Player and types.Actor.stats.dynamic.health(object).current == 0) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    return nil
end
local function scrollUp()
    if not quickLootMenu then return end
    local selectedx = quickLootMenu.selectedPosX
    local selectedy = quickLootMenu.selectedPosY
    if (quickLootMenu.selectedPosX > 1 and quickLootMenu:getItemAt(quickLootMenu.selectedPosX - 1, selectedy) ~= nil) then
        quickLootMenu.selectedPosX = selectedx - 1
    else
        if (quickLootMenu.scrollOffset > 0) then
            quickLootMenu.scrollOffset = (quickLootMenu.scrollOffset - 1)
        end
    end
    quickLootMenu:reDraw()
end
local function scrollDown()
    if not quickLootMenu then return end
    local selectedx = quickLootMenu.selectedPosX
    local selectedy = quickLootMenu.selectedPosY
    if (selectedx < quickLootMenu.rowCountY and quickLootMenu:getItemAt(selectedx + 1, selectedy) ~= nil) then
        quickLootMenu.selectedPosX = selectedx + 1
    elseif quickLootMenu.selectedPosX > quickLootMenu.rowCountY - 1 then
        quickLootMenu.scrollOffset = (quickLootMenu.scrollOffset + 1)
    end
    quickLootMenu:reDraw()
end
local function takeItem()
    local sourceObj = quickLootMenu.parentObject
    local targetObj = self
    local invItem = quickLootMenu:getItemAt(quickLootMenu.selectedPosX, quickLootMenu.selectedPosY)
    local count = invItem.count
    for index, value in ipairs(quickLootMenu.itemDataList) do
        if value == invItem then
            table.remove(quickLootMenu.itemDataList, index)
            break
        end
    end
    if #getInventory(sourceObj):getAll() == 1 then

    quickLootMenu:destroy()
    else

    quickLootMenu:reDraw()
    end
    core.sendGlobalEvent("CI_moveInto",
        { sourceObj = sourceObj, targetObj = targetObj, invItem = invItem.item, count = count, player = self })
end


local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local function getCameraDirData()
    local pos = Camera.getPosition()
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local function getPosInCrosshairs(mdist)
    local pos, v = getCameraDirData()

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    return pos + v * dist
end
local useRenderingRay = false
local function getObjInCrosshairs(ignoreOb, mdist, force)
    --ignoreOb is the object we are ignoring
    --mdist is the maximum distance we will search for
    if ignoreOb and type(ignoreOb) ~= "table" then
        ignoreOb = { ignoreOb }
    end
    local pos, v = getCameraDirData() --this function gets the position of the camera, and the angle of the camera

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    if (ignoreOb and not force) then --current functionality, have to do normal cast ray. This isn't great for placing items, since it will hit the hitbox of a bookshelf, not the shelf.

        return nearby.castRenderingRay(pos, pos + v * dist)
    else
        if (ignoreOb) then
            if useRenderingRay then

            else
                return nearby.castRenderingRay(pos, pos + v * dist)
                -- local ret = nearby.castRay(getPosInCrosshairs(20), pos + v * dist,{ignore = ignoreOb})

            end
        end
        return nearby.castRenderingRay(pos, pos + v * dist)
    end
end
local lastObject = nil
local function onInputAction(id)
    if not quickLootMenu then
        return
    end
    if id == input.ACTION.ZoomIn then
        scrollUp()
    elseif id == input.ACTION.ZoomOut then
        scrollDown()
    elseif id == input.ACTION.Use then
        takeItem()
    end
end
local function canUse(object)
    if not object then return false end
    if object.type.isLocked ~= nil and object.type.isLocked(object) == false and object.type.getTrapSpell(object) == nil and getInventory(object) then
        if not getInventory(object):isResolved() then
            core.sendGlobalEvent("resolveCont", object)
            return
        end
        if #getInventory(object):getAll() == 0 then
            return false
        end
        return true
    elseif (object.type == types.NPC or object.type == types.Actor) and types.Actor.stats.dynamic.health(object).current == 0 then
        if not getInventory(object):isResolved() then
            core.sendGlobalEvent("resolveCont", object)
            return
        end
        if #getInventory(object):getAll() == 0 then
            return false
        end
        return true
    else
        return false
    end
end
local lastPress = 0
local function onControllerButtonPress(id)
    if (core.getRealTime() < lastPress + 0.002) then
        --  --print("skip", os.time(), lastPress)
        return
    end
    lastPress = core.getRealTime()
if id == input.CONTROLLER_BUTTON.DPadUp then
    scrollUp()
elseif id == input.CONTROLLER_BUTTON.DPadDown then
    scrollDown()
end

end
local function destroyWindow()
    if quickLootMenu then
        quickLootMenu:destroy()
        I.Camera.enableZoom()
        I.Camera.enableModeControl()
        I.Controls.overrideCombatControls(false)
        I.Deckwind.setBlockInput(false)
        quickLootMenu = nil
    end
end
local function onUpdate(dt)
    if dt == 0 then
        return
    end
    local castRayData = getObjInCrosshairs(self, 400, false)
    if castRayData.hitObject then
        local hitOb = castRayData.hitObject
        if hitOb == lastObject then
        else
            if lastObject and quickLootMenu then
                --  --print("Lost", lastObject.recordId)
                destroyWindow()
            end
            if canUse(hitOb) then
                if quickLootMenu then
                    quickLootMenu:destroy()
                end
                I.Deckwind.setCurrentCat(1)
                quickLootMenu = I.Controller_Item_Window.createItemWindow(hitOb, 0.5, 0.5, false)
                quickLootMenu.selected = true
                quickLootMenu.listMode = true
                quickLootMenu.blockHeader = true
                quickLootMenu:setGridSize(1, 6)
                I.Camera.disableZoom()
                I.Camera.disableModeControl()
                I.Controls.overrideCombatControls(true)
                I.Deckwind.setBlockInput(true)
            end
            lastObject = hitOb
        end
    else
        destroyWindow()
        lastObject = nil
    end
end
local function objectUpdated(obj)
if obj then
    if canUse(obj) then
        if quickLootMenu then
            quickLootMenu:destroy()
        end
        I.Deckwind.setCurrentCat(1)
        quickLootMenu = I.Controller_Item_Window.createItemWindow(obj, 0.5, 0.5, false)
        quickLootMenu.selected = true
        quickLootMenu.listMode = true
        quickLootMenu.blockHeader = true
        quickLootMenu:setGridSize(1, 6)
        I.Camera.disableZoom()
        I.Camera.disableModeControl()
        I.Controls.overrideCombatControls(true)
        I.Deckwind.setBlockInput(true)
    end
end
end
return {
    interfaceName = "ControllerInterface_QL",
    interface = {
        version = 1,
       destroyWindow = destroyWindow,



    },
    eventHandlers = {
        CI_objectUpdated = objectUpdated
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onUpdate,
        onActive = onActive,
        onControllerButtonPress = onControllerButtonPress,
        onInputAction = onInputAction,
        onSave = onSave,
        onLoad = onLoad,
        onControllerButtonRelease = onControllerButtonRelease,
    }
}
