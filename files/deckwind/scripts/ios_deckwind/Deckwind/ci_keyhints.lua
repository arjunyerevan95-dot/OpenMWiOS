if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local I = require("openmw.interfaces")
local input = require("openmw.input")
local const = require("scripts.ios_deckwind.Deckwind.ci_const")
if not const.doesRun then
    return {}
end

local function getActorServices(actor)
    if not actor then
        error("No actor")
    end
    local record = actor.type.records[actor.recordId]
    if not record then
        return {}
    end
    local services = record.servicesOffered
    local validServices = {}
    if services["Training"] then
        table.insert(validServices, "Training")
    end
    if services["Travel"] then
        table.insert(validServices, "Travel")
    end
    if services["Enchanting"] then
        table.insert(validServices, "Enchanting")
    end
    if services["Spells"] then
        table.insert(validServices, "Spells")
    end
    local barter = false
    if services["MagicItems"] then
        barter = true
    elseif services["RepairItems"] then
        barter = true
    elseif services["Weapon"] then
        barter = true
    elseif services["Armor"] then
        barter = true
    elseif services["Ingredients"] then
        barter = true
    elseif services["Books"] then
        barter = true
    elseif services["Picks"] then
        barter = true
    elseif services["Probes"] then
        barter = true
    elseif services["Apparatus"] then
        barter = true
    elseif services["Misc"] then
        barter = true
    elseif services["Potions"] then
        barter = true
    elseif services["Lights"] then
        barter = true
    elseif services["Clothing"] then
        barter = true
    end
    if barter then
        table.insert(validServices, "Barter")
    end
    --This needs to respect service refsual
    return validServices
end
local uiHints = {
    Journal = {
        DPadUp = "Previous Page",
        DPadDown = "Next Page",
        Y = "Open Quest Menu",
    },
    SpellBuying = {

        DPadUp = "Navigate List Up",
        DPadDown = "Navigate List Down",
        A = "Purchase Spell",
        B = "Exit Spell Buying",
    },
    Dialogue = {

    }
}
local keyData = {}
local function UiModeChanged(data)
    keyData = {}
    local newMode = data.newMode
    I.CI_Background.clearHotKeys()

    if newMode and uiHints[newMode] then
        for index, value in pairs(uiHints[newMode]) do
            I.CI_Background.addHotKey(value, index)
        end
        if newMode == "Dialogue" then
            local services = getActorServices(data.arg)
            local actor = data.arg
            keyData.actor = actor
            if services then
                if services[1] then
                    I.CI_Background.addHotKey(services[1], "Y")
                    keyData.YKey = services[1]
                end
                if services[2] then
                    I.CI_Background.addHotKey(services[2], "X")
                    keyData.XKey = services[2]
                end
            end
        end
        I.CI_Background.drawBottomBar()
    end
end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged
    },
    engineHandlers = {
        onControllerButtonPress = function(key)
            local buttonKeys = {
                [input.CONTROLLER_BUTTON.X] = keyData.XKey,
                [input.CONTROLLER_BUTTON.Y] = keyData.YKey
            }

            if buttonKeys[key] then
                local menu = buttonKeys[key]

                --NOTE: This bypasses service refusal(rank requirements)
                if menu == "Training" then
                    I.UI.setMode("Training", { target = keyData.actor })
                elseif menu == "Spells" then
                    I.UI.setMode("SpellBuying", { target = keyData.actor })
                elseif menu == "Barter" then
                    I.UI.setMode("Barter", { target = keyData.actor })
                elseif menu == "Travel" then
                    I.UI.setMode("Travel", { target = keyData.actor })
                elseif menu == "Open Quest Menu" then
                    I.CI_questlog.openQuestMenu()
                end
            end
        end
    }
}
