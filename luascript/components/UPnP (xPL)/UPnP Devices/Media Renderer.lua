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

	Initialize = function (self,settings)
        local b = Super.Initialize (self,settings)
        
        local ts = self:GetUPnPDeviceService ('urn:upnp-org:serviceId:AVTransport')
        if ts then
            local method = ts.methods.GetTransportInfo
            if method then
                local callback = function (success,...)
                    if success then
                        local svar = self:GetUPnPDeviceServiceVariable ('urn:upnp-org:serviceId:AVTransport','TransportState')
                        svar.value = arg [1]
                        
                        local interface = self:GetInterfaceForUPnPServiceVariable ('urn:upnp-org:serviceId:AVTransport','TransportState')
                        interface:UPnPVariableUpdate (ts,svar)
                    end
                end
                
                method:executeasync (callback,0)
            end
        end
        
        return b 
    end,
    
    
    BuildInterfaces = function (self)
        local vi = vic:Create ( { 
            Parent = self,
        } )
        
        if vi then
            self:AddInterface (vi)
        end
        
        local mi = mic:Create ( { 
            Parent = self,
        } )
        
        if mi then
            self:AddInterface (mi)
        end
        
        local ti = tic:Create ( { 
            Parent = self,
        } )
        
        if ti then
            self:AddInterface (ti)
        end
        
    end,
    

} )


return class
