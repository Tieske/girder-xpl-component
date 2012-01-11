------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <br/><br/>
-- This file is an xPL message handler for <code>log.basic</code> messages. The xPL log messages
-- received will be logged in the Girder event log, including the apropriate icon. The sender
-- will be displayed as the source xPL address.
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

	ID = "LogBasic",		-- enter a unique string to identify this handler



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
		"*.*.*.*.log.basic"
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

		local mtext = GetValueByKey('text')
		local icon = GetValueByKey('type')
		if icon == 'inf' then
			icon = 0
		elseif icon == 'wrn' then
			icon = 1
		elseif icon == 'err' then
			icon = 2
		else
			-- nothing provided, assume informational
			icon = 0
		end

		local i
		for i = 1,table.getn(msg.body) do
			local k = msg.body[i].key
			if k ~= 'text' and k ~= 'type' then
				-- found an unknown key, append its value
				mtext = mtext .. ', ' .. k .. '=' .. msg.body[i].value
			end
		end

		gir.LogMessage('xPLGirder; ' .. msg.source, mtext, icon)

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
