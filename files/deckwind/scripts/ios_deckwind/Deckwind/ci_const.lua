
local storage = require("openmw.storage")
local core = require("openmw.core")
local key = "SettingsControllerInterface"
local globalSettings = storage.globalSection(key)

local doesRun =globalSettings:get("enableMod")
if core.API_REVISION < 60 then
    doesRun = false
end
return {key = key, doesRun = doesRun}
