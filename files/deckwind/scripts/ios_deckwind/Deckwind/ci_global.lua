local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local overRide = false

local function getInventory(object)
    --Gets the inventory of an object, actor or container.
    if (object.type == types.NPC or object.type == types.Creature or object.type ==
            types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
end

local settings = require("scripts.ios_deckwind.Deckwind.ci_settings_g")

local const = require("scripts.ios_deckwind.Deckwind.ci_const")
if not const.doesRun then
    return {}
end
local function getObjectOwner(obj)
    if obj.owner then
        return obj.owner.recordId
    else
        return obj.ownerRecordId
    end
end
local function getObjectOwnerFaction(obj)
    if obj.owner then
        return obj.owner.factionId
    else
        return obj.ownerFactionId
    end
end
local function setObjectOwner(obj, owner)
    if obj.owner then
        obj.owner.recordId = owner
    else
        obj.ownerRecordId = owner
    end
end
local function setObjectOwnerFaction(obj, owner)
    if obj.owner then
        obj.owner.factionId = owner
    else
        obj.ownerFactionId = owner
    end
end
local function activateActor(actor, player)
    if overRide then
        return
    end
    if (types.Actor.stats.dynamic.health(actor).current == 0) then
        player:sendEvent("CI_openContainerInterface", actor)

        return false
    end
end
local function CI_SetTimeScale(val)
    world.setSimulationTimeScale(val)
end
local function resolveCont(object)
    if not getInventory(object):isResolved() then
        getInventory(object):resolve()
        world.players[1]:sendEvent("CI_objectUpdated", object)
    end
end
local function activateContainer(cont, actor)
    if not actor then
        actor = world.players[1]
    end
    if overRide then
        return
    end
    if (cont.type.isLocked(cont) or cont.type.getTrapSpell(cont) ~= nil) then
        return
    end
    if not getInventory(cont):isResolved() then
        getInventory(cont):resolve()
    end

    actor:sendEvent("CI_openContainerInterface", cont)
    return false
end
local function fixPosition(object, position)
    local bbox = object:getBoundingBox()


    local halfSize = object:getBoundingBox().halfSize.z
    local centerPos = object:getBoundingBox().center.z
    return util.vector3(position.x, position.y, position.z + halfSize - centerPos)
end
local function isInFaction(id)
    local player = world.players[1]
    -- print(id)
    if types.NPC.isExpelled(player, id) then
        return false
    end
    for i, x in pairs(types.NPC.getFactions(player)) do
        if x == id then
            return true
        end
    end
    return false
end
local function getItemFactionRank(obj)
    return obj.owner.factionRank
end
local function allowedToUseContainer(obj)
    if obj.type == types.Container then
        local player = world.players[1]
        if getObjectOwner(obj) then
            return false
        elseif obj.owner.factionId and isInFaction(obj.owner.factionId) and types.NPC.getFactionRank(player, obj.owner.factionId) >= getItemFactionRank(obj) then
            return true
        elseif obj.owner.factionId then
            return false
        end
    end
    return true
end
local pendingCrime = 0
local function CI_moveInto(data, holdCrime)
    local sourceObj = data.sourceObj
    local targetObj = data.targetObj
    local invItem = data.invItem
    local count = data.count
    local dropPos = data.dropPos
    local doCopy = data.doCopy
    local ignoreTheft = data.ignoreTheft
    local player = data.player or world.players[1]

    if count == nil then
        count = invItem.count
    end
    if invItem.count == 0 then
        return
    end

    if (targetObj == nil and dropPos ~= nil and invItem.count > 0) then
        invItem:teleport(sourceObj.cell, fixPosition(invItem, dropPos))
        player:sendEvent("CI_upDateinvWins")
        return
    end
    if not targetObj then
        targetObj = world.players[1]
    end
    if targetObj and targetObj.type == types.Player then
        if not ignoreTheft and not allowedToUseContainer(sourceObj) then
            if holdCrime then
                pendingCrime = pendingCrime + (invItem.type.record(invItem).value * count)
            else
                I.CrimeSystem.hackCrime(sourceObj, invItem.type.record(invItem).value * count)
            end
            --   types.Player.triggerCrime({amount = invItem.type.record(invItem).value * invItem.count,factionId = getObjectOwnerFaction(sourceObj), player = targetObj, victim =  getObjectOwner(sourceObj)})
            invItem:split(count):moveInto(targetObj)
        else
            if doCopy then
                invItem = world.createObject(invItem.recordId, count)
            end
            invItem:split(count):moveInto(targetObj)
        end
        player:sendEvent("CI_upDateinvWins")
        return
    end
    local targetInv = getInventory(targetObj)
    invItem:split(count):moveInto(targetInv)
    player:sendEvent("CI_upDateinvWins")
end
local function transferAllInv(data)
    if data.source.type == types.Player then
        return
    end
    pendingCrime = 0

    for index, value in ipairs(types.Actor.inventory(data.source):getAll()) do
        CI_moveInto(
            {
                sourceObj = data.source,
                targetObj = data.target,
                invItem = value,
                count = value.count,
                player = data
                    .player
            },
            true)
    end
    if pendingCrime > 0 then
        I.CrimeSystem.hackCrime(data.source, pendingCrime)
    end
end
local function onSave()
    --should really only do this if it was set to false before, by this script
    world.setSimulationTimeScale(1)
end
local function incrementPlayerGold(amount)
    if amount < 0 then
        local newGold = world.createObject("gold_001", math.abs(amount))
        newGold:moveInto(world.players[1])
    elseif amount == 0 then
        return
    else
        local oldGold = types.Actor.inventory(world.players[1]):find("gold_001")
        oldGold:remove(amount)
    end
end
local function disableCI()
    overRide = true
end
local function consumeOneItem(data)
    local object = data.object
    local actor = data.actor
    if object.count > 1 then
        --  object = object:split(1)
    end

    --core.sendGlobalEvent('UseItem', { object = object, actor = actor, force = true })
    --
    world._runStandardUseAction(object, actor, true)
end
--acti.addHandlerForType(types.Container, activateContainer)
--acti.addHandlerForType(types.Creature, activateActor)
--acti.addHandlerForType(types.NPC, activateActor)
local pendingRepair
local pendingRepairData
local function CI_SetCondition(data)
    --   core.sendGlobalEvent("CI_SetCondition", { object = value, condition = value.type.record(value).health })

    local object = data.object
    pendingRepair = object
    local condition = data.condition
    object:teleport(world.players[1].cell, world.players[1].position)
    pendingRepairData = data

    --    object:moveInto(world.players[1])
    --    types.Item.itemData(object).condition = condition
end
local objectToRepair
local function CI_RepairFinished(obj)
    objectToRepair:moveInto(world.players[1])
    objectToRepair = nil
end
local function onItemActive(obj)
    if pendingRepair and obj.id == pendingRepair.id then
        obj:sendEvent("CI_SetCondition", pendingRepairData)
        objectToRepair = obj
        pendingRepair = nil
    end
end
local function fillMap()
    local mapData = {}
    for i, x in ipairs(world.cells) do
        if x.name and x.isExterior then
            table.insert(mapData, { cell = { name = x.name }, id = x.name, item = x:getAll()[1] })
        end
        if x.isExterior then
            for index, value in ipairs(x:getAll(types.Door)) do
                if types.Door.destCell(value) then
                    table.insert(mapData, {
                        cell = { name = types.Door.destCell(value).name },
                        id = value.id,
                        position =
                            value.position
                    })
                end
            end
        end
    end
    world.players[1]:sendEvent("fillMap", mapData)
end

local lastRenderedInventoryItem = nil

local function CI_itemHoverRender(data)
    if lastRenderedInventoryItem then
        lastRenderedInventoryItem:remove()
    end

    local itemId = data.recordId
    local cell = data.cell
    local pos = data.position
    local rotation = data.rotation
    local scale = data.scale

    lastRenderedInventoryItem = world.createObject(itemId, 1)
    lastRenderedInventoryItem:teleport(cell, pos, rotation)
    lastRenderedInventoryItem:setScale(scale)
    world.players[1]:sendEvent("CI_itemHoverRenderCreated", {item = lastRenderedInventoryItem})
end
local function CI_removeItemHoverRender()
    if lastRenderedInventoryItem then
        lastRenderedInventoryItem:remove()
        lastRenderedInventoryItem = nil
    end
end
local function CI_updateRenderedItemRotation(data)
    if lastRenderedInventoryItem then
        -- CONFIG
        local rotationSpeed = 0.03
        local axisX = data.rightAxisX
        local axisY = data.rightAxisY
        local fov = data.fov

        -- CAMERA ORIENTATION
        local yaw = world.players[1].rotation:getYaw()
        local pitch = world.players[1].rotation:getPitch()

        print("yaw: " .. yaw)
        print("pitch: " .. pitch)

        -- STEP 1: Build forward vector from yaw and pitch (Z-up coordinate system)
        local cosPitch = math.cos(pitch)
        local sinPitch = math.sin(pitch)
        local cosYaw = math.cos(yaw)
        local sinYaw = math.sin(yaw)

        local forward = util.vector3(
            cosPitch * sinYaw,  -- X
            cosPitch * cosYaw,  -- Y
            -sinPitch           -- Z
        ):normalize()

        local right = util.vector3(
            cosYaw,    -- X
            -sinYaw,   -- Y
            0          -- Z
        ):normalize()

        local up = right:cross(forward):normalize()

        local angleX = axisX * rotationSpeed  -- left/right stick → rotate around screen-up
        local angleY = axisY * rotationSpeed  -- up/down stick   → rotate around screen-right

        local rotateAroundUp    = util.transform.rotate(angleX, up)
        local rotateAroundRight = util.transform.rotate(angleY, right)

        -- STEP 5: Combine and apply rotation to object
        local totalRotation = rotateAroundRight * rotateAroundUp
        local object = lastRenderedInventoryItem

        local newRotation = totalRotation * object.rotation
        object:teleport(object.cell, object.position, newRotation)
    end
end

return {
    eventHandlers = {
        fillMap = fillMap,
        CI_moveInto = CI_moveInto,
        CI_SetTimeScale = CI_SetTimeScale,
        resolveCont = resolveCont,
        incrementPlayerGold = incrementPlayerGold,
        disableCI = disableCI,
        consumeOneItem = consumeOneItem,
        CI_SetCondition = CI_SetCondition,
        CI_RepairFinished = CI_RepairFinished,
        transferAllInv = transferAllInv,
        activateContainer = activateContainer,
        CI_itemHoverRender = CI_itemHoverRender,
        CI_removeItemHoverRender = CI_removeItemHoverRender,
        CI_updateRenderedItemRotation = CI_updateRenderedItemRotation,
    },
    engineHandlers = { onUpdate = onUpdate, onItemActive = onItemActive, onLoad = onLoad, onSave = onSave, onFrame = onFrame },
}
