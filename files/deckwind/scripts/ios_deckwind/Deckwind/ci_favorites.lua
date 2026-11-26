if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local favoriteItems = {}
local favoriteMagic = {}
local function addFavoriteItem(ID)
    favoriteItems[ID] = true
end
local function removeFavoritedItem(ID)
    favoriteItems[ID] = nil
end
local function addFavoriteMagic(ID)
    favoriteMagic[ID] = true
end
local function removeFavoriteMagic(ID)
    favoriteMagic[ID] = nil
end
local function hasFavoriteMagic(ID)
   return favoriteMagic[ID] ~= nil
end
local function getFavoriteItemCount()
    local count = 0
    for index, value in pairs(favoriteItems) do
        count = count + 1
    end
    return count
end
local function hasFavoriteItem(recordId)
    return favoriteItems[recordId] ~= nil

end
local function toggleFavoriteItem(ID)
    if favoriteItems[ID] then
        removeFavoritedItem(ID)
    else
        addFavoriteItem(ID)
    end
end
local function toggleFavoriteMagic(ID)
    if favoriteMagic[ID] then
        removeFavoriteMagic(ID)
    else
        addFavoriteMagic(ID)
    end
end

return {
    interfaceName = "Controller_Favorites",
    interface = {
        version = 1,
        addFavoriteItem = addFavoriteItem,
        removeFavoritedItem = removeFavoritedItem,
        addFavoriteMagic = addFavoriteMagic,
        removeFavoriteMagic = removeFavoriteMagic,
        hasFavoriteMagic = hasFavoriteMagic,
        getFavoriteItemCount = getFavoriteItemCount,
        toggleFavoriteItem = toggleFavoriteItem,
        toggleFavoriteMagic = toggleFavoriteMagic,
        getFavoriteItems = function ()
            return favoriteItems--I.Controller_Favorites.favoriteItems()
        end
        ,hasFavoriteItem=hasFavoriteItem,
    },
    engineHandlers = {
        onSave = function()
            local data = {}
            data.favoriteItems = favoriteItems
            data.favoriteMagic = favoriteMagic
            return data
        end
        ,
        onLoad = function(data)
            if not data then return end
            favoriteItems = data.favoriteItems
            favoriteMagic = data.favoriteMagic
        end
    }
}
