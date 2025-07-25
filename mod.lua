-- File: mod.lua

source(g_currentModDirectory .. "propaneDelivery.lua")
source(g_currentModDirectory .. "propaneDeliveryUI.lua")

-- Initialize UI once the game loads the production menu
g_onCreateLoadedObjects:registerObject("PropaneDeliveryStartup", function()
    if g_productionChainScreen and g_modPropaneDelivery then
        g_propaneDeliveryUI = PropaneDeliveryUI:new(g_productionChainScreen, g_modPropaneDelivery)
    else
        print("[PropaneDelivery] Could not hook into production screen.")
    end
end)
