------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <br/><br/>
-- This file is an xPL message handler for <code>fragment.basic</code> messages. These messages
-- are fragments of a message that was too large to send at once. This handler will collect them
-- reconstruct the original message and then deliver that to xPLGirder.
-- Only receiving these messages is supported, not sending. This handler is basically an 
-- infrastructure thing, it bypasses the size limit of xPL messages, and should work unnoticed by
-- the user and other handlers.
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

require 'Classes.DelayedExecutionDispatcher'
require 'thread'
require 'date'

local xPLEventDevice = 10124	-- when raising events, use this as source to set it to xPLGirder

local fragments = {} 			-- table to maintain incomplete fragments
--[[
	elements in this list should be structured as;
	    [<sourceaddress> .. ':' .. ID] = {
				expire = <time it expires, or nil while incomplete>,
				waitingfor = {<numeric list with message numbers still incomplete>},
				messages = {<list of received messages indexed by their number>}
				fragmentrequested = <true / false if the timer already requested a fragment after initial timeout>
			}
]]--

local GetValueByKey = function (key, msg)
	-- get a value from the message at hand by its key (the first occurence of that key)
	for k,v in ipairs(msg.body) do
		if v.key == key then
			return v.value
		end
	end
end

local myNewHandler = {

	ID = "FragmentBasic",		-- enter a unique string to identify this handler



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
		"*.*.*.*.fragment.basic"
	},

	Initialize = function (self)
		-- function called upon initialization of this handler
		--print ("Initializing the xPL handler ID: " .. self.ID)
		fragments = {}		-- clear fragments list
	end,

	ShutDown = function (self)
		-- function called upon shuttingdown this handler
		--print ("Shutting down the xPL handler ID: " .. self.ID)
		fragments = {}		-- clear fragments list
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

		-- collect messageID, fragment number, total numbers
		local partid = GetValueByKey("partid",msg)
		local _, _, fragnr, fragcount, sid = string.find(partid, "(%d+)/(%d+):(.+)" )
		fragnr = tonumber(fragnr)
		fragcount = tonumber(fragcount)
		local mid = msg.source .. ':' .. sid
		local fm = fragments[mid]

		-- check existence, add to fragment list
		if fm == nil then
		-- new fragmented message
			fm = {
					waitingfor = {},
					messages = {},
				}
			for n = 1,fragcount do
				fm.waitingfor[n] = n
			end
			fm.source = msg.source
			fm.messageid = sid
			fm.waitingfor[fragnr] = nil
			fm.messages[fragnr] = msg
			fragments[mid] = fm
			fm.timer = gir.CreateTimer("", function () self.TimerExpired(self, mid) end, "", false)
			fm.timer:Arm(3000)
		else
			-- existing fragmented message, add fragment to it
			if fm.expire ~= nil then
				-- message was already completed, fragment probably requested by someone else
				-- update expire time
				fm.expire = date:now()
				fm.expire.Minute = fm.expire.Minute + 1
			else
				fm.waitingfor[fragnr] = nil
				fm.messages[fragnr] = msg
				fm.timer:Cancel()
				fm.timer:Arm(3000)
				fm.fragmentrequested = nil
			end
		end
		-- check for completeness
		if fm.expire == nil and table.IsEmpty(fm.waitingfor) then
			-- message is complete, start reconstruction
			local m = table.copy(fm.messages[1])
			m.body = {}			-- start with empty body
			local cnt = 1
			for n = 1, fragcount do
				local msg = fm.messages[n]
				local gotschema = true
				local gotid = false
				if n == 1 then
					-- get original schema value
					m.schema = GetValueByKey("schema", msg)
					gotschema = false
				end
				for i,kvp in ipairs(msg.body) do
					if kvp.key ~= "schema" or gotschema == true then
						if kvp.key ~= "partid" or gotid == true then
							m.body[cnt] = kvp
							cnt = cnt + 1
						else
							gotid = true
						end
					else
						gotschema = true
					end
				end
			end
			-- cleanup
			fm.timer:Cancel()
			fm.timer:Destroy()
			fm.expire = date:now()
			fm.expire.Minute = fm.expire.Minute + 1
			fm.messages = nil
			fm.waitingfor = nil
			-- handle the reconstructed message, but do this delayed to prevent lock-ups due to mutexes
			local ded = Classes.DelayedExecutionDispatcher:New (100, function () xPLGirder:ProcessReceivedMessage(m) end)
		end

		-- cleanup expired items in fragment list
		for id,msg in fragments do
			if msg.expire ~= nil then
				if date:now() > msg.expire then
					-- can delete it by now
					fragments[id] = nil
				end
			end
		end

		return true	-- suppress standard event
	end,

	_TimerExpired = function (self, mid)
		local fm = fragments[mid]
		if fm ~= nil then
			if fm.fragmentrequested then
				-- a fragment was already requested, but apparently not
				-- received, dispose of message all together
				fragments[mid] = nil
				fm.timer:Destroy()
				fm.expire = nil
				fm.messages = nil
				fm.waitingfor = nil
				gir.LogMessage(xPLGirder.Name, self.ID .. ' disposed fragmented message ' .. mid .. ' because not all fragments could be retrieved', 2)
			else
				-- timeout while waiting, so go request missing fragments
				local header = "xpl-cmnd\n{\nhop=1\nsource=%s\ntarget=%s\n}\nfragment.request\n{\ncommand=resend\nmessage=%s\n"
				local body = ""
				local footer = "}\n"
				-- create list of key-value pairs with missing fragments
				for k,v in fm.waitingfor do
					body = body .. "part=" .. v .. "\n"
				end
				-- build and send message
				local msg = string.format(header .. body .. footer, xPLGirder.Source, fm.source, fm.messageid)
				xPLGirder:SendMessage(msg)
				-- restart timer
				fm.fragmentrequested = true
				fm.timer:Arm(7000)
			end
		end
	end,

	TimerExpired = function (self, mid)
		self:Lock()
		self:_TimerExpired(mid)
		self:Unlock()
	end,

	-- Mutex and functions to lock/unlock the handler and make the MessageHandler thread-save
	_lock = thread.newmutex(),
	Lock = function (self)
		self._lock:lock()
	end,
	Unlock = function (self)
		self._lock:unlock()
	end,
	MessageHandler = function (self, msg, filter)
		-- protected handler to run only singular, other threads can only enter after this call completed
		self:Lock()
		local result = false
		local s,r = pcall(self._MessageHandler, self, msg, filter)
		if s then	-- success
			result = r
		else	-- failure
			-- error was returned from handler
			print("xPLHandler " .. self.ID .. " had a lua error;" .. r)
			print("while handling the following xPL message;")
			table.print(msg)
			gir.LogMessage(xPLGirder.Name, self.ID .. ' failed while processing a message, see lua console', 2)
		end
		self:Unlock()
		return result
	end,

}


-- finally deliver the handler to the xPLGirder component
return myNewHandler
