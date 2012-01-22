------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <a href="http://xplproject.org.uk">xPL is an open source home automation protocol</a> that uses simple
-- text based messages to communicate and provides automatic discovery of devices on the network.
-- <br/><br/>
-- After the component has been enabled within Girder and 
-- <a href="http://www.thijsschreijer.nl/blog/?page_id=150">the xPL infrastructure has been setup</a>,
-- Girder will automatically connect to the xPL network. xPL uses 
-- <a href="http://xplproject.org.uk/wiki/index.php?title=XPL_Message_Schema">message schemas</a> to 
-- identify and specify message contents. For several message schemas handler files have been provided 
-- and also a template is available to create your own (this requires lua coding).
-- If the installed handlers do not prevent it (see below), a Girder event will be created for received 
-- messages.
-- The event source will be xPLGirder, the event string will have the format of an xPL filter and the 
-- event payloads will be;
-- <ol><li>the xPL message 'pickled'</li>
-- <li>nil</li>
-- <li>nil</li>
-- <li>nil</li></ol>
-- <br/>To access the message, just unpickle the payload value; <code>local msg = unpickle(pld1)</code>.
-- Additional events will be created for xPL devices arriving, leaving and the xPL connection status.
-- <br/><br/>The generated events depend upon the message handlers. Whenever a message is received it will
-- be handed to every handler in turn. Each handler will only be called if the message matches the filter list
-- of that handler. If a handler handles a message, if may raise a specific event for that message. The return
-- values of the handlers determine if there will be a generic event. If at least one handler returns <code>true</code>
-- after handling the message then the generic xPLGirder event for received messages will be suppressed. Only
-- if none of the handlers returns <code>true</code> the generic event will be raised.
-- <br/><br/>xPLGirder installs in a global table <code>xPLGirder</code>, but that global is only available after 
-- the component has been started. Several functions can be used through this global table.
-- <br/><br/>
-- @class module
-- @name xPLGirder
-- @copyright 2011-2012 Richard A Fox Jr., Thijs Schreijer
-- @release Version 0.1.6, xPLGirder.
-- <br/><br/>

local License = [[
xPLGirder is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
xPLGirder is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with xPLGirder.  If not, see <a href="http://www.gnu.org/licenses/">http://www.gnu.org/licenses/</a>.
See the accompanying ReadMe.txt file for additional information.
]]


local Version = '0.1.6'
local PluginID = 13100
local PluginName = 'xPL'
local Global = 'xPL'
local Description = 'xPL Interface'
local ConfigFile = 'xPL.cfg'
local UDP_SOCKET = 50000
local XPL_PORT = 3865
local INTERVAL = 5

local xPLParser = require ('Components.xPL.Support.xPLParser')

local GetRegKey = require ('Components.xPL.Support.GetRegKey')

local CleanupIP = require ('Components.xPL.Support.CleanupIP')

local socket = require('socket')

require 'date'

local ded = require 'Classes.DelayedExecutionDispatcher'


local Events    -- declare first to trick LuaDoc
--------------------------------------------------------------------------------
-- Events generated from the xPLGirder component (in addition to standard
-- component events)
-- @class table
-- @name Events
-- @field xPLMessage Whenever an xPL message is received this event is raised. Has a single
-- parameter, the xPL message table.
-- @field xPLHandlerLoaded Raised after a handler has been loaded, but before it has been initialized.
-- Has a single parameter, the handler table.
-- @field xPLHandlerInitialized Raised after a handler has been initialized.
-- Has a single parameter, the handler table.
-- @field xPLHandlerShutDown Raised after a handler has been shut down.
-- Has a single parameter, the handler table.
-- @field xPLDeviceArrived Raised when a heartbeat is received from a currently unknown xPL device.
-- Has a single parameter, the xPL address of the device.
-- @field xPLDeviceLeft Raised after an xPL device left the network. Either by sending an 'end' message
-- or when the next expected heartbeat times out. Has a single parameter, the xPL address of the device.
-- @field Status The existing <code>Status</code> event has been extended with the following values;
-- <ul><li><code>Startup</code> xPLGirder is trying to connect to the xPL network</li>
-- <li><code>Online</code> xPLGirder has established a connection to the xPL network</li>
-- <li><code>Offline</code> xPLGirder went offline</li></ul>
Events = table.makeset ( {
    'xPLMessage',
    'xPLHandlerLoaded',
    'xPLHandlerInitialized',
    'xPLHandlerShutDown',
    'xPLDeviceArrived',
    'xPLDeviceLeft',
    'DUI', -- update dui page
} )


local DefaultSettings = {
    LogDirectory = 'xPL',

    LogSettings = {  -- note we move logging of device and direct component stuff that is insteon related outside of the comprehensive CM logging file
        FileLogLevel = 0,
        ConsoleLogLevel = 4,
        DaysToKeep = 5,
        RemoteLogLevel = 0,
        FileName = 'xPL',
        ConsoleName = 'xPL',
    },


}

local ComponentSubDirectory = 'xPL'


local Handlers = {
   {
        fn = 'UPnP',
        id = 13101,
        enable = true
    },
}

-- disable order
local HandlersDisableOrder = {
    13101, -- UPnP
}






local Super = require 'Components.Classes.Base'
-----------------------------------------------------------
-- properties of global xPLGirder table. These are accessible through the global <code>xPLGirder</code>.
-- @name properties
-- @class table
-- @field Address the xPL address in use by Girder (automatically generated based upon the current systems hostname)
-- @field Port the current UDP port in use (listening on for incoming xPL messages)
-- @field ID Girder plugin ID for xPLGirder
-- @field Name Girder component name for xPL Girder
-- @field Description Girder component description for xPLGirder
-- @field Version Component version number
-- @field Devices table with xPL devices found on the xPL network
local xPLGirder = Super:New ( {

    ID = PluginID,
    Name = PluginName,
    Description = Description,
    Global = Global,
    Version = Version,
    License = License,
    ConfigFile = ConfigFile,
    
    Source = false,
    Address = false,
    HostName = false,
    xPLListenOnAddress = false,
    xPLListenToAddresses = false,
    xPLBroadcastAddress = false,
    Port = UDP_SOCKET,
    
    DefaultSettings = DefaultSettings,
    Requires = Requires,
    License = License,
    
    Handlers = Handlers, -- xPL message handler sub components
    EnabledHandlers = {}, -- list of all enabled handlers, indexed by filename
    
    xPLDevices = {},
    hbeatCount = 0,    -- counts own heartbeats send until one is received
    
    ReceivedBytes = 0,
    SentBytes = 0,
    
    Mode = false, -- connection status to hub
    
    Requires = {
    
        {
            Type = 'Version',
            Identifier = 'Pro',
        },
        
    },
    

    Initialize = function (self)
        self:AddEvents (Events)
        self:AddDoNotLogEvent(Events.xPLMessage)  -- do not log xPL messages, there are too many of them

        self:AddToDefaultSettings (DefaultSettings)

        return Super.Initialize (self)
    end,
    
    
    Loaded = function (self)
        self.DUICopied = false

        self.ComponentSubDirectory = ComponentManager:GetComponentDirectory () .. '\\' .. ComponentSubDirectory

        -- copy ui xml file
        local spath = self.ComponentSubDirectory..'\\DUI\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\ui\\'

        local res =win.SHFileOperation (spath..'xpl.xml',dpath,win.FO_COPY,win.FOF_FILESONLY)
        if not res then
            self:Log (5,'error copying xml file')
            return false
        end

        self.DUIImageDir = spath -- store dui files know where to find images

        -- copy treescript stub file
        local spath = self.ComponentSubDirectory..'\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\treescript\\'

        local res =win.SHFileOperation (spath..'xpl ui.lua',dpath,win.FO_COPY,win.FOF_FILESONLY)
        if not res then
            self:Log (5,'error copying treescript ui files')
            return false
        end

        self.DUICopied = true

        return Super.Loaded (self)
    end,


    -- called by stub file in the treescript dir
    LoadUIFiles = function (self)
        local path = self.ComponentSubDirectory..'\\DUI\\'

        for fa in win.Files (path..'*.lua') do
          if math.band (fa.FileAttributes, win.FILE_ATTRIBUTE_DIRECTORY) == 0 then
            self:Log (2,'Loading UI file ',fa.FileName)
            local succ,f,err = Protect (loadfile,path..fa.FileName)
            if succ and f then
                Protect (f)
            else
                self:Log (5,'Error loading UI file ',fa.FileName)
                self:Log (5,err)
            end
          end
        end
    end,


    Enable = function (self)
        local b = Super.Enable (self)
    
        local loggerc = assert (ComponentManager:GetComponentUsingName ('Logging'))
        local logdir = loggerc:GetSettings ().Directory
        if not win.PathExists (logdir) then
            local res,err = win.CreateDirectory (logdir..'\\'..self.Settings.LogDirectory)
            self:Log (4,'Unable to create log directory: error number',err)
        else
            self:CreateLogger ()
        end

        self:LogLocal (0,'Starting')

        self:SetMode ('Startup')
        
        for _,c in ipairs (Handlers) do
            if not ComponentManager:GetComponentUsingID (c.id) then
                local component = assert (self:LoadHandler (c.fn),c.fn)
                self:LogLocal (3,'Loaded Handler ',c.fn)
                ComponentManager:InitializeComponent (component)
                self:LogLocal (3,'Initialized Handler ',c.fn)
            end
        end

        for _,c in ipairs (Handlers) do
            if c.enable then
                local component = ComponentManager:GetComponentUsingID (c.id)
                ComponentManager:EnableComponent (component)
                self.EnabledHandlers [c.fn] = component
                self:LogLocal (3,'Enabled Handler ',c.fn)
            end
        end

        self:SetupNetworking ()    
		
		--self.Source = 'girder.'..string.gsub (string.lower(self.HostName), "%p", ""),
        self.Source = 'tieske-girder.'..string.gsub (string.lower(self.HostName), "%p", ""),

        self:StartReceiver()

        self:StartHBTimer()

        self:SendHeartbeat()

        return b
    end,


    Disable = function (self)
        self:SetMode ('Offline')

        self:DisableHandlers ()
        
        self:ShutdownReciever()

        self:AllDevicesLeaving()

        return Super.Disable (self)
    end,
    
    
    LoadHandler = function (self,filename)
        local component = ComponentManager:ReadComponentFile (self.ComponentSubDirectory..'\\Handlers\\'..filename..'.lua')
        if not component then
            self:LogLocal (5,'Unable to read Handler',filename)
            return false
        end

        if not ComponentManager:LoadComponent (component) then
            self:LogLocal (5,'Unable to load handler',filenmae)
        end

        return component
    end,


    DisableHandlers = function (self)
        for _,id in ipairs (HandlersDisableOrder) do
            local component = ComponentManager:GetComponentUsingID (id)
            if component and component:IsEnabled () then
                ComponentManager:DisableComponent (component)
                self:LogLocal (1,'Disabled Handler: ',component:GetName ())
            end
        end
    end,
    
    
    SetupNetworking = function (self)
        local Address, HostName = win.GetIPInfo(0)
        self.Address = Address
        self.HostName = HostName

        self.xPLListenOnAddress = GetRegKey("ListenOnAddress", "ANY_LOCAL")
        if self.xPLListenOnAddress ~= "ANY_LOCAL" then
            self.xPLListenOnAddress = CleanupIP(self.xPLListenOnAddress)
            Address = xPLListenOnAddress
        end

        self.xPLListenToAddresses = GetRegKey("ListenToAddresses", "ANY_LOCAL")
        if self.xPLListenToAddresses ~= "ANY_LOCAL" then
            if self.xPLListenToAddresses ~= "ANY" then
                self.xPLListenToAddresses = CleanupIP(self.xPLListenOnAddress)
                -- remove '.' characters because they are magical lua patterns
                self.xPLListenToAddresses = string.gsub(xPLListenToAddresses, "%.", "_")
            end
        end

        self.xPLBroadcastAddress = GetRegKey("BroadcastAddress", "255.255.255.255")

    end,


    StartHBTimer = function (self)
        self.HeartbeatTimer = gir.CreateTimer (nil,function () self:SendHeartbeat () end,nil,true)
        self.HeartbeatTimer:Arm (3000)
        return true
    end,

    -------------------------------------------------------------------
    -- Sends a heartbeat on to the network.
    -- This will be done automatically and should normally not be called.
    -- @name xPLGirder.SendHeartbeat
    -- @usage xPLGirder:SendHeartbeat()
    SendHeartbeat = function (self)
        if self.hbeatCount ~= 0 then
            -- a previous hbeat send was not received back... unstable connection!
            gir.LogMessage(self.Name, 'No connection to xPL hub. Retrying...', 1)
            if self.Mode == 'Online' then
                self:SetMode ('Startup')
                if self.HeartbeatTimer ~= nil then
                    self.HeartbeatTimer:Cancel()
                    self.HeartbeatTimer:Arm (3000)
                end
            end
        end
        self.hbeatCount = self.hbeatCount + 1
        local hb = "xpl-stat\n{\nhop=1\nsource=%s\ntarget=*\n}\nhbeat.app\n{\ninterval=%s\nport=%s\nremote-ip=%s\nversion=%s\n}\n"
        local msg = string.format(hb, self.Source, INTERVAL, self.Port, self.Address, self.Version)
        self:SendMessage(msg)
        self:CheckDevicesExpiring()
    end,


    -------------------------------------------------------------------
    -- Sends a heartbeat request for all other devices on the network to
    -- announce themselves by sending a heartbeat on to the network.
    -- This will be done automatically at startup.
    -- @name xPLGirder.SendDiscovery
    -- @usage xPLGirder:SendDiscovery()
    SendDiscovery = function (self)
        local hb = "xpl-cmnd\n{\nhop=1\nsource=%s\ntarget=*\n}\nhbeat.request\n{\ncommand=request\n}\n"
        local msg = string.format(hb, self.Source)
        self:SendMessage(msg)
    end,


    ShutdownReciever = function (self)
        local hb = "xpl-stat\n{\nhop=1\nsource=%s\ntarget=*\n}\nhbeat.end\n{\ninterval=%s\nport=%s\nremote-ip=%s\n}\n"
        local msg = string.format(hb, self.Source, INTERVAL, self.Port, self.Address)
        self:SendMessage(msg)
        if self.HeartbeatTimer ~= nil then
            self.HeartbeatTimer:Cancel()
            self.HeartbeatTimer = nil
        end
        self.Receiver:close()
    end,


    StartReceiver = function (self)
        self.Receiver = socket.udp()
        if not self.Receiver then
            gir.LogMessage(self.Name, 'Could not create UDP socket.', 2)
            return false
        end
        self.Receiver:settimeout(1)
        local status, err = self.Receiver:setsockname('*', self.Port)

        while not status do
            self.Port = self.Port + 1
            self.Receiver:close()
            self.Receiver = socket.udp()
            self.Receiver:settimeout(1)
            self.Receiver:setoption("broadcast", true)
            status, err = self.Receiver:setsockname('*', self.Port)
            --print (status,err)
        end

        local updaterunning = self.AsyncReceiverID and self.AsyncReceiverID:isthreadrunning ()
        if updaterunning or gir.IsLuaExiting () then  -- leave if we are already running or lua is shutting down
            return
        end
        self.AsyncReceiverID = thread.newthread (self.AsyncReceiver,{self,1,2})
    end,


    AsyncReceiver = function (self)
        while not gir.IsLuaExiting() do
            local data, err = self.Receiver:receivefrom()

            if not data and err ~= 'timeout' then
                -- if any error occurs end the thread, unless the error is 'timeout'
                return false
            end

            if data then
                self.ReceivedBytes = self.ReceivedBytes + string.len (data)
                self:Event (self.Events.DUI)
                
                local fromip = string.gsub(err, "%.", "_") -- if data was returned, 2nd argument contains the Sender IP
                if self.xPLListenToAddresses ~= "ANY" then
                    -- we need to check the from address
                    if self.xPLListenToAddresses == "ANY_LOCAL" then
                        -- the first three elements in our address must match
                        local a = string.Split(self.Address, ".")
                        a[4] = 255
                        a = table.concat(a, "_")
                        fromip = string.Split(fromip, "_")
                        fromip[4] = 255
                        fromip = table.concat(fromip, "_")
                        if a ~= fromip then
                            data = nil
                            print ("Message from " .. err .. " not approved.")
                        end
                    else
                        -- check if sender address is in our list, clear data if not
                        if not string.find(self.xPLListenToAddresses, fromip) then
                            data = nil
                            print ("Message from " .. err .. " not approved.")
                        end
                    end
                end
                local msg = nil
                if data then msg = xPLParser(data) end
                if msg then
                    --if not self:ProcessHeartbeat(msg) then
                        self:ProcessReceivedMessage (msg)
                    --end
                end
            end
        end
    end,


    ProcessReceivedMessage = function (self, data)
        if not self:ProcessHeartbeat(data) then
            local forus = data.target == '*' or data.target == self.Source
            if forus then
                self:Event(Events.xPLMessage, table.copy(data))
                if not self:ProcessMessageHandlers ( data ) then
                    -- returned false, so standard xPL event should not be supressed
                    local dotAddr = string.gsub(data.source, "%-", ".", 1)  -- replace address '-'  by '.'
                    local eventstring = string.format("%s.%s.%s", data.type, dotAddr, data.schema)
                    local pld1 = pickle(data)
                    if string.len(pld1) > 2900 then
                        pld1 = "message too large for a payload"
                    end
                    if not string.find (eventstring,'fragment') then
                        gir.TriggerEvent(eventstring, self.ID, pld1)
                    end
                end
            end
        end
    end,

    
    ProcessMessageHandlers = function (self, msg)
        --print ('xpl process msg',msg)
        local result = false
        local s, r
        
        -- loop through all handlers
        for _, handler in pairs(self.EnabledHandlers) do
            result = handler:ProcessMessage (msg)
        end
            
        return result
    end,


    ProcessHeartbeat = function (self, data)
        if data.type == 'xpl-stat' and (data.schema == "hbeat.app" or data.schema == "config.app" or data.schema == "hbeat.basic" or data.schema == "config.basic") then
            local source = data.source
            if self.Mode == 'Startup' then
                if source == self.Source then
                    self.hbeatCount = 0        -- reset counter
                    self:SetMode ('Online')
                    self.HeartbeatTimer:Cancel()
                    self.HeartbeatTimer:Arm (INTERVAL * 60000)
                    self:SendDiscovery()
                end
            end
            if self.Mode == 'Online' then
                if source == self.Source then
                    -- its my own heartbeat
                    self.hbeatCount = 0        -- reset counter
                else
                    -- someone elses heartbeat
                    local expire
                    for _, kvp in ipairs(data.body) do
                        if kvp.key == "interval" then
                            -- found the interval key, now calculate expire time
                            expire = date:now()
                            expire.Minute = expire.Minute + 1 + 2 * (tonumber(kvp.value) or 5)
                            break
                        end
                    end
                    if not self.xPLDevices[source] then
                        -- not in the list, so a new device has arrived
                        self.xPLDevices[source] = { address = source, expire = expire }
                        -- now announce the new device
                        self:Event(Events.xPLDeviceArrived, source)
                        gir.TriggerEvent('xPL device arrived ' .. source, self.ID, source)
                    else
                        -- existing device, set new expire time
                        self.xPLDevices[source].expire = expire
                    end
                    
                end
            end
            return true     -- msg was a heartbeat
        elseif data.type == 'xpl-stat' and (data.schema == "config.end" or data.schema == "hbeat.end") then
            self:DeviceLeaving(data.source)
            return true     -- msg was a heartbeat
        elseif data.type == 'xpl-cmnd' and data.schema == "hbeat.request" then
            self:SendHeartbeat()
            return true     -- msg was a heartbeat
        end
        return false        -- msg was not a heartbeat
    end,

    
    DeviceLeaving = function (self, dev)
        -- Device left
        if self.xPLDevices[dev] then
            -- a known device is leaving
            self.xPLDevices[dev] = nil
            self:Event(Events.xPLDeviceLeft, dev)
            gir.TriggerEvent('xPL device left ' .. dev, self.ID, dev)
        end
    end,

    
    AllDevicesLeaving = function (self)
        for dev, _ in pairs(self.xPLDevices) do
            self:DeviceLeaving(dev)
        end
    end,
    

    CheckDevicesExpiring = function (self)
        local n = date:now()
        for _, dev in pairs(self.xPLDevices) do
            if n > dev.expire then
                -- device expired !
                self:DeviceLeaving(dev.address)
            end
        end
    end,

    
    SetMode = function (self, m)
        self.Mode = m
        self:SetStatus(m)
        
        self:Event (self.Events.DUI)
        
        gir.TriggerEvent('Status changed to: ' .. self.Mode, self.ID, self.Mode)
    end,
    

    GetMode = function (self, m)
        return self.Mode 
    end,
    
    
    GetSourceDevices = function (self)
        return table.copy(self.xPLDevices)
    end,


    GetSource = function (self)
        return self.Source
    end,


    -------------------------------------------------------------------
    -- Sends an xPL message on the network.
    -- The string value provided must be a valid xPL message, but it will
    -- not be checked for correctness!
    -- @name xPLGirder.SendMessage
    -- @param msg a string containing the xPL message to send
    -- @usage# -- create a heartbeat request message
    -- local msg = "xpl-cmnd\n{\nhop=1\nsource=tieske-device.girderid\ntarget=*\n}\nhbeat.request\n{\ncommand=request\n}\n"
    -- -- now send it
    -- xPLGirder:SendMessage(msg)
    SendMessage = function (self, msg)
        if not msg then
            error ("Must provide a message string, call as; SendMessage( self, MsgString )", 2)
        end
        if type(msg) == "string" then
            --print ('xpl sending',msg)
            local result, error = self.Receiver:sendto(msg,self.xPLBroadcastAddress, XPL_PORT)
            if not result then
                print ("Error sending xPL message: " .. tostring(error))
            else
                self.SentBytes = self.SentBytes + string.len (msg)
                self:Event (self.Events.DUI)
            end
        elseif type(msg) == "table" then
----------------------------
-- to be implemented here --
----------------------------
            table.print (msg)
            error ("sending objects is not implemented yet!")
        end
    end,


    Log = function (self,level,...)
		if self.Logger then
			self.Logger:Log (level,unpack (arg))
		else
			Super.Log (self,level,unpack (arg))
		end
    end,


    CreateLogger = function (self)
        self.Logger = Classes.Logger:New ( {
            ConsoleName = self.Name,
            Filename = self.Name,
            FileLogLevel = 1,
            ConsoleLogLevel = 4,
            DaysToKeep = 5,
        } )
    end,


    LogLocal = function (self,level,...)
        if self.Logger then
            self.Logger:Log (level,unpack (arg))
        else
            self:Log (level,unpack (arg))
        end
    end,


	-- tell the component manager to not log any of our events
	DoNotLogEvent = function (self,Event,...)
		return true
	end,


    Close = function (self)
        self:DisableHandlers ()
        self:ShutdownReciever()
        _ = self.HeartbeatTimer and self.HeartbeatTimer:Destroy ()

        Super.Close (self)
    end,

} )

local msg -- trick luadoc
----------------------------------------------------------------------
-- xPL message table. Each received message is represented in a table
-- with this structure.
-- @name message
-- @class table
-- @field type the message type, either one of <code>'xpl-cmnd', 'xpl-trig',</code> or <code>'xpl-stat'</code>.
-- @field hop message hop-count
-- @field source source address
-- @field target target address
-- @field schema message schema
-- @field body a list/array with all the key-value pairs in the message body. Every item in this list
-- is a table with 2 key-value pairs; <code>key</code> and <code>value</code> which each contain the key and value
-- of the key-value pair in that position. So to access the first key use; <code>msg.body[1].key</code> and to access
-- the accompanying value use <code>msg.body[1].value</code>.
msg = {}
msg = nil

return xPLGirder

