--[[

Control Interface Mapping Base Class

Use to map controls/services between G5 Devices and a UPnP Device


--]]




local Base = {

    DMControlID = false, -- id of the control on the G5 device
    
    UPnPInterface = false, -- reference to the UPnP interface

    Parent = false, -- reference the parent that contains us
    
    UPnPServiceID = false, -- service for this control  
    
    UPnPService = false, -- direct ref to the service
    
    UPnPVariableName = false, -- name of the variable
    
    AsyncExecute = true, -- default to using the executeasync method
    
    RequestUPnPVariableAtStartup = false, 
    

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
        
        o.Parent = assert (settings.Parent)
        
		return o:Initialize () and o or false
    end,


	-- must return true or false if interface not possible
	Initialize = function (self,settings)
        if not self:IsInterfacePossible () then
            return false
        end
        
        if not self:GetDMDevice ():GetControl (self.DMControlID) then
            self:CreateControl () -- create the control on the g5 device
        end
        
        self:UpdateControl () -- sets the control value
        
        -- get variable if we do not have it
        if self.RequestUPnPVariableAtStartup and self:GetUPnPVariableValue () == nil then
            self:GetRemoteUPnPVariableValue ()
        end
        
        return true
	end,


    
    
    --[[
    
    UPnP Interface
    
    --]]
    
    
    UPnPDeviceLeft = function (self)
        self.UPnPService = false
    end,
    
    
    GetUPnPDevice = function (self)
        return self.Parent:GetUPnPDevice ()
    end,        
    
    
    GetUPnPDeviceService = function (self,serviceid)
        --if not self.UPnPService then 
            for _,service in pairs (self:GetUPnPDevice ().services) do
                if service.service == self.UPnPServiceID then
                    self.UPnPService = service
                    break
                end
            end
        --end
        
        return self.UPnPService or false
    end,

    
    GetUPnPDeviceServiceVariable = function (self)
        local service = self:GetUPnPDeviceService ()
        
        return service and service.variables [self.UPnPVariableName] or false
    end,
    
    
    GetUPnPVariableValue = function (self)
        local variable = assert (self:GetUPnPDeviceServiceVariable ())
        --uv = variable
        return variable.value
    end,        

    -- subclasses to provide, returns a table of paramets to send the the exexute function
    GetSetUPnPVariableValueParameters = function (self,value)
        assert (false)
    end,
    
    
    -- subclasses to provide, returns a table of paramets to send the the exexute function
    GetGetUPnPVariableValueParameters = function (self)
        assert (false)
    end,
    
    
    -- object used to get the value of the variable
    GetGetUPnPVariableValueObject = function (self)
        local service = self:GetUPnPDeviceService ()
        return service.methods ['Get'..self.UPnPVariableName]
    end,
    
    
    -- object used to set the value of the variable
    GetSetUPnPVariableValueObject = function (self,value)
        local service = self:GetUPnPDeviceService ()
        return service.methods ['Set'..self.UPnPVariableName]
    end,
    
    
    -- gets value from external upnp device
    GetRemoteUPnPVariableValue = function (self)
        local params = self:GetGetUPnPVariableValueParameters ()
        local method = self:GetGetUPnPVariableValueObject ()
        
        --print (self.UPnPVariableName,' get remote' , method, params)
        
        if self.AsyncExecute then
            self:ExecuteUPnPMethodAsync (method,params)
        else
            return self:ExecuteUPnPMethodSync (method,params)
        end
    end,
    
    
    -- sets the value on the upnp device
    SetUPnPVariableValue = function (self,value)
        local params = self:GetSetUPnPVariableValueParameters (value)
        local method = self:GetSetUPnPVariableValueObject (value)
        
        if self.AsyncExecute then
            self:ExecuteUPnPMethodAsync (method,params)
        else
            self:ExecuteUPnPMethodSync (method,params)
        end
    end,
    
    
    ExecuteUPnPMethodSync = function (self,method,params)
        return method:execute (unpack (params))
    end,
    
    
    ExecuteUPnPMethodAsync = function (self,method,params,callback)
--        callback = callback or function (...)
        local callback = function (...)
            print ('callback for ' ,method.name, table.tostring (params))
            self:UPnPExecuteCallback (unpack (arg))
        end
        --print ('async')
        return method:executeasync (callback,unpack (params))
    end,
    
    
    UPnPVariableUpdate = function (self,pservice,svar)
        --print ('upnpvariableupdate',pservice.service,svar.name)
        local value = self:GetUPnPVariableValue ()
        self:UpdateControl (value)
    end,
    
    
    IsInterfaceForUPnPServiceVariable = function (self,serviceid,variablename)
        --print ('is inter serv',serviceid, self.UPnPServiceID , variablename , self.UPnPVariableName)
        return serviceid == self.UPnPServiceID and variablename == self.UPnPVariableName
    end,
    
    
    -- generic callback handler for executeasync
    UPnPExecuteCallback = function (self,...)
        print (self.UPnPVariableName , ' upnp callback')
        table.print (arg)
    end,
    
    
	--[[

	G5 DM Interface

	--]]
    
    
    GetDMDevice = function (self)
        return self.Parent:GetDMDevice ()
    end,        
    
    
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
            self:GetDMDevice ():EventFromProvider (DeviceManager.Devices.Events.Condition,self.DMControlID,value)
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
