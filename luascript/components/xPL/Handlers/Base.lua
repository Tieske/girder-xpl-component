--[[


This file is an xPL message handler base class to be used with the xPLGirder plugin.
It allows for the easy handling of specific xPL message types.

Use the items below to create the handler, instructions are in the comments.

The file should be located inside the Girder program directory, in directory
'luascript\xPLHandlers\' and must be renamed to a file extension '.lua', it
will be loaded when the xPLGirder component initializes.



------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <br/><br/>
-- This file is a <strong>template</strong> xPL message handler. It can be used to quickly
-- create new/custom message handlers. The file has extensive code comments with instructions
-- on how to adapt it to a working handler.</br>
-- Messages received by xPLGirder will be passed to all registered message handlers which
-- have a filter defined that matches the message contents (see code comments for more details).
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
-- @copyright 2011-2012 Richard A Fox Jr., Thijs Schreijer
-- @release Version 0.1.6, xPLGirder.



}


-- finally deliver the handler to the xPLGirder component
return myNewHandler


--]]


require 'thread'

require 'Protected'

require 'Classes.Publisher'

local Date = require 'Classes.Date'

require 'Classes.WaitForCondition'

local ded = require 'Classes.DelayedExecutionDispatcher'


local DefaultSettings = {
    ControllerProperties = {}, -- indexed by controller name, each entries contains the properties needed to instantiate a controller

    LogSettings = {  -- note we move outsnamee of the comprehensive CM logging file
        FileLogLevel = 0,
        ConsoleLogLevel = 4,
        DaysToKeep = 5,
        RemoteLogLevel = 0,
        FileName = 'HAI Controller Manager',
        ConsoleName = 'OmniLink II',
    },

    LogMethods = {
        Local = true, -- use our own logger
        Parent = false, -- the c component,
        ComponentManager = false, -- log up to the CM, note both parent and cm should not be true as this could cause duplicate logging to the cm
    },

}


local Events = table.makeset ( {
	'Property',
} )

local DefaultFilters = {
		"*.*.*.*.*.*"
}



local Super = require 'Components.Classes.Base'


local Base = Super:New ( {

    Hidden = true,

    Requires = {
        {
            Type = 'Version',
            Identifier = 'Pro',
        },
        { -- xPL
            Type = 'Component',
            Identifier = 13100,
        },
    },


    Initialize = function (self)
         self:AddToDefaultSettings (DefaultSettings)
         self:AddEvents (Events)

        return Super.Initialize (self)
    end,


    AddProperties = function (self,properties)
        for property,setting in pairs (properties) do
--            assert (not self [property],property) -- make sure they are unique...
            self.Properties [property] = setting
        end

        -- build methods for properties, setup defaults....
        for property,settings in pairs (properties) do
            local property = property -- upvalues
            local settings = settings
			settings.LogLevel = settings.LogLevel or 3

            self ['Get'..property] = function (self)
                return self [property]
            end

            self ['Set'..property] = function (self,value)
				if value == nil then -- set to default
					value = (type (settings.Default) == 'table' and table.copy (settings.Default)) or settings.Default
				end

                assert (value ~= nil)

                if self [property] ~= value or settings.AlwaysSendOnSet then
                    self [property] = value
                    self:Log (settings.LogLevel,'Set Property ',property,value)
                    if settings.Event then
                        self:Event (settings.Event,property,value)
                    end
                    if settings.GirderEvent then
                       -- self:GirderEvent (settings.Event,property,value)
                    end
				else
                    --self:Log (settings.LogLevel,'Set Property (skipped) ',property,value)
                end
            end

            self [property] = (self [property] == nil and ((type (settings.Default) == 'table' and table.copy (settings.Default)) or settings.Default)) or self [property]
        end
    end,


    Enable = function (self)
        if self.Settings.LogMethods.Local then
            self:CreateLogger ()
        end

        self:LogLocal (1,'Starting')

        self.xPL = ComponentManager:GetComponentUsingID (13100)

        -- Mutex and functions to lock/unlock the handler and make the MessageHandler thread-save
        self._messagelock = thread.newmutex()

        self.Filters = self.Filters or DefaultFilters

        local b = Super.Enable (self)

        return b
    end,


    Disable = function (self)
        self._messagelock = nil

        local b = Super.Disable (self)
        return b
    end,


	MessageLock = function (self)
		self._messagelock:lock()
	end,


	MessageUnlock = function (self)
		self._messagelock:unlock()
	end,


    GetFilters = function (self)
        return self.Filters
    end,


    GetxPLEventDevice = function (self)
        return self.xPL.PluginID-- when raising events, use this as source to set it to xPLGirder
    end,


    -- get a value from the message at hand by its key (the first occurence of that key)
    GetMessageValueByKey = function (self,msg,key)
        for k,v in ipairs(msg.body) do
            if v.key == key then
                return v.value
            end
        end
    end,


    CleanKey = function (self,key)
        if type(key) == "string" then
            key = string.gsub(key, '%.', '_' )  -- remove any '.' (dot) as the variable inspector will not show tables with them
            key = string.gsub(key, '%:', '_' )  -- remove any ':' (dot) as the variable inspector will not show tables with them
        end
        return key
    end,


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


    ProcessMessage = function (self, msg)
        -- loop through all filters
        for _, filter in ipairs(self:GetFilters ()) do

            if self:FilterMatch ( msg, filter ) then
                return self:MessageHandler (msg,filter)
            end
        end

        return false
    end,


	_MessageHandler = function (self, msg, filter)
		--[[
		The handler function below will handle the actual message. The parameters are the xPL message
		and the filter string that passed the message.

		The return value should be a boolean indicating whether the standard xPLGirder event should
		be suppressed.
			msg is a table with the following keys;
			msg.type		message type, either one of 'xpl-cmnd', 'xpl-trig', or 'xpl-stat'.
			msg.hop			message hop-count
			msg.source		source address
			msg.target		target address (or wildcard)
			msg.schema		message schema
			msg.body		contains sub-tables, each with a 'key' and a 'value' field, so to access;
							first key value  :   msg.body[1].key
							first value value:   msg.body[1].value
		]]--


		-- add your code here to handle the actual message
		print ("Got one on filter: " .. filter .. " from source: " .. msg.source)


		-- Determine the return value
		-- false: The standard xPLGirder event will still be created (if all other handlers also
		--        return false)
		-- true:  The standard xPLGirder event is suppressed, this should be used when the handler
		--        has created a more specific event from the xPL message than the regular xPLGirder
		--        event.
		return false
	end,


    -- do not override
	MessageHandler = function (self, msg, filter)
		-- protected handler to run only singular, other threads can only enter after this call completed
		self:MessageLock()
		local s,r = pcall(self._MessageHandler, self, msg, filter)
		self:MessageUnlock()

		if s then	-- success
			return r
		else	-- failure
			-- error was returned from handler
			print("xPL Handler " .. self.ID .. " had a lua error;" .. r)
			print("while handling the following xPL message;")
			table.print(msg)
			gir.LogMessage(self.Name, ' failed while processing a message, see lua console', 2)
    		return false
		end
	end,

    ApplySettings = function (self)
    end,


    Event = function (self,...)
		--print ('HAI CM Event: ',unpack (arg))
        Super.Event (self,unpack (arg))
    end,


    Print = function (self)
    end,


    CreateLogger = function (self)
        local c = ComponentManager:GetComponentUsingID (13101)
        local logdir = c:GetSettings ().LogDirectory
        local ls = self.Settings.LogSettings

        self.Logger = Classes.Logger:New ( {
            ConsoleName = ls.ConsoleName,
            Filename = ls.FileName,
            FileLogLevel = ls.FileLogLevel,
            ConsoleLogLevel = console or ls.ConsoleLogLevel,
            DaysToKeep = ls.DaysToKeep,
            SubDirectory = logdir,
        } )
    end,


	GetDefaultPort = function (self)
		return DefaultPort
	end,


    LogLocal = function (self,level,...)
        if self.Settings.LogMethods.Local then
            self.Logger:Log (level,unpack (arg))
        end

        if self.Settings.LogMethods.Parent then
            self.Parent:LogC (level,'Controller '..GetName ()..':',unpack (arg))
        end

        if self.Settings.LogMethods.ComponentManager then
            self:Log (level,'HAI Controller '..GetName ()..':',unpack (arg))
        end
    end,


    -- tell the component manager to not log any of our events
    DoNotLogEvent = function (self,Event,...)
        return true
    end,



    Close = function (self)
        self:LogLocal (1,'Closing')
        Super.Close (self)
    end,


} )


return Base

