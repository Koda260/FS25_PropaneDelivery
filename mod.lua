print("🔥 FS25_PropaneDelivery: mod.lua executed")

-- File: mod.lua

modDirectory = g_currentModDirectory
print("[PropaneDelivery] mod.lua loading...")

source(modDirectory .. "propaneDelivery.lua")
source(modDirectory .. "propaneDeliveryUI.lua")

-- Create delivery system
g_modPropaneDelivery = PropaneDelivery:new(g_currentMission, modDirectory)

-- Wait until production screen exists, then inject UI
local function onPostLoadMap()
    if g_productionChainScreen ~= nil then
        print("[PropaneDeliveryUI] Initializing PropaneDeliveryUI...")
        g_propaneDeliveryUI = PropaneDeliveryUI:new(g_productionChainScreen, g_modPropaneDelivery)
    else
        print("[PropaneDeliveryUI] g_productionChainScreen not available yet")
    end
end

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, onPostLoadMap)
