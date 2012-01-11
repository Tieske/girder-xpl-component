------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <br/><br/>
-- This file is an xPL message handler for <code>ac.basic</code> messages used by 
-- the <a href="http://www.rfxcom.com">RFXLAN device</a>.
-- Received message with this schema will be transformed into a standard Girder event. The event 
-- source will be xPLGirder. The event payloads will be;
-- <ol><li>device address and unit id, separated by an '_' (underscore)</li>
-- <li>command</li>
-- <li>level (in case of a dimm level)</li>
-- <li>xpl message type (cmnd, trig, stat)</li></ol>
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



local xPLEventDevice = 10124	-- when raising events, use this as source to set it to xPLGirder

local myNewHandler = {

	ID = "AcBasic",		-- enter a unique string to identify this handler



	--[[
	first define a list of filters to trigger the message handler. Any filter that has a positive
	match will trigger the handler. Each Handler will be called once per message, so if this handler
	has 2 filters that match, only the first will call the handler.

	a filter is a dot ('.') separated string with xPL message elements, each element may be
	wildcarded with an asterix ('*').

		filter = [msgtype].[vendor].[device].[instance].[schemaclass].[schematype]

	The default filter '*.*.*.*.*.*' will call the handler for every message received

	]]--

	Filters = {
		"*.*.*.*.ac.basic",
	},

	Initialize = function (self)
		-- function called upon initialization of this handler
	end,

	ShutDown = function (self)
		-- function called upon shuttingdown this handler
	end,

	MessageHandler = function (self, msg, filter)
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

		local GetValueByKey = function (key)
			-- get a value from the message at hand by its key (the first occurence of that key)
			for k,v in ipairs(msg.body) do
				if v.key == key then
					return v.value
				end
			end
		end




		-- add your code here to handle the actual message
		local prot = string.Split( msg.schema, '.' )[1]
		local typ = string.Split(msg.type, '-')[2]
		local dev = GetValueByKey('address') .. "_" .. GetValueByKey('unit')
		local cmd = GetValueByKey('command')
		local lev = GetValueByKey('level')
		if lev ~= nil then
			cmd = cmd .. "_" .. lev
		end
		local eventstring = typ .. ' ' .. prot .. '_' .. dev .. '_' .. cmd
		gir.TriggerEvent(eventstring, xPLEventDevice, dev, cmd, lev, typ)


		-- Determine the return value
		-- false: The standard xPLGirder event will still be created (if all other handlers also
		--        return false)
		-- true:  The standard xPLGirder event is suppressed, this should be used when the handler
		--        has created a more specific event from the xPL message than the regular xPLGirder
		--        event.
		return true
	end,
}


-- finally deliver the handler to the xPLGirder component
return myNewHandler
