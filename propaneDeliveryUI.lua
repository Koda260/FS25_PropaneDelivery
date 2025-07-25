-- File: propaneDeliveryUI.lua

PropaneDeliveryUI = {}
PropaneDeliveryUI.__index = PropaneDeliveryUI

function PropaneDeliveryUI:new(productionScreen, deliverySystem)
    local self = setmetatable({}, PropaneDeliveryUI)
    self.productionScreen = productionScreen
    self.deliverySystem = deliverySystem
    self:injectButton()
    return self
end

function PropaneDeliveryUI:injectButton()
    if not self.productionScreen or not self.productionScreen.buttonFrame then
        print("[PropaneDeliveryUI] Failed to inject UI: buttonFrame not found.")
        return
    end

    self.button = ButtonElement:new()
    self.button:setText("Propane Delivery")
    self.button.onClickCallback = function()
        self:openDialog()
    end

    self.productionScreen.buttonFrame:addElement(self.button)
end

function PropaneDeliveryUI:openDialog()
    local selectedProduction = self.productionScreen.production
    if not selectedProduction or not selectedProduction.fillTypeStats then
        print("[PropaneDeliveryUI] No production selected or no fill stats.")
        return
    end

    local tankId = selectedProduction.id
    local tank = self.deliverySystem:getTankById(tankId)
    if not tank then
        print("[PropaneDeliveryUI] Selected production is not a registered propane tank.")
        return
    end

    local dialog = g_gui.guis["MessageDialog"]
    local fillLevel = tank:getFillLevel()
    local capacity = tank:getCapacity()
    local spaceLeft = capacity - fillLevel

    local message = string.format("Tank has %d L propane.\nSelect amount to deliver:", fillLevel)

    g_gui:showDialog({
        target = self,
        text = message,
        dialogType = DialogElement.TYPE_OK_CANCEL,
        yesButtonText = "Deliver Max",
        noButtonText = "Cancel",
        callback = function(_, result)
            if result == DialogElement.BUTTON_YES then
                self.deliverySystem:performDelivery(tankId, false)
            end
        end
    })
end
