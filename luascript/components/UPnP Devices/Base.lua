--[[



Base Class for a UPnP device and Device Manager Device



--]]



local Base = {

	DMClass = false, -- class used to instatiate the G5DM device

	DMDevice = false, -- holds the device for G5DM
    
    UUID = false, -- id of the UPnP device
    
    UPnPDevice = false, -- reference to the upnp device
    
    UPnPInterface = false,
    
    Interfaces = false, -- table of interfaces between upnp services/variables and g5 dm controls


	-- to subclass
    New = function (self,subclass)
	    setmetatable (subclass,self)
	    self.__index = self
		subclass.__tostring = self.ToString
		return subclass
    end,


	-- for instances
    Create = function (self,UUID)
		-- create the object
        local o = {}

        o.UUID = assert (UUID)
        
	    setmetatable (o,self)
	    self.__index = self

        o.UPnPInterface = assert (ComponentManager:GetComponentUsingID (13200))
        
        o.UPnPDevice = o.UPnPInterface:GetUPnPDevice (o.UUID)
        
        o.Interfaces = {}
        
		return o:Initialize () and o or false
    end,


	-- must return true or false if error
	Initialize = function (self,settings)
		if self:GetDMClass () then
			local device = self:CreateDMDevice ()
            
            if device then
                self:BuildInterfaces ()
			    self:AddDMDeviceToLocalDM ()
            end
		end
        
		return true
	end,
    
    
    -- subclass implement
    BuildInterfaces = function (self)
    end,
    
    
    AddInterface = function (self,interface)
        --print ('add interface',interface)
        table.insert (self.Interfaces,interface)
    end,
    
    
    GetInterfaceForDMControlID = function (self,controlid)
        for _,interface in ipairs (self.Interfaces) do
            if interface:IsInterfaceForDMControl (controlid) then
                return interface
            end
        end
        
        return false
    end,
            

    GetInterfaceForUPnPServiceVariable = function (self,serviceid,variablename)
        for _,interface in ipairs (self.Interfaces) do
            if interface:IsInterfaceForUPnPServiceVariable (serviceid,variablename) then
                return interface
            end
        end
        
        --print ('no interface for',serviceid,variablename)
        
        return false
    end,
            


    --[[
    
    UPnP Side
    
    --]]
    

    GetUUID = function (self)
        return self.UUID
    end,
   
    
    GetUPnPDevice = function (self)
        return self.UPnPDevice    
    end,        
    
    
    GetUPnPDeviceService = function (self,serviceid)
        for _,service in pairs (self:GetUPnPDevice ().services) do
            if service.service == serviceid then
                return service
            end
        end
        
        return false
    end,
    

    GetUPnPDeviceServiceVariable = function (self,serviceid,variablename)
        local service = assert (self:GetUPnPDeviceService (serviceid))        
        return service.variables [variablename] or false
    end,
    
    
    -- called by the upnp interface when a device's value changes
    UPnPVariableUpdate = function (self,pservice,svar)
        --print ('Value update',self:GetUUID (), pservice.service,svar.name,svar.value)
        
        local interface = self:GetInterfaceForUPnPServiceVariable (pservice.service,svar.name)
        
        if interface then
            interface:UPnPVariableUpdate ()
        else
            --print ('no service')
        end
    end,
    
    
	--[[

	G5 DM Side

	--]]


	GetDMID = function (self)
		return self.UUID -- use uuid for for the g5 device id
	end,


	GetDMProvider = function (self)
		return {

			GetName = function (provider)
				return self.UPnPInterface:GetName ()
			end,


			GetPath = function (provider)
				return DeviceManager.Local:GetPath() .. '\\' .. self.UPnPInterface:GetName ()
 			end,


			GetType = function (provider)
				return self.UPnPInterface:GetName ()
			end,


			DeviceCommand = function (provider,Command,Device,...)
				--print ('device command',Command,Device,unpack (arg))

		        if Command == DeviceManager.Devices.Commands.Action then
					local control = arg [1]:GetID ()
					local value = arg [2]
					self:DMAction (control,value)
				elseif Command == DeviceManager.Devices.Commands.Property then
					self:DMProperty ()
				end
			end,

		}
	end,


	CreateDMDevice = function (self)
		local deviceproperties = {
			ID = self:GetDMID (),
			Location = self:GetDMProvider ():GetName (),
			Name = self.UPnPDevice.name,
			Provider = self:GetDMProvider (),
			Description = self:GetDMDeviceDescription ()
		}

		local device = assert (self:GetDMClass():New  (deviceproperties))

		self.DMDevice = device

		device:SetStatus (DeviceManager.Devices.Statuses.Ok)
        
		return device
	end,


	AddDMDeviceToLocalDM = function (self)
		DeviceManager.Local:AddDevice (self:GetDMDevice ())
	end,


	RemoveDMDevice = function (self)
		DeviceManager.Local:RemoveDevice (self.DMDevice)
		self.DMDevice = nil
	end,


	GetDMDevice = function (self)
		return self.DMDevice
	end,


	-- action requested from the G5 DM
	DMAction = function (self,controlid,value)
        local interface = self:GetInterfaceForDMControlID (controlid)
        
        if interface then
            interface:DMControlAction (value) -- ask the control to set the value
        else
            --print ('no interface for ',controlid,value)
        end
    end,
    
    
	-- property change from the G5 DM
	DMProperty = function (self)
	end,


	GetDMDeviceDescription = function (self)
		return self.UPnPDevice.type
	end,


	GetDMClass = function (self)
		return self.DMClass
	end,

    
	--[[

	Close

	--]]


	Close = function (self)
		if self.DMDevice then
			self:RemoveDMDevice ()
		end
	end,


}


return Base
