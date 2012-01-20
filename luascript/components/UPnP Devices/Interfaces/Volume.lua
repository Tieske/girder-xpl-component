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


local Super = require 'Components.UPnP Devices.Interfaces.Base'

local interface = Super:New ( {

    UPnPServiceID = 'urn:upnp-org:serviceId:RenderingControl',

    UPnPVariableName = 'Volume',

    DMControlID = 'Volume',


    --[[

    UPnP

    --]]


    SetUPnPVariableValue = function (self,value)
        local service = self:GetUPnPDeviceService ()
        service.methods.SetVolume:executeasync (1,'Master',value)
	end,


	--[[

	G5 DM Interface

	--]]


    -- creates a control for the device (if needed), returns false if this control is not valid for the supplied upnp device
    CreateControl = function (self)
        local VolumeControl = Controls.Volume:New({Name = self.DMControlID, Device = self.DMDevice})
        self.DMDevice:AddControl(VolumeControl)
    end,


    UpdateControl = function (self,value)
        value = tonumber (value)

        Super.UpdateControl (self,value)
    end,


} )


return interface
