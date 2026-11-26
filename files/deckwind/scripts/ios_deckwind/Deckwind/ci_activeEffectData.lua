if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local util = require("openmw.util")
local self = require("openmw.self")
local ui = require("openmw.ui")
local input = require("openmw.input")
local ambient = require("openmw.ambient")


local function findEffectData()
    local effectSources = {}
    for i, x in pairs(types.Actor.activeSpells(self)) do
       -- print(x.id)
        for index, effect in pairs(x.effects) do
            if not effectSources[effect.id] then
                effectSources[effect.id] = {}
            end
            table.insert(effectSources[effect.id], {magnitude = effect.magnitudeThisFrame, source = x.id})
           -- print(effect.id, effect.magnitudeThisFrame)
        end

    end
    for xindex, xvalue in pairs(effectSources) do
        print(xindex)
        for index, value in ipairs(xvalue) do

        print( value.source, value.magnitude)
        end
    end
end
--I.CI_ActiveEffectData.findEffectData()
return {
    interfaceName = "CI_ActiveEffectData",
    interface = {
        findEffectData = findEffectData,
    }
    ,
    engineHandlers = {
    onSave = function ()
        return {}
    end,
    onLoad = function (data)
    end}
}
