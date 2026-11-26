local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local function getWeaponTooltipType(record)
    local type = record.type
    local wt = types.Weapon.TYPE
    local thanded = ", " .. core.getGMST("sTwoHanded")
    local ohanded = ", " .. core.getGMST("sOneHanded")
    if type == wt.Arrow or type == wt.Bolt or type == wt.MarksmanCrossbow or type == wt.MarksmanThrown or type == wt.MarksmanBow then
        return core.getGMST("sSkillMarksman")
    elseif type == wt.AxeOneHand then
        return core.getGMST("sSkillAxe") .. ohanded
    elseif type == wt.AxeTwoHand then
        return core.getGMST("sSkillAxe") .. thanded
    elseif type == wt.BluntOneHand then
        return core.getGMST("sSkillBluntweapon") .. ohanded
    elseif type == wt.BluntTwoClose or type == wt.BluntTwoWide then
        return core.getGMST("sSkillBluntweapon") .. thanded
    elseif type == wt.LongBladeOneHand then
        return core.getGMST("sSkillLongblade") .. ohanded
    elseif type == wt.LongBladeTwoHand then
        return core.getGMST("sSkillLongblade") .. thanded
    elseif type == wt.ShortBladeOneHand then
        return core.getGMST("sSkillShortblade") .. ohanded
    elseif type == wt.SpearTwoWide then
        return core.getGMST("sSkillSpear") .. thanded
    else
        return "Unhandled weapon type"
    end
end
local function genMagicTooltips(list, spellRecord, item)
    local name = spellRecord.name

    table.insert(list,name)
    for index, value in ipairs(spellRecord.effects) do
        local range = nil
        if value.range == core.magic.RANGE.Self then
            range = core.getGMST("sRangeSelf")
        elseif value.range == core.magic.RANGE.Target then
            range = core.getGMST("sRangeTarget")
        elseif value.range == core.magic.RANGE.Touch then
            range = core.getGMST("sRangeTouch")
        end
        local name = value.effect.name
        if value.affectedAttribute then
            name = name .. " " .. value.affectedAttribute
        elseif value.affectedSkill then
            name = name .. " " .. value.affectedSkill
        end
        local line
        if item and item.type == types.Potion then
            range = ""
        else
            range = " on " .. range
        end
        if item and item.type == types.Ingredient then
            line = string.format("%s", name)
        elseif value.magnitudeMin == value.magnitudeMax then
            line = string.format("%s %g pts for %g secs%s", name, value.magnitudeMax, value.duration, range)
        else
            line = string.format("%s %g to %g pts for %g secs%s", name, value.magnitudeMin, value.magnitudeMax,
                value.duration, range)
        end

        table.insert(list, { text = "   " .. line, icon = value.effect.icon })
    end
end

local function getItemNormalizedHealth(itemData, maxCondition)
    if itemData.condition == 0 or not itemData.condition then
        return 0.0
    else
        return itemData.condition / tonumber(maxCondition)
    end
end
local useSoulgemRebalance = false

local function getConditionValues(item)
    local maxCondition = 0
    if record.health then
        maxCondition = record.health
    elseif record.maxCondition then
        maxCondition = record.maxCondition
    end
    local itemData = types.Item.itemData(item)
    local norm = getItemNormalizedHealth(itemData, maxCondition)
end
local function getConditionLine(item)
    local line = nil
    local currentCondition = types.Item.itemData(item).condition
    if item.type == types.Light then
    elseif item.type == types.Armor or item.type == types.Weapon then
        local maxCondition = item.type.records[item.recordId].health
        line = "Condition: " .. tostring(math.floor(currentCondition or maxCondition)) .. "\\" .. tostring(maxCondition)
    elseif item.type == types.Lockpick or item.type == types.Probe then
        local maxCondition = item.type.records[item.recordId].maxCondition
        line               = "Uses: " .. tostring(currentCondition or maxCondition)
    end
    return line
end
local function getItemValue(item, ignoreCondition)
    local record = item.type.records[item.recordId]
    local value = record.value
    local maxCondition = 0
    if record.health then
        maxCondition = record.health
    elseif record.maxCondition then
        maxCondition = record.maxCondition
    end
    local itemData = types.Item.itemData(item)
    if itemData and itemData.condition and not ignoreCondition then
        value = value * getItemNormalizedHealth(itemData, maxCondition)
    end
    if item.type == types.Miscellaneous then
        local soul = types.Miscellaneous.getSoul(item)
        if soul and types.Creature.record(soul) then
            local soulValue = types.Creature.record(soul).soulValue
            if useSoulgemRebalance then
                local soulValueNum = 0.0001 * soulValue ^ 3 + 2 * soulValue

                -- Check if the item is Azura's star
                if item.recordId == "misc_soulgem_azura" then
                    value = value + soulValueNum
                else
                    value = soulValueNum
                end
            else
                value = value * soulValue
            end
        end
    end
    return math.floor(value)
end
local function getArmorType(armor)
    if armor.type ~= types.Armor and not armor.baseArmor then
        error("Not Armor")
    end
    local record = nil
    if armor.baseArmor then --A record was supplied, not a gameObject
        record = armor
    else
        record = types.Armor.record(armor)
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
        return "Light"
    elseif weight <= armorTypeWeight * medMultiplier then
        return "Medium"
    else
        return "Heavy"
    end
end
local function genToolTips(item)
    local list = {}
    if item.spell and not item.spell.recordId then
        genMagicTooltips(list, item.spell, nil)
        return list
    elseif item.spell and item.spell.recordId then
        item = item.spell
    end
    if not item.type then
        return {}
    end
    local record = item.type.records[item.recordId]
    local name = record.name
    if item.type == types.Miscellaneous and types.Miscellaneous.getSoul(item) then
        local soulName = types.Creature.record(types.Miscellaneous.getSoul(item)).name
        name = name .. " (" .. soulName .. ")"
    end
    if item.count > 1 then
        name = name .. " (" .. tostring(item.count) .. ")"
    end
    table.insert(list, name)
    if item.type == types.Weapon then
        local weaponType = getWeaponTooltipType(record)
        table.insert(list, weaponType)
        if weaponType == core.getGMST("sSkillMarksman") then
            table.insert(list,
                string.format(core.getGMST("sAttack") .. ": %g - %g", types.Weapon.records[item.recordId].chopMinDamage,
                    types.Weapon.records[item.recordId].chopMaxDamage))
        else
            table.insert(list,
                string.format(core.getGMST("sChop") .. ": %g - %g", types.Weapon.records[item.recordId].chopMinDamage,
                    types.Weapon.records[item.recordId].chopMaxDamage))
            table.insert(list,
                string.format(core.getGMST("sSlash") .. ": %g - %g", types.Weapon.records[item.recordId].slashMinDamage,
                    types.Weapon.records[item.recordId].slashMaxDamage))
            table.insert(list,
                string.format(core.getGMST("sThrust") .. ": %g - %g", types.Weapon.records[item.recordId].thrustMinDamage,
                    types.Weapon.records[item.recordId].thrustMaxDamage))
        end
    end
    local conditionLine = getConditionLine(item)
    if conditionLine then
        table.insert(list, conditionLine)
    end
    if item.type == types.Armor then
        local weightType = getArmorType(item)
        table.insert(list,
            core.getGMST("sWeight") .. ": " .. tostring(math.floor(record.weight)) .. " (" .. weightType .. ")")
        local armorSkillType = weightType:lower() .. "armor"
        local rating = types.Armor.records[item.recordId].baseArmor * (types.NPC.stats.skills[armorSkillType](self).modified / 30)
        table.insert(list, core.getGMST("sArmorRating") .. ": " .. tostring(math.floor(rating)))
    elseif record.weight > 0 then
        local weight = record.weight
        local formattedWeight = tostring(math.floor(weight))

        if weight % 1 ~= 0 then
            formattedWeight = formattedWeight .. string.format("%.1f", weight % 1):sub(2)
        end
        table.insert(list, core.getGMST("sWeight") .. ": " .. formattedWeight)
    end
    local value = getItemValue(item)
    if value > 0 then
        table.insert(list, core.getGMST("sValue") .. ": " .. tostring(value))
    end
    local spacing = "   "
    if record.enchant ~= "" and record.enchant ~= nil then
        local enchant = core.magic.enchantments.records[record.enchant]
        if enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            table.insert(list, core.getGMST("sItemCastWhenStrikes"))
        elseif enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
            table.insert(list, core.getGMST("sItemCastWhenUsed"))
        elseif enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
            table.insert(list, core.getGMST("sItemCastOnce"))
        elseif enchant.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            table.insert(list, core.getGMST("sItemCastConstant"))
        end
        genMagicTooltips(list, enchant, item)
    elseif item.type == types.Potion or item.type == types.Ingredient then
        genMagicTooltips(list, record, item)
    end
    return list
end
return { genToolTips = genToolTips, getItemValue = getItemValue, getItemNormalizedHealth = getItemNormalizedHealth }
