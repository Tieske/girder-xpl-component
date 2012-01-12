------------------------------------------------------------------------------------------------
-- xPLGirder is a Girder component to connect Girder to an xPL network.
-- <br/><br/>
-- This file is part of xPLGirder and provides 2 actions in the Girder interface action tree
-- <ul><li>send a specific xPL message</li>
-- <li>send an automatic event message, where the xPL message is being generated based on the
-- Girder event that triggered it (see structure below)</li></ul>
-- Please not that these actions do not work (or might even generate errors) if the xPLGirder
-- component has not been enabled.
-- <br/><br/>
-- The message structure of Girder events being forwarded;<br/>
-- <code>xpl-trig<br/>
-- {<br/>
-- source=vendor.device-instance<br/>
-- target=*<br/>
-- hop=1<br/>
-- }<br/>
-- girder.basic<br/>
-- {<br/>
-- device= ...  Girder device ID<br/>
-- event= ... Girder eventstring<br/>
-- [pld1= ... event payload 1]<br/>
-- [pld2= ... event payload 2]<br/>
-- [pld3= ... event payload 3]<br/>
-- [pld4= ... event payload 4]<br/>
-- }<br/></code>
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


-- This file contains 2 actions;  specific message and the event message

--[[


xPLGirder UI File
xPLGirder.lua


Send Specific Message Action


--]]


local messagetypes = {
    'Command (xpl-cmnd)',
    'Trigger (xpl-trig)',
    'Status (xpl-stat)',
}

local paramids = {
    [1] = { Key = 'key1edit', Value = 'value1edit' },
    [2] = { Key = 'key2edit', Value = 'value2edit' },
    [3] = { Key = 'key3edit', Value = 'value3edit' },
    [4] = { Key = 'key4edit', Value = 'value4edit' },
    [5] = { Key = 'key5edit', Value = 'value5edit' },
    [6] = { Key = 'key6edit', Value = 'value6edit' },
}

local ActionID = 10124		-- Specific message

local Super = require 'Classes.DUI.ActionComponent'


local Config = Super:New ( {

    ID = ActionID,

    ComponentName = 'xPLGirder',

    UpdateControls = function (self)
        --local name = dui.GetStringItem (self.Controls.namelist) or ''

        Super.UpdateControls (self)
    end,


    BuildNameControl = function (self)
        local component = self:GetComponent ()
        local targetlist = component:GetSourceDevices()

        table.sort (targetlist)
        table.insert(targetlist, 1, "None (*)")

        dui.BuildStringsI (self.Controls.targetlist,targetlist)
        self.Controls.targetlist.ItemIndex = 0

        dui.BuildStringsI (self.Controls.messagetypelist,messagetypes)
    end,


    BuildControls = function (self)
        self:BuildNameControl ()
        Super.BuildControls (self)
    end,


    OnShow = function (self)
        Super.OnShow (self)
        local settings = unpickle(self.Action.sValue2)
        --table.print (settings)
        dui.SetStringIndex (self.Controls.messagetypelist, settings.MessageType)
        self.Controls.sourceedit.Text = settings.Header.Source
        dui.SetStringIndex (self.Controls.targetlist, settings.Header.Target)
        self.Controls.schemaclassedit.Text = settings.Header.Schema.Class
        self.Controls.schematypeedit.Text = settings.Header.Schema.Type
        for k,v in ipairs(paramids) do
            --print(v.Key,v.Value)
            self.Controls[v.Key].Text = (settings.Body.Params[k] and settings.Body.Params[k].Key) or ''
            self.Controls[v.Value].Text = (settings.Body.Params[k] and settings.Body.Params[k].Value) or ''
        end
        --self:UpdateControls ()
    end,


    OnAction = function (self,Event)
        --print ('xPLGirder:SendMessage:OnAction()',pld1,pld2,pld3,pld4)
        local payloads = {
        	['pld1'] = pld1,
        	['pld2'] = pld2,
        	['pld3'] = pld3,
        	['pld4'] = pld4,
        }

        local header = "%s\n{\nhop=1\nsource=%s\ntarget=%s\n}\n%s.%s\n"
        if self:IsComponentEnabled () then
            local component = self:GetComponent ()
            local settings = unpickle(self.Action.sValue2)
            local _,_, mtype = string.find (settings.MessageType, "%((.+)%)")
            local target = string.find (settings.Header.Target, "None") and "*" or settings.Header.Target
            local h = string.format(header, mtype, settings.Header.Source, target, settings.Header.Schema.Class, settings.Header.Schema.Type)
            local body = {}
            local counter = 2
            body[1] = "{"
            for k,v in ipairs(settings.Body.Params) do
                if v.Key and v.Key ~= '' then
                    local value = v.Value
                    local _,_, var = string.find (v.Value, "%<(.+)%>")
                    if var then
                        value = string.gsub(v.Value, "<"..var..">", payloads[var])
                    end
                    body[k + 1] = v.Key.."="..value
                    counter = counter + 1
                end
            end
            body[counter] = "}"
            local b = table.concat(body, "\n")
            local msg = h..b.."\n"
            --print (msg)
            component:SendMessage(msg)
        else
            return false,'Component not enabled'
        end
        Super.OnAction (self,Event)
    end,


    OnDefaults = function (self)
        local component = self:GetComponent ()
        local source = component:GetSource()

        self.Action.sValue1 = ''
        self.Action.sValue2 = pickle ({
            MessageType = '',
            Header = {
                Target = '',
                Source = source,
                Schema = {},
            },
            Body = {
                Params = {},
            },
        })
        Super.OnDefaults (self)
    end,


    OnApply = function (self)
        local settings = {}
        settings.MessageType = dui.GetStringItem (self.Controls.messagetypelist)
        settings.Header = {
            Source = self.Controls.sourceedit.Text,
            Target = dui.GetStringItem (self.Controls.targetlist),
            Schema = {
                Class = self.Controls.schemaclassedit.Text,
                Type = self.Controls.schematypeedit.Text,
            }
        }
        settings.Body = {}
        local params = {}
        for k,v in ipairs(paramids) do
            local key = self.Controls[v.Key].Text
            local value = self.Controls[v.Value].Text
            table.insert(params, k, {Key = key, Value = value} )
        end
        settings.Body.Params = params
        self.Action.sValue2 = pickle(settings)
        --table.print (settings)
        Super.OnApply (self)
    end,


    OnEvent = function (self, ID1, ID2, Control)
        Super.OnEvent (self,ID1,ID2,Control)
    end,


} )

--[[


xPLGirder UI File
xPLGirder.lua


Send Event Message Action

--]]


local ActionID = 10125		-- Generic event message, Tieske:  ID to be verified!!

-- Added by Tieske, generic 'forward event' action
local Config = Super:New ( {

    ID = ActionID,

    ComponentName = 'xPLGirder',

    UpdateControls = function (self)
        --local name = dui.GetStringItem (self.Controls.namelist) or ''
        Super.UpdateControls (self)
    end,


    BuildControls = function (self)
        Super.BuildControls (self)
    end,


    OnShow = function (self)
        Super.OnShow (self)
    end,


    OnAction = function (self,Event)
        --table.print (Event)
        --print ('xPLGirder:SendMessage:OnAction()',pld1,pld2,pld3,pld4,'Hello')
        local header = "%s\n{\nhop=1\nsource=%s\ntarget=%s\n}\n%s\n"
        if self:IsComponentEnabled () then
            local component = self:GetComponent ()
            local h = string.format(header, "xpl-trig", component.Source, "*", "girder.basic")
            local body = {}
            body[1] = "{"
            body[2] = "device=" .. (Event.Device or 18)
            body[3] = "event=" .. (Event.EventString or "")
            body[table.getn(body) + 1] = (pld1 ~= "" and pld1) or nil
            body[table.getn(body) + 1] = (pld2 ~= "" and pld2) or nil
            body[table.getn(body) + 1] = (pld3 ~= "" and pld3) or nil
            body[table.getn(body) + 1] = (pld4 ~= "" and pld4) or nil
            body[table.getn(body) + 1] = "}"
            local b = table.concat(body, "\n")
            local msg = h..b.."\n"
            --print (msg)
            component:SendMessage(msg)
        else
            return false,'Component not enabled'
        end
        Super.OnAction (self,Event)
    end,


    OnDefaults = function (self)
        Super.OnDefaults (self)
    end,


    OnApply = function (self)
        Super.OnApply (self)
    end,


    OnEvent = function (self, ID1, ID2, Control)
        Super.OnEvent (self, ID1, ID2, Control)
    end,


} )


return "xPL_actions.xml"
