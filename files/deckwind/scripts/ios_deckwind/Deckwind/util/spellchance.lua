local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local storage = require("openmw.storage")
local debug = require('openmw.debug')

local function getSpell(id)
return core.magic.spells.records[id]
end
local function calcSpellCost(spell)
    return spell.cost
    --TODO: fix this
end
local function calcSpellBaseSuccessChance(spell, actor)
    local effectiveSchool = {}
    if type(spell) == "string" then
        spell = getSpell(spell)
    end
    if not spell then return -1 end
    local maxFloat = math.huge
    local y = maxFloat
    local lowestSkill = 0

    for _, effect in ipairs(spell.effects) do
        local x = effect.duration
        local effectId = effect.id
        local magicEffect = core.magic.effects.records[effectId]

        if not magicEffect.isAppliedOnce	        then
            x = math.max(1, x)
        end

        x = x * 0.1 * magicEffect.baseCost
        x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
        x = x + effect.area * 0.05 * magicEffect.baseCost

        if effect.rangeType == core.magic.RANGE.Target then
            x = x * 1.5
        end

        local fEffectCostMult = core.getGMST("fEffectCostMult")
        x = x * fEffectCostMult

        local skillLevel = 2.0 * types.NPC.stats.skills[magicEffect.school](actor).modified
        if (skillLevel - x) < y then
            y = skillLevel - x
            if effectiveSchool then
                effectiveSchool = magicEffect.school -- Simulate pointer-like output
            end
            lowestSkill = skillLevel
        end
    end

    local willpower = types.NPC.stats.attributes["willpower"](actor).modified
    local luck = types.NPC.stats.attributes["luck"](actor).modified

    local cost = calcSpellCost(spell) -- You'll need a Lua version of this function too
    local castChance = (lowestSkill - cost + 0.2 * willpower + 0.1 * luck)

    return castChance, effectiveSchool
end
local function isPowerUsable(spell)
return true
end
local function getSilence(actor)
    local carryWeight = 0
    local totalFeather = 0
    for index, value in pairs(types.Actor.activeEffects(actor)) do
        --  print(value.id)
        if value.id == "silence" then
            local mag = value.magnitude
            if (mag > 1 ) then
            return true
            end
            --
        end
    end
    return false
end
local function getSound(actor)
    local carryWeight = 0
    local totalFeather = 0
    for index, value in pairs(types.Actor.activeEffects(actor)) do
        --  print(value.id)
        if value.id == "sound" then
            local mag = value.magnitude
            if (mag > 1 ) then
            return mag
            end
            --
        end
    end
    return 0
end
local function getFatigueTerm(actor)
    local max = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.fatigue(actor).modifier
    local current = types.Actor.stats.dynamic.fatigue(actor).current

    local normalised = math.floor(max) == 0 and 1 or math.max(0, current / max)

    local fFatigueBase = core.getGMST("fFatigueBase")
    local fFatigueMult = core.getGMST("fFatigueMult")

    return fFatigueBase - fFatigueMult * (1 - normalised)
end
local function getSpellSuccessChance(spell, actor, effectiveSchool, cap, checkMagicka)
    cap = true
    checkMagicka = true
    if type(spell) == "string" then
        spell = getSpell(spell)
    end
    local baseChance, effectiveSchool = calcSpellBaseSuccessChance(spell, actor)

    local isPlayer = actor.type == types.Player
    local godMode = isPlayer and debug.isGodMode()  -- This may vary depending on how godmode is exposed

    local stats = actor.stats

    local silence = getSilence(actor)
    if silence and not godMode then
        return 0
    end

    if spell.type == core.magic.SPELL_TYPE.Power then
        return isPowerUsable(spell) and 100 or 0
    end

    if godMode then
        return 100
    end

    if spell.type ~= core.magic.SPELL_TYPE.Spell then
        return 100
    end

    if checkMagicka then
        local cost = calcSpellCost(spell)
        if cost > 0 and types.Actor.stats.dynamic.magicka(actor).current < cost then
            return 0
        end
    end

    if spell.alwaysSucceedFlag then
        return 100
    end

    local sound = getSound(actor)
    local castBonus = sound and -sound or 0
    local castChance = baseChance + castBonus
    castChance = castChance * getFatigueTerm(actor) -- Usually between 0.75 and 1.25
    if castChance < 0 then
        castChance = 0
    end
return math.floor(castChance)

end
return {calcSpellBaseSuccessChance = calcSpellBaseSuccessChance, getSpellSuccessChance = getSpellSuccessChance}
