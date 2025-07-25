-- File: propaneDeliveryUI.lua

PropaneDeliveryUI = {}
PropaneDeliveryUI.__index = PropaneDeliveryUI

function PropaneDeliveryUI:new(productionScreen, deliverySystem)
    local self = setmetatable({}, PropaneDeliveryUI)
    self.productionScreen = productionScreen
    self.deliverySystem = deliverySystem

    -- Patch the update function for the production details panel
    self.originalUpdateDetails = productionScreen.updateProductionDetails

    productionScreen.updateProductionDetails = function(screen, production, ...) 
        self.originalUpdateDetails(screen, production, ...)
        self:onProductionSelected(screen, production)
    end

    return self
end

function PropaneDeliveryUI:onProductionSelected(screen, production)
    if not production then return end

    local tankId = production.id
    local tank = self.deliverySystem:getTankById(tankId)
    if not tank then return end -- not a propane tank

    -- Add our custom "Propane Delivery" button
    if self.button == nil then
        self.button = ButtonElement:new()
        self.button:setText("Propane Delivery")
        self.button.onClickCallback = function()
            self:openDeliveryDialog(tankId, tank)
        end
        screen.pageButtonBox:addElement(self.button)
    end

    self.button:setVisible(true)
end

function PropaneDeliveryUI:openDeliveryDialog(tankId, tank)
    local fillLevel = tank:getFillLevel()
    local capacity = tank:getCapacity()
    local spaceLeft = capacity - fillLevel

    if spaceLeft <= 0 then
        g_gui:showInfoDialog({
            text = "
