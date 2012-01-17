--[[

Control Interface Mapping Base Class

Use to map controls/services between G5 Devices and a UPnP Device


--]]




local Base = {

	DMDevice = false, -- holds the device for G5DM
    
    DMControlID = false, -- id of the control on the G5 device
    
    UPnPInterface = false, -- reference to the UPnP interface

    UPnPDevice = false, -- reference to the upnp device table
    
    UPnPServiceID = false, -- service for this control
    
    UPnPService = false, -- direct ref to the service
    
    UPnPVariableName = false, -- name of the variable
    

	-- to subclass
    New = function (self,subclass)
	    setmetatable (subclass,self)
	    self.__index = self
		subclass.__tostring = self.ToString
		return subclass
    end,


	-- for instances
    Create = function (self,settings)
		-- create the object
        local o = {}

	    setmetatable (o,self)
	    self.__index = self

        o.UPnPInterface = assert (ComponentManager:GetComponentUsingID (13200))
        
        o.UPnPDevice = assert (settings.UPnPDevice)
        o.DMDevice = assert (settings.DMDevice)
        
		return o:Initialize () and o or false
    end,


	-- must return true or false if interface not possible
	Initialize = function (self,settings)
        if not self:IsInterfacePossible () then
            return false
        end
        
        if not self.DMDevice:GetControl (self.DMControlID) then
            self:CreateControl () -- create the control on the g5 device
        end
        
        self:UpdateControl () -- sets the control value
        
        return true
	end,


    
    
    --[[
    
    UPnP Interface
    
    --]]
    
    
    GetUPnPDevice = function (self)
        return self.UPnPDevice    
    end,        
    
    
    GetUPnPDeviceService = function (self,serviceid)
        if not self.UPnPService then 
            for _,service in pairs (self:GetUPnPDevice ().services) do
                if service.service == self.UPnPServiceID then
                    self.UPnPService = service
                    break
                end
            end
        end
        
        return self.UPnPService or false
    end,

    
    GetUPnPDeviceServiceVariable = function (self)
        local service = self:GetUPnPDeviceService ()
        
        return service and service.variables [self.UPnPVariableName] or false
    end,
    
    
    GetUPnPVariableValue = function (self)
        local variable = assert (self:GetUPnPDeviceServiceVariable ())
        uv = variable
        return variable.value or false
    end,
    

    -- subclasses provide method to set remote upnp device     
    SetUPnPVariableValue = function (self,value)
        assert (false)
    end,
    
    
    UPnPVariableUpdate = function (self)
        --print ('upnpvariableupdate')
        local value = self:GetUPnPVariableValue ()
        self:UpdateControl (value)
    end,
    
    
    IsInterfaceForUPnPServiceVariable = function (self,serviceid,variablename)
        --print ('is inter serv',serviceid, self.UPnPServiceID , variablename , self.UPnPVariableName)
        return serviceid == self.UPnPServiceID and variablename == self.UPnPVariableName
    end,
    
    
	--[[

	G5 DM Interface

	--]]
    
    
    -- can we create an interface between this upnp device and the g5 device for this control type
    IsInterfacePossible = function (self)
        return self:GetUPnPDeviceServiceVariable ()
    end,

    
    IsInterfaceForDMControl = function (self,controlid)
        return controlid == self.DMControlID
    end,
    

    -- creates a control for the device (if needed), returns false if this control is not valid for the supplied upnp device
    CreateControl = function (self)
        assert (false)
    end,
    
    
    -- sets the control to current value as on the upnp device
    UpdateControl = function (self,value)
--        print ('update control',self.DMControlID,value)
        
        if value then
            self.DMDevice:EventFromProvider (DeviceManager.Devices.Events.Condition,self.DMControlID,value)
        else
            --print ('vairable has no value')
        end
    end,

    
    -- action requested from the G5 DM
	DMControlAction = function (self,value)
  --      print ('dm action',value)
        self:SetUPnPVariableValue (value)
	end,
    
    
	--[[

	Close

	--]]


	Close = function (self)
	end,


}


return Base
