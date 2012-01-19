--[[


Mute


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

    UPnPServiceID = 'urn:upnp-org:serviceId:RenderingControl',
    
    UPnPVariableName = 'Mute',
    
    DMControlID = 'Mute',

    
    --[[
    
    UPnP
    
    --]]
    
    
    SetUPnPVariableValue = function (self,value)
        local service = self:GetUPnPDeviceService ()
        service.methods.SetMute:executeasync (1,'Master',value == 'On')
	end,
    

    UPnPVariableUpdate = function (self)
        --print ('upnpvariableupdate')
        local value = self:GetUPnPVariableValue ()
        self:UpdateControl (value and 'On' or 'Off')
    end,
    
    
    
	--[[

	G5 DM Interface

	--]]


    -- creates a control for the device (if needed), returns false if this control is not valid for the supplied upnp device
    CreateControl = function (self)
        local Control = Controls.Mute:New({Name = self.DMControlID, Device = self.DMDevice}) 
        self.DMDevice:AddControl(Control)
    end,
    
    
} )


return interface
