--[[

Dimmable


not in use
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

    UPnPServiceID = 'urn:upnp-org:serviceId:Dimming.0001',

    UPnPVariableName = 'LoadLevelStatus',

    DMControlID = 'Level',


    --[[

    UPnP

    --]]


    SetUPnPVariableValue = function (self,value)
        local service = self:GetUPnPDeviceService ()
        service.methods.SetLoadLevelTarget:execute (value)
	end,


	--[[

	G5 DM Interface

	--]]

    UpdateControl = function (self,value)
        value = tonumber (value)

        Super.UpdateControl (self,value)
    end,



} )


return interface
