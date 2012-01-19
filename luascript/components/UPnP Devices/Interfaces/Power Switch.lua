--[[

not in use

--]]

require 'DeviceManager.Controls.Range'
require 'DeviceManager.Controls.Toggles'
require 'DeviceManager.Controls.List'
require 'DeviceManager.Controls.Transport'
require 'DeviceManager.Controls.Image'
require 'DeviceManager.Controls.Time'


local Controls = DeviceManager.Controls.Classes


local Super = require 'Components.UPnP (xPL).UPnP Devices.Interfaces.Base'

local interface = Super:New ( {

    UPnPServiceID = 'urn:upnp-org:serviceId:SwitchPower.0001',
    
    UPnPVariableName = 'Status',
    
    DMControlID = 'Switch',

    
    --[[
    
    UPnP
    
    --]]
    
    
    SetUPnPVariableValue = function (self,value)
        local service = self:GetUPnPDeviceService ()
        service.methods.SetTarget:execute (value == 'On' and 1 or 0)
	end,
    
    
    UPnPVariableUpdate = function (self)
        local value = tonumber (self:GetUPnPVariableValue ())
        self.DMDevice:EventFromProvider (DeviceManager.Devices.Events.Condition,'Switch',value == 1 and 'On' or 'Off')
    end,
    
    
    
} )


return interface
