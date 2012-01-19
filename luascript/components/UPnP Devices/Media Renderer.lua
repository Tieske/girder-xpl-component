--[[


UPnP Media Renderer


--]]


-- build our own av device
require 'DeviceManager.Devices.AudioVisual'

local Devices = DeviceManager.Devices.Classes

local Base = Devices.Base

local AVRenderer = Base:New ( { 

    Type = 'AV\\Renderer',
    
    AddControls = function (self)
    end,

} )

DeviceManager:AddDeviceClass('AVRenderer', AVRenderer)




local vic = require 'Components.UPnP (xPL).UPnP Devices.Interfaces.Volume'
local mic = require 'Components.UPnP (xPL).UPnP Devices.Interfaces.Mute'
local tic = require 'Components.UPnP (xPL).UPnP Devices.Interfaces.Transport'

local Super = require 'Components.UPnP (xPL).UPnP Devices.Base'

local class = Super:New ( {

    DMClass = DeviceManager.Devices.Classes.AVRenderer,

    BuildInterfaces = function (self)
        local vi = vic:Create ( { 
            DMDevice = self:GetDMDevice (),
            UPnPDevice = self:GetUPnPDevice (),
        } )
        
        if vi then
            self:AddInterface (vi)
        end
        
        local mi = mic:Create ( { 
            DMDevice = self:GetDMDevice (),
            UPnPDevice = self:GetUPnPDevice (),
        } )
        
        if mi then
            self:AddInterface (mi)
        end
        
        local ti = tic:Create ( { 
            DMDevice = self:GetDMDevice (),
            UPnPDevice = self:GetUPnPDevice (),
        } )
        
        if ti then
            self:AddInterface (ti)
        end
        
    end,
    

} )


return class
