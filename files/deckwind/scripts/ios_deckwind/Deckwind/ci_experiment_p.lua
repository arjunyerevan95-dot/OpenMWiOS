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

local currentMode
local forcemodes = {

    Scroll = false,
    Interface = false,
    Container = false,
    Companion = false,
    Travel = false,
    QuickKeysMenu = true,
    Journal = true,
    Book = false,
    Rest = false,
    Repair = true,
    Jail = false,
    ChargenClassReview = true,
    ChargenClassCreate = true,
    ChargenClassPick = true,
    ChargenClassGenerate = true,
    ChargenClass = true,
    ChargenBirth = true,
    ChargenRace = true,
    ChargenName = true,
    LevelUp = false,
    MerchantRepair = true,
    Training = false,
    Recharge = true,
    Enchanting = true,
    SpellCreation = true,
    SpellBuying = false,
    Barter = false,
    Dialogue = true,
    Alchemy = true,
    MainMenu = false,
}
--This file holds functions that aren't added to the game yet, but I want to try out, and easily change.
local canDoChanges = input._isGamepadCursorActive ~= nil
local function toggleCursorVisible(state,force)
    if not canDoChanges then
        return
    end
    if not force  then
        if currentMode then
            if forcemodes[currentMode] then

            else
                return
            end
        end
    end
    input._setGamepadCursorActive(state)

    ---I.CI_Expirement.toggleCursorVisible(false)
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
local function setObjectOwner(obj,owner)
    if obj.owner then
     obj.owner.recordId = owner
    else
         obj.ownerRecordId  = owner
    end
end
local function setObjectOwnerFaction(obj,owner)
    if obj.owner then
         obj.owner.factionId = owner
    else
         obj.ownerFactionId = owner
    end
end
local function isGamepadCursorActive()
    if canDoChanges then
        return input._isGamepadCursorActive()
    end
end
local function triggerTheftCrime(amount)

end
local modes = {

    Scroll = false,
    Interface = false,
    Container = false,
    Companion = false,
    Travel = false,
    QuickKeysMenu = true,
    Journal = true,
    Book = false,
    Rest = false,
    Repair = true,
    Jail = false,
    ChargenClassReview = true,
    ChargenClassCreate = true,
    ChargenClassPick = true,
    ChargenClassGenerate = true,
    ChargenClass = true,
    ChargenBirth = true,
    ChargenRace = true,
    ChargenName = true,
    LevelUp = false,
    MerchantRepair = true,
    Training = false,
    Recharge = true,
    Enchanting = true,
    SpellCreation = true,
    SpellBuying = false,
    Barter = false,
    Dialogue = true,
    Alchemy = true,
    MainMenu = false,
}
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)

local function UiModeChanged(data)
    local newMode = data.newMode
    if modes[newMode] ~= nil then
        local state = modes[newMode]
        if newMode == "Dialogue" and  playerSettings:get("defaultDialogCursor")  ~= nil then
            state = playerSettings:get("defaultDialogCursor")
        end
        toggleCursorVisible(state)
    end
    currentMode = newMode
    --print(newMode, modes[newMode])
end
local function openEmptyUIWindow()
    I.UI.setMode("Interface",{windows = {}})
   -- I.UI.setMode("Loading",{windows = {}})
end

local function getPlayerReputation()
    return 0
end
return {
    interfaceName = "CI_Expirement",
    interface = {
        version = 1,
        toggleCursorVisible = toggleCursorVisible,
        triggerTheftCrime = triggerTheftCrime,
        getPlayerReputation= getPlayerReputation,
        isGamepadCursorActive = isGamepadCursorActive,
        getObjectOwner = getObjectOwner,
        getObjectOwnerFaction = getObjectOwnerFaction,
        setObjectOwner = setObjectOwner,
        setObjectOwnerFaction = setObjectOwnerFaction,
        openEmptyUIWindow = openEmptyUIWindow,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged
    },
    engineHandlers = {
    }
}
