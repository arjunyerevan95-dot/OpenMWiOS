if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local acti  = require("openmw.interfaces").Activation
local core  = require("openmw.core")
local world = require("openmw.world")
local util  = require("openmw.util")
local I     = require("openmw.interfaces")
local async = require("openmw.async")
local c = require('openmw.interfaces').Crimes

local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end
local function Crime_Level_set(data)
    types.Player.setCrimeLevel(data.player, data.amount)
end
local tempItem
local delay = 0
local famount = 0

local pendingCrime = 0

local function hackCrime(container, amount)
    local owner = container.owner.recordId
    local ownerObject
    local ownerFaction = container.owner.factionId
    if owner then
        for i, x in ipairs(world.activeActors )do
            if x.recordId == owner then
                ownerObject = x
            end

        end
    end
    c.commitCrime(world.players[1],{arg = 100,type = types.Player.OFFENSE_TYPE.Theft,victim = ownerObject, faction = ownerFaction})
    -- if pendingCrime == 0 then
    --     pendingCrime = amount
    --     async:newUnsavableSimulationTimer(0.1, function()
    --         tempItem = world.createObject("misc_com_bottle_13")
    --         tempItem:teleport(container.cell, world.players[1].position)
    --         tempItem.owner.recordId = container.owner.recordId
    --         tempItem.owner.factionId = container.owner.factionId
    --         tempItem.owner.factionRank = container.owner.factionRank
    --         world.players[1]:sendEvent("bounceBack", 1)
    --         famount = pendingCrime
    --         pendingCrime = 0
    --     end)
    -- else
    --     pendingCrime = pendingCrime + amount
    -- end
end

local recordedCrime = 0
local function bounceBack1()
    recordedCrime = types.Player.getCrimeLevel(world.players[1])

    world._runStandardActivationAction(tempItem, world.players[1])
    --tempItem:activateBy(world.players[1])
    --print("bounce done")
    world.players[1]:sendEvent("bounceBack", 2)
end
local function bounceBack2()
    local bottle = types.Actor.inventory(world.players[1]):find("misc_com_bottle_13")
    if not bottle then
        error("unable to find placeholder")
    else
        bottle:remove(1)
    end
    if types.Player.getCrimeLevel(world.players[1]) > recordedCrime then
        types.Player.setCrimeLevel(world.players[1], types.Player.getCrimeLevel(world.players[1]) + famount - 1)
    end
end
return {
    interfaceName = "CrimeSystem",
    interface = {
        hackCrime = hackCrime,
    },
    eventHandlers = {
        Crime_Level_set = Crime_Level_set,
        hackCrime = hackCrime,
        bounceBack1 = bounceBack1,
        bounceBack2 = bounceBack2,
    }
}
