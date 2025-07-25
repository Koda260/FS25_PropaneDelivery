-- File: propaneDelivery.lua

PropaneDelivery = {}
PropaneDelivery_mt = Class(PropaneDelivery)

local DELIVERY_FEE = 1000
local DAILY_DISCOUNT = 0.10
local DELIVERY_HOUR = 6 -- 6:00 AM

function PropaneDelivery:new(mission, modDirectory)
    local self = setmetatable({}, PropaneDelivery_mt)
    self.mission = mission
    self.modDirectory = modDirectory
    self.dailySubscriptions = {} -- tankId => {enabled, nextDeliveryTime, cancelAfterTime}
    self.tanks = {} -- tankId => tank object
    self:registerEvents()
    return self
end

function PropaneDelivery:registerTank(tankId, tankObject)
    self.tanks[tankId] = tankObject
end

function PropaneDelivery:registerEvents()
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end)
end

function PropaneDelivery:hourChanged()
    local hour = g_currentMission.environment.currentHour
    if hour == DELIVERY_HOUR then
        for tankId, sub in pairs(self.dailySubscriptions) do
            if sub.enabled and g_currentMission.time >= sub.nextDeliveryTime then
                self:performDelivery(tankId, true)

                if sub.cancelAfterTime and g_currentMission.time >= sub.cancelAfterTime then
                    sub.enabled = false
                    sub.cancelAfterTime = nil
                end
            end
        end
    end
end

function PropaneDelivery:performDelivery(tankId, isAutomated)
    local tank = self:getTankById(tankId)
    if not tank then return end

    local fillLevel = tank:getFillLevel()
    local capacity = tank:getCapacity()
    local toFill = capacity - fillLevel
    if toFill <= 0 then return end

    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(FillType.PROPANE)
    local totalCost = pricePerLiter * toFill + DELIVERY_FEE
    if isAutomated then totalCost = totalCost - (DELIVERY_FEE * DAILY_DISCOUNT) end

    if g_currentMission:getMoney() >= totalCost then
        tank:setFillLevel(capacity)
        g_currentMission:addMoney(-totalCost, g_currentMission.player.farmId)
        print(string.format("Propane delivered to tank %s for $%.2f", tankId, totalCost))
    else
        print("Not enough money for propane delivery.")
    end
end

function PropaneDelivery:getTankById(tankId)
    return self.tanks[tankId]
end

function PropaneDelivery:enableDailyDelivery(tankId)
    local now = g_currentMission.time
    self.dailySubscriptions[tankId] = {
        enabled = true,
        nextDeliveryTime = self:getNext6AMTime(now + 86400000), -- start next day
        cancelAfterTime = nil
    }
end

function PropaneDelivery:disableDailyDelivery(tankId)
    local sub = self.dailySubscriptions[tankId]
    if not sub or not sub.enabled then return false end

    local now = g_currentMission.time
    local timeUntilNextDelivery = sub.nextDeliveryTime - now

    if timeUntilNextDelivery >= 86400000 then -- 24h in ms
        sub.enabled = false
        sub.cancelAfterTime = nil
        return true
    else
        sub.cancelAfterTime = sub.nextDeliveryTime + 86400000
        return true
    end
end

function PropaneDelivery:getNext6AMTime(fromTime)
    local dayInMs = 86400000
    local today6AM = math.floor(fromTime / dayInMs) * dayInMs + (DELIVERY_HOUR * 60 * 60 * 1000)
    if fromTime < today6AM then
        return today6AM
    else
        return today6AM + dayInMs
    end
end

g_modPropaneDelivery = PropaneDelivery:new(g_currentMission, g_currentModDirectory)
