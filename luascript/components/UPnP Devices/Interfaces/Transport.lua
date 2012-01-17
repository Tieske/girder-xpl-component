--[[


Transport


--]]

require 'DeviceManager.Controls.Range'
require 'DeviceManager.Controls.Toggles'
require 'DeviceManager.Controls.List'
require 'DeviceManager.Controls.Transport'
require 'DeviceManager.Controls.Image'
require 'DeviceManager.Controls.Time'


local Controls = DeviceManager.Controls.Classes

local p2g = {
    ['STOPPED'] = 'Stop',
    ['PAUSED_PLAYBACK'] = 'Pause',
    ['PAUSED_RECORDING'] = 'Pause',
    ['PLAYING'] = 'Play',
    ['RECORDING'] = 'Record',
    ['TRANSITIONING'] = false,
    ['NO_MEDIA_PRESENT'] = 'Stop',
}

local g2pm = {
    ['Stop'] = 'Stop', 
    ['Play'] = 'Play', 
    ['Pause'] = 'Pause', 
    ['Next'] = 'Next', 
    ['Previous'] = 'Previous',
} 


local tvs = {
    'Stop', 
    'Play', 
    'Pause', 
    'Next', 
    'Previous',
} 


local Super = require 'Components.UPnP (xPL).UPnP Devices.Interfaces.Base'

local interface = Super:New ( {

    UPnPServiceID = 'urn:upnp-org:serviceId:AVTransport',
    
    UPnPVariableName = 'TransportState',
    
    DMControlID = 'Transport',

    
    --[[
    
    UPnP
    
    --]]
    
    
    SetUPnPVariableValue = function (self,value)
        local service = self:GetUPnPDeviceService ()
        
        local methodname = g2pm [value]
        
        if methodname then
            local method = service.methods [methodname]
            -- special handle play.....
            if methodname == 'Play' then
                method:executeasync (0,1)
            else
                method:executeasync (0)
            end
        end
	end,
    

    UPnPVariableUpdate = function (self)
        local value = self:GetUPnPVariableValue ()
        local new = p2g [value]
        --print ('upnpvariableupdate',value,type (value),string.len (value), new)

        if new then
            self:UpdateControl (new)
        end
    end,
    
    
    
	--[[

	G5 DM Interface

	--]]


    -- creates a control for the device (if needed), returns false if this control is not valid for the supplied upnp device
    CreateControl = function (self)
        local Control = Controls.Transport:New({ID = self.DMControlID, Name = self.DMControlID, Device = self.DMDevice, Values = tvs,})
        
        self.DMDevice:AddControl(Control)
    end,
    
    
} )


return interface
