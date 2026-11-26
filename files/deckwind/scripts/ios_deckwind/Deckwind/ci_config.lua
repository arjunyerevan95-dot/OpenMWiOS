local ci_config = {}
local ui = require("openmw.ui")

local v2 = require("openmw.util").vector2
ci_config.boxTemplate = {
    -- template = I.MWUI.templates.boxTransparentThick,
    type = ui.TYPE.Container,
    props = {
        relativePosition = v2(1, 01),
        anchor = v2(1, 1),
        vertical = false,
        relativeSize = v2(0.1, 1),
        arrange = ui.ALIGNMENT.Center
    },
}
