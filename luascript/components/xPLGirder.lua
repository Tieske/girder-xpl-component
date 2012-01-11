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
-- xPLGirder is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- xPLGirder is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License
-- along with xPLGirder.  If not, see <a href="http://www.gnu.org/licenses/">http://www.gnu.org/licenses/</a>.
-- <br/><br/>
-- See the accompanying ReadMe.txt file for additional information.
-- @class module
-- @name xPLGirder
-- @copyright 2011-2012 Richard A Fox Jr., Thijs Schreijer
-- @release Version 0.1.6, xPLGirder.

local Version = '0.1.6'
local PluginID = 10124
local PluginName = 'xPLGirder'
local Global = 'xPLGirder'
local Description = 'xPLGirder'
local ConfigFile = 'xPLGirder.cfg'
local ProviderName = 'xPLGirder'
local UDP_SOCKET = 50000
local XPL_PORT = 3865
local INTERVAL = 5
local handlerdir = 'luascript\\xPLHandlers'
local handlerfiles = '*.lua'


local function trim (s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- xPL parser. returns a table.
local function xPLParser(msg)
    local x = string.Split(msg, "\n")
    local xPLMsg = {}
    local Line
    local State=1

    xPLMsg.body = {}
    xPLMsg.type = x[1]

    for i in ipairs(x) do

        Line = trim(x[i])

        -- Reading the Body.
        if ( State == 5) then
            if ( Line=='}' ) then
                State = 0
            else
                local t = string.Split( Line, "=")
                if ( table.getn(t)==2 ) then
                    -- 2 elements found, so key and a value
                    table.insert(xPLMsg.body, { key = t[1], value = t[2] })
                elseif ( table.getn(t)==1 ) then
                    -- 1 element found, so key consider it key only
                    table.insert(xPLMsg.body, { key = t[1], value = "" })
                else
                    -- 3 or more elements found, so value contains '=' character
                    table.insert(xPLMsg.body, { key = t[1], value = string.sub(Line, string.len(t[1]) + 2) })
                end
            end
        end

        -- Waiting for Body
        if ( State == 4 ) then
            if ( Line=='{' ) then
                State = 5
            end
        end

        -- Waiting for Schema
        if ( State == 3 ) then

            --if ( Line ~= '' ) and ( Line~='\n') and ( Line~='\r\n' ) and ( Line~='\n\r' ) then
            if ( Line ~= '' ) and ( string.len(Line)>1) then
                xPLMsg.schema = Line
                State = 4
            end

        end

        -- Header.
        if ( State == 2) then
            if ( Line=='}' ) then
                State = 3
            else
                local t = string.Split( Line, "=")
                if ( table.getn(t)==2 ) then
                    xPLMsg[t[1]] = t[2]
                end
            end
        end

        -- Idle
        if ( State == 1 ) then
            if ( Line=='{' ) then
                State = 2
            end
        end
    end
    if not xPLMsg.type then
        return
    end

    if not xPLMsg.source then
        return
    end

    return xPLMsg
end

local GetRegKey = function(name, default)
    local key = "HKLM"
    local path = [[Software\xPL\]]
    local reg, err, val
    local result = default

    reg, err = win.CreateRegistry(key, path)
    if (reg ~= nil) then
        val = reg:Read(name)
        if (val ~= nil) then
            result = val
        end
        reg:CloseKey()
    end
    return result
end

local CleanupIP = function(ips)
    local t = string.Split(ips, ",")
    for k,v in ipairs(t) do
        local i = string.Split(v, ".")
        for k1,v1 in ipairs(i) do
            i[k1] = v1 * 1
        end
        t[k] = table.concat(i, ".")
    end
    return table.concat(t, ",")
end


local DefaultSettings = {
}

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
} )

local socket = require('socket')

local Address, HostName = win.GetIPInfo(0)

local xPLListenOnAddress = GetRegKey("ListenOnAddress", "ANY_LOCAL")
if xPLListenOnAddress ~= "ANY_LOCAL" then
    xPLListenOnAddress = CleanupIP(xPLListenOnAddress)
end

local xPLListenToAddresses = GetRegKey("ListenToAddresses", "ANY_LOCAL")
if xPLListenToAddresses ~= "ANY_LOCAL" then
    if xPLListenToAddresses ~= "ANY" then
        xPLListenToAddresses = CleanupIP(xPLListenOnAddress)
        -- remove '.' characters because they are magical lua patterns
        xPLListenToAddresses = string.gsub(xPLListenToAddresses, "%.", "_")
    end
end

local xPLBroadcastAddress = GetRegKey("BroadcastAddress", "255.255.255.255")

if xPLListenOnAddress ~= "ANY_LOCAL" then
    Address = xPLListenOnAddress
end

require 'date'
require 'Components.Classes.Provider'
require 'Classes.DelayedExecutionDispatcher'

local Super = require 'Components.Classes.Provider'
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
    ConfigFile = ConfigFile,
    ProviderName = ProviderName,
    Source = 'tieske-girder.'..string.gsub (string.lower(HostName), "%p", ""),
    Address = Address,
    HostName = HostName,
    xPLListenOnAddress = xPLListenOnAddress,
    xPLListenToAddresses = xPLListenToAddresses,
    xPLBroadcastAddress = xPLBroadcastAddress,
    Port = UDP_SOCKET,

    xPLDevices = {},
    hbeatCount = 0,    -- counts own heartbeats send until one is received

    Initialize = function (self)
        self:AddEvents (Events)
        self:AddDoNotLogEvent(Events.xPLMessage)  -- do not log xPL messages, there are too many of them

        self:AddToDefaultSettings (DefaultSettings)

        return Super.Initialize (self)
    end,


    StartProvider = function (self)
        --Super.StartProvider (self)
    end,


    Enable = function (self)
        self:SetMode ('Startup')

        self:LoadHandlers()

        self:StartReceiver()

        self:StartHBTimer()

        self:SendHeartbeat()

        return Super.Enable (self)
    end,


    Disable = function (self)
        self:SetMode ('Offline')

        self:ShutdownReciever()

        self:AllDevicesLeaving()

        self:RemoveAllHandlers()

        return Super.Disable (self)
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
                    gir.TriggerEvent(eventstring, self.ID, pld1)
                end
            end
        end
    end,

    Handlers = {},         -- emtpy table with specific message handlers

    FilterMatch = function (self, msg, filter)
        -- filter = [msgtype].[vendor].[device].[instance].[class].[type]
        -- wildcards can be used; '*'
        -- return true if the message matches the filter

        local addr = string.gsub(msg.source, "%-", ".", 1)    -- replace address '-' with '.'
        local mflt = string.format("%s.%s.%s", msg.type, addr, msg.schema)

        -- split filter elements
        local flst = string.Split( filter, '.' )
        local mlst = string.Split( mflt, '.' )

        for i = 1,6 do
            -- check wildcard first
            if flst[i] ~= '*' then
                -- isn't a wildcard, check equality
                if flst[i] ~= mlst[i] then
                    -- not equal, so match failed
                    return false
                end
            end
        end
        -- we've got a match
        return true
    end,

    ProcessMessageHandlers = function (self, msg)
        local result = false
        local s, r
        -- loop through all handlers
        for ID, handler in pairs(self.Handlers) do
            -- loop through all filters
            for k, v in pairs(handler.Filters) do
                if self:FilterMatch ( msg, v ) then
                    -- filter matches, go call handler, protected, s = success true/false, r = result
                    s,r = pcall(handler.MessageHandler, handler, msg, v)
                    if s then
                        if r then
                            result = true
                        end
                    else
                        -- error was returned from handler
                        print("xPLHandler " .. handler.ID .. " had a lua error;" .. r)
                        print("while handling the following xPL message;")
                        table.print(msg)
                        gir.LogMessage(self.Name, handler.ID .. ' failed while processing a message, see lua console', 2)
                    end
                    -- call each handler max 1, so exit 'filter' loop, continue with next handler
                    break
                end
            end
        end
        return result
    end,

    RegisterHandler = function (self, handler)
        self:RemoveHandler(handler.ID)
        -- setup defaults and ID
        local newID = handler.ID
        handler.Filters = handler.Filters or {}
        if table.IsEmpty( handler.Filters ) then
            handler.Filters = {'*.*.*.*.*.*'}    -- default filter; all messages
        end
        -- Go add to Handler list and initialize
        self.Handlers[newID] = handler
        handler:Initialize()
        self:Event(Events.xPLHandlerInitialized, handler)
    end,

    RemoveHandler = function (self, ID)
        if ID ~= nil then
            local h = self.Handlers[ID]
            if h ~= nil then
                h:ShutDown()
                self:Event(Events.xPLHandlerShutDown, h)
                self.Handlers[ID] = nil
            end
        end
    end,

    RemoveAllHandlers = function (self)
        -- shutdown all handlers, and empty table
        for ID, handler in pairs(self.Handlers) do
            self:RemoveHandler(ID)
        end
    end,

    LoadHandlers = function (self)
        --self:Log (3,'Loading xPL handlers')
        local dir = win.GetDirectory('GIRDERDIR').."\\"..handlerdir

        for fa in win.Files (dir..'\\'..handlerfiles) do
            if math.band (fa.FileAttributes, win.FILE_ATTRIBUTE_DIRECTORY) == 0 then
                local handler = self:ReadHandlerFile (dir..'\\'..fa.FileName)
                if handler then
                    self:RegisterHandler (handler)
                end
            end
        end
    end,

    ReadHandlerFile = function (self, file)
        --self:Log (3,'Reading handler ',file)

        local f,err = loadfile (file)
        if not f then
            gir.LogMessage(self.Name, 'Error reading handler file ' .. file, 2)
            return false
        end

        local res,handler = xpcall (f, debug.traceback)

        if not res or type (handler) ~= 'table' then
            gir.LogMessage(self.Name, 'Error running handler file ' .. file, 2)
            return false
        end

        if not res then
            gir.LogMessage(self.Name, 'Error running handler file ' .. file, 2)
            return false
        end

        self:Event(Events.xPLHandlerLoaded, handler)
        gir.LogMessage(self.Name, 'Loaded handler ' .. handler.ID, 3)
        return handler
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
        gir.TriggerEvent('Status changed to: ' .. self.Mode, self.ID, self.Mode)
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
            local result, error = self.Receiver:sendto(msg,self.xPLBroadcastAddress, XPL_PORT)
            if not result then
                print ("Error sending xPL message: " .. tostring(error))
            end
        elseif type(msg) == "table" then
----------------------------
-- to be implemented here --
----------------------------
            table.print (msg)
            error ("sending objects is not implemented yet!")
        end
    end,


    Close = function (self)
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

