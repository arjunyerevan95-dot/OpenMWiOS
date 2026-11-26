local menu = require('openmw.menu')

-- Menu scripts start before game storage is available. Only the enabled Deckwind
-- player script sends this event.
return {
    eventHandlers = {
        iosDeckwindQuickSave = function()
            menu.saveGame('Quicksave', 'quicksave')
        end,
    },
}
