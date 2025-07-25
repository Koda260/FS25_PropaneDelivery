-- File: propaneDeliveryUI.lua

PropaneDeliveryUI = {}
PropaneDeliveryUI_mt = Class(PropaneDeliveryUI)

function PropaneDeliveryUI:new(productionChainsPage, deliverySystem)
    local self = setmetatable({}, PropaneDeliveryUI_mt)
    self.page = productionChainsPage
    self.deliverySystem = deliverySystem
    self:initUI()
    return self
end

function PropaneDeliveryUI:initUI()
    -- Hook into FS25 production chains page update
    local oldUpdate = self.page.updateProductionDetails
    self.page.updateProductionDetails = function(page, ...)
        oldUpdate(page, ...)
        self:addPropaneDeliveryButton()
    end
end

function PropaneDeliveryUI:addPropaneDeliveryButton()
    local selectedProduction = self.page:getSelectedProduction()
    if not selectedProduction then return end

    if not self:isPropaneTank(selectedProduction) then return end

    if self.button then
        self.button:setVisible(true)
        return
    end

    self.button = self.page:createButton("Propane Delivery", self.onOpenPopup, self)
    self.page:addFooterElement(self.button)
end

function PropaneDeliveryUI:isPropaneTank(production)
    -- Heuristic: match fillType or production name
    return production.name:lower():find("propane") ~= nil
end

function PropaneDeliveryUI:onOpenPopup()
    local selectedProduction = self.page:getSelectedProduction()
    if not selectedProduction then return end

    local tankId = selectedProduction.id or selectedProduction.name
    local tank = self.deliverySystem:getTankById(tankId)
    if not tank then return end

    local capacity = tank:getCapacity()
    local current = tank:getFillLevel()
    local space = capacity - current

    -- UI Frame
    local popup = self.page:createFrame("Propane Delivery")

    -- Slider
    local sliderSteps = {1,2,5,10,20,50,100,200,500,1000,2000,5000}
    for _, step in ipairs(sliderSteps) do
        if step <= space then
            popup:addSliderStep(tostring(step))
        end
    end
    if not tableContains(sliderSteps, space) then
        popup:addSliderStep(tostring(space))
    end
    popup:setSliderLabel("Liters to Deliver")

    -- Daily Delivery Checkbox
    local sub = self.deliverySystem.dailySubscriptions[tankId]
    local isEnabled = sub and sub.enabled
    popup:addCheckbox("Enable Daily Delivery", isEnabled, function(newState)
        if newState then
            self.deliverySystem:enableDailyDelivery(tankId)
        else
            self.deliverySystem:disableDailyDelivery(tankId)
        end
    end)

    -- Confirm Button
    popup:addButton("Confirm Delivery", function()
        local selectedAmount = tonumber(popup:getSliderValue())
        if selectedAmount > 0 then
            self.deliverySystem:performDeliveryManual(tankId, selectedAmount)
        end
        popup:close()
    end)

    popup:addButton("Cancel", function() popup:close() end)
    self.page:showPopup(popup)
end

function tableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end
