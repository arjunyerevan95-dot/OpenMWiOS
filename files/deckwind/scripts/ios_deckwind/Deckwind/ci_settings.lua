
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local core = require("openmw.core")
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
if core.API_REVISION == 29 then
    I.Settings.registerPage {
        key = key,
        l10n = "Deckwind",
        name = "Deckwind",
        description =
        "You are running OpenMW 0.48, please update to a newer version(0.49 dev or newer) for this mod to work."
    }
    return {}

end
if core.API_REVISION < 60 then
    I.Settings.registerPage {
        key = key,
        l10n = "Deckwind",
        name = "Deckwind",
        description =
        "Your OpenMW version is too old for this mod to work, please download a new build."
    }
    return {}
end
I.Settings.registerPage {
    key = key,
    l10n = "Deckwind",
    name = "Deckwind",
    description =
    "Enable Deckwind here and restart OpenMW. Adjust the menu size under HUD & Menus."
}
