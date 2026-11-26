if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")

local function CI_SetCondition(data)
    --   core.sendGlobalEvent("CI_SetCondition", { object = value, condition = value.type.record(value).health })

    local condition = data.condition
    types.Item.itemData(self).condition = condition
    core.sendGlobalEvent("CI_RepairFinished", { object = self.object })

end
return {
    eventHandlers = {
        CI_SetCondition = CI_SetCondition,
        checkActive = function ()
            print("Recieved")
        end
    }
}
