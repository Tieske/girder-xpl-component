--[[


UPnP dimable light


have to kludge 2 services into one to fit DM level device

--]]

--]]


require 'DeviceManager.Devices.Lighting'

local dsid = 'urn:upnp-org:serviceId:Dimming.0001'

local psid = 'urn:upnp-org:serviceId:SwitchPower.0001'


local Super = require 'Components.UPnP (xPL).UPnP Devices.Base'

local class = Super:New ( {

    DMClass = DeviceManager.Devices.Classes.LightDimmer,


    -- called by the upnp interface when a device's value changes
    UPnPVariableUpdate = function (self,pservice,svar)
        if pservice.service == psid then -- power switch
            if svar.name == 'Status' then
                local value = svar.value
                if value then -- on 
                    local level = tonumber (self:GetUPnPDeviceServiceVariable (dsid,'LoadLevelStatus').value) or 100
                    self:GetDMDevice ():EventFromProvider (DeviceManager.Devices.Events.Condition,'Level',level)
                else -- off
                    self:GetDMDevice ():EventFromProvider (DeviceManager.Devices.Events.Condition,'Level',0)
                end
            end
        elseif pservice.service == dsid then -- dimming
            if svar.name == 'LoadLevelStatus' then
              --  print ('power service',self:GetUPnPDeviceServiceVariable (psid,'Status').value)
                local status = self:GetUPnPDeviceServiceVariable (psid,'Status').value
                if status then
                    local level = svar.value
                    self:GetDMDevice ():EventFromProvider (DeviceManager.Devices.Events.Condition,'Level',level)
                end
            end
        else
            Super.UPnPVariableUpdate (self,pservice,svar)
        end
    end,    
    
    
	-- action requested from the G5 DM
	ProcessDMAction = function (self,controlid,value)
        if controlid == 'Level' then
            local ls = self:GetUPnPDeviceService (dsid)
            local ps = self:GetUPnPDeviceService (psid)

            -- set load level            
            --print ('set level' , value)
            ls.methods.SetLoadLevelTarget:executeasync (nil,value)
            
            --set power state if needed
            local pvar = self:GetUPnPDeviceServiceVariable (psid,'Status')
            local pval = pvar.value or true
            --print ('pval',pval)
            if value == 0 and pval then -- level is 0, set power to off
                ps.methods.SetTarget:executeasync (nil,false)
            elseif value > 0 and pval then
                ps.methods.SetTarget:executeasync (nil,true)
            end
        end
    end,
        
    
} )


return class
