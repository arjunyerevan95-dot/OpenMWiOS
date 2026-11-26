local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local showBarLabel = true
local renderStat
local bit8 = 255
local statColors = {
    fatigue = util.color.rgb(0 / bit8, 150 / bit8, 60 / bit8),
    health = util.color.rgb(200 / bit8, 60 / bit8, 30 / bit8),
    magicka = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
    encumbrance = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
    level = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
}
local statTexture = ui.texture({ path = 'textures/menu_bar_gray.dds' })
local statSize = util.vector2(65, 13)
local dynamicStats = types.Actor.stats.dynamic
local function contEncumbranceData(cont)
    local encumCurrent = cont.type.getEncumbrance(cont)

    local baseCapac = 10
    if cont.type.getCapacity then
        baseCapac = cont.type.getCapacity(cont)
    end
    return { current = encumCurrent, base = baseCapac }
end

local function renderBar(color, base, current,position, size)
    if not color then
        color = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8)
    end
    local currentVal = current
    local baseVal = base
    if not size then
        size = statSize
    end
    local textSize = size.y
    if textSize > 20 then
        textSize = 20
    end
    local ratio = currentVal / baseVal

    local label
    if showBarLabel then
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = util.vector2(0.5, 0.5),

                anchor = util.vector2(0.5, 0.5),
                text = ('%i/%i'):format(math.floor(currentVal), math.floor(baseVal)),
                textColor = util.color.rgb(1, 1, 1),
                textSize = textSize,
            },
        }
    end
    return {
        template = I.MWUI.templates.boxTransparent,
        props = {

            arrange = alignment or ui.ALIGNMENT.Center,
            align = alignment or ui.ALIGNMENT.Center,
            position = position,
        },
        content = ui.content({
            {
                props = {
                    size = size,
                },
                content = ui.content({
                    {
                        name = 'image',
                        type = ui.TYPE.Image,
                        props = {
                            size = size:emul(util.vector2(ratio, 1)),
                            resource = statTexture,
                            color = color,
                        },
                    },
                    label,
                }),
            },
        }),
    }
end
renderStat = function(actor, key)

    if dynamicStats[key] then
        local stat = dynamicStats[key](actor)
        return renderBar(statColors[key], stat.base, stat.current)
    elseif key == "encumbrance" then
        local data = contEncumbranceData(actor)
        return renderBar(statColors[key], data.base, data.current)
    elseif key == "level" then
        return renderBar(statColors[key], 10, types.Actor.stats.level(actor).progress)
    end
end

return { renderStat = renderStat,renderBar = renderBar, contEncumbranceData = contEncumbranceData }
