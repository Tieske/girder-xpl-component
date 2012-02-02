--[[


Volume


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
    
    UPnPVariableName = 'Volume',
    
    DMControlID = 'Volume',

    --RequestUPnPVariableAtStartup = true, 
    
    
    --[[
    
    UPnP
    
    --]]
    
    
    -- retuns a list of paramters to send the exexute function
    GetSetUPnPVariableValueParameters = function (self,value)
        return {
            1,
            'Master',
            value,
        }
	end,
    
    
    GetGetUPnPVariableValueParameters = function (self)
        return {
            1,
            'Master',
        }
	end,
    
    
	--[[

	G5 DM Interface

	--]]


    -- creates a control for the device (if needed), returns false if this control is not valid for the supplied upnp device
    CreateControl = function (self)
        local VolumeControl = Controls.Volume:New({Name = self.DMControlID, Device = self:GetDMDevice ()}) 
        self:GetDMDevice ():AddControl(VolumeControl)
    end,

    
    UpdateControl = function (self,value)
        value = tonumber (value)
        
        Super.UpdateControl (self,value)
    end,
    
    
} )


return interface
