local types = require('openmw.types')
local core = require('openmw.core')
local tooltipgen = require("scripts.ios_deckwind.Deckwind.ci_tooltipgen")
---
-- `openmw_aux.core` defines utility functions for objects.
-- Implementation can be found in `resources/vfs/openmw_aux/core.lua`.
-- @module core
-- @usage local auxCore = require('openmw_aux.core')
local aux_core = {}

local SKILL = types.NPC.stats.skills

local armorSkillString = {[SKILL.heavyarmor] = "Heavy",[SKILL.mediumarmor] = "Medium", [SKILL.lightarmor] = "Light"}

---
-- Checks if the provided armor is Heavy, Medium, or Light. Errors if invaid object supplied.
-- @function [parent=#core] getArmorType
-- @param openmw.core#GameObject armor Either a gameObject or a armor record.
-- @return openmw.core#SKILL  The skill for this armor
function aux_core.getArmorType(armor)

    if armor.type ~= types.Armor and not armor.baseArmor then
        error("Not Armor")
    end
    local record = nil
    if armor.baseArmor then--A record was supplied, not a gameObject
        record = armor
    else
        record = types.Armor.record(armor.recordId)
    end
    local epsilon = 0.0005;
    local lightMultiplier = core.getGMST("fLightMaxMod") + epsilon
    local medMultiplier = core.getGMST("fMedMaxMod") + epsilon
    local armorGMSTs = {
        [types.Armor.TYPE.Boots] = "iBootsWeight",
        [types.Armor.TYPE.Cuirass] = "iCuirassWeight",
        [types.Armor.TYPE.Greaves] = "iGreavesWeight",
        [types.Armor.TYPE.Shield] = "iShieldWeight",
        [types.Armor.TYPE.LBracer] = "iGauntletWeight",
        [types.Armor.TYPE.RBracer] = "iGauntletWeight",
        [types.Armor.TYPE.RPauldron] = "iPauldronWeight",
        [types.Armor.TYPE.LPauldron] = "iPauldronWeight",
        [types.Armor.TYPE.Helmet] = "iHelmWeight",
        [types.Armor.TYPE.LGauntlet] = "iGauntletWeight",
        [types.Armor.TYPE.RGauntlet] = "iGauntletWeight",
    }
    local armorType = record.type
    local weight = record.weight
    local armorTypeWeight = math.floor(core.getGMST(armorGMSTs[armorType]))

    if weight <= armorTypeWeight * lightMultiplier then
        return SKILL.lightarmor
    elseif weight <= armorTypeWeight * medMultiplier then
        return SKILL.mediumarmor
    else
        return SKILL.heavyarmor
    end
end
local function getEffectiveArmorRating(ref, actor)
    local armorSkillType = aux_core.getArmorType(ref):lower() .. "armor"
    local armorSkill = types.NPC.stats.skills[armorSkillType](actor).modified

    local iBaseArmorSkill = core.getGMST("iBaseArmorSkill")
    local record = ref.type.records[ref.recordId]
    if record.weight == 0 then
        return record.baseArmor
    else
        return record.baseArmor * armorSkill / iBaseArmorSkill
    end
end
 function aux_core.getArmorRating(actor)
    if actor.type == types.Creature then
        return 0
    end
    local fUnarmoredBase1 = core.getGMST("fUnarmoredBase1")
    local fUnarmoredBase2 = core.getGMST("fUnarmoredBase2")
    local unarmoredSkill = types.NPC.stats.skills.unarmored(actor).modified

    local ratings = {}
    --  local i = 0
    local equipment = types.Actor.getEquipment(actor)
    for _, i in pairs(types.Actor.EQUIPMENT_SLOT) do
        --  i = i + 1
        local item = equipment[i]
        if not item or item.type ~= types.Armor then
            -- unarmored
            ratings[i] = (fUnarmoredBase1 * unarmoredSkill) * (fUnarmoredBase2 * unarmoredSkill)
        else
            ratings[i] = getEffectiveArmorRating(item, actor)

            -- Take into account armor condition
            local hasHealth = types.Item.itemData(item).condition
            if hasHealth then
                local maxCondition = item.type.record(item.recordId).health
                ratings[i] = ratings[i] * tooltipgen.getItemNormalizedHealth(types.Item.itemData(item), maxCondition)
            end
        end
    end

    local shield = types.Actor.activeEffects(actor):getEffect("shield") or 0
    if shield and shield ~= 0 then
        shield = shield.magnitude
    end
    local ret = ratings[types.Actor.EQUIPMENT_SLOT.Cuirass] * 0.3
        + (ratings[types.Actor.EQUIPMENT_SLOT.CarriedLeft] + ratings[types.Actor.EQUIPMENT_SLOT.Helmet]
            + ratings[types.Actor.EQUIPMENT_SLOT.Greaves] + ratings[types.Actor.EQUIPMENT_SLOT.Boots]
            + ratings[types.Actor.EQUIPMENT_SLOT.LeftPauldron] + ratings[types.Actor.EQUIPMENT_SLOT.RightPauldron])
        * 0.1
        + (ratings[types.Actor.EQUIPMENT_SLOT.LeftGauntlet] + ratings[types.Actor.EQUIPMENT_SLOT.RightGauntlet]) * 0.05
        + shield
    return math.floor(ret)
end
local weaponType = types.Weapon.TYPE
local weaponSound = {
    [weaponType.BluntOneHand] = "Weapon Blunt",
    [weaponType.BluntTwoClose] = "Weapon Blunt",
    [weaponType.BluntTwoWide] = "Weapon Blunt",
    [weaponType.MarksmanThrown] = "Weapon Blunt",
    [weaponType.Arrow] = "Ammo",
    [weaponType.Bolt] = "Ammo",
    [weaponType.SpearTwoWide] = "Weapon Spear",
    [weaponType.MarksmanBow] = "Weapon Bow",
    [weaponType.MarksmanCrossbow] = "Weapon Crossbow",
    [weaponType.AxeOneHand] = "Weapon Blunt",
    [weaponType.AxeTwoHand] = "Weapon Blunt",
    [weaponType.ShortBladeOneHand] = "Weapon Shortblade",
    [weaponType.LongBladeOneHand] = "Weapon Longblade",
    [weaponType.LongBladeTwoHand] = "Weapon Longblade",
}
local goldIds = { gold_001 = true, gold_005 = true, gold_010 = true, gold_025 = true, gold_100 = true }
local function getItemSound(object)
    local type = object.type
    if object.type.baseType ~= types.Item or not object then
        error("Invalid object supplied")
    end
    local record = object.type.record(object.recordId)
    local soundName = tostring(type) -- .. " Up"
    if type == types.Armor then
        soundName = "Armor " .. armorSkillString[aux_core.getArmorType(object)]
    elseif type == types.Clothing then
        soundName = "Clothes"
        if record.type == types.Clothing.TYPE.Ring then
            soundName = "Ring"
        end
    elseif type == types.Light or type == types.Miscellaneous then
        if goldIds[object.recordId] then
            soundName = "Gold"
        else
            soundName = "Misc"
        end
    elseif type == types.Weapon then
        soundName = weaponSound[record.type]
    end
    return soundName
end


---
-- Get the sound that should be played when this item is dropped.
-- @function [parent=#core] getDropSound
-- @param openmw.core#GameObject item
-- @return #string
function aux_core.getDropSound(item)
    local soundName = getItemSound(item)
    return string.format("Item %s Down", soundName)
end

---
-- Get the sound that should be played when this item is picked up.
-- @function [parent=#core] getPickupSound
-- @param openmw.core#GameObject item
-- @return #string
function aux_core.getPickupSound(item)
    local soundName = getItemSound(item)
    return string.format("Item %s Up", soundName)
end

return aux_core
