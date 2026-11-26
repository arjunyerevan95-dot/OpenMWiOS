if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local types = require("openmw.types")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local savedActorData = {

}

--I.CI_ActorGold.getActorGold(actor)
local function getActorGold(actor)
    local baseGold = actor.type.record(actor).baseGold
    if savedActorData[actor.id] then
        local time = core.getGameTime()
        local expireTime = savedActorData[actor.id].expireTime
        if time > expireTime then
            print("Time expired")
            savedActorData[actor.id] = nil
            return baseGold
        end
        return savedActorData[actor.id].currentGold
    else
        return baseGold
    end
end
local function setActorGold(actor,amount)
    if amount < 0 then
        amount = 0
    end
    --local baseGold = actor.type.record(actor).baseGold

    if savedActorData[actor.id] then
        savedActorData[actor.id].currentGold = amount
        print("Updating gold")
    else
        print("Setting gold")
        savedActorData[actor.id] = {currentGold = amount, expireTime = core.getGameTime() +time.hour * 24 }
    end

end
local function incrementActorGold(actor,amount)
    setActorGold(actor,getActorGold(actor) + amount)
end
return {
    interfaceName = "CI_ActorGold",
    interface = {
        getActorGold = getActorGold,
        setActorGold = setActorGold,
        incrementActorGold = incrementActorGold,
    }
    ,
    engineHandlers = {
    onSave = function ()
        return {savedActorData = savedActorData}
    end,
    onLoad = function (data)
        savedActorData = data.savedActorData or {}
    end}
}
