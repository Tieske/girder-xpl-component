--[[



xPL



--]]


local ConfigID = 13100

local ComponentID = 13100



local ControlSettings = {   -- table to change controls based on Mode changes
    Select = {
        enable = {
            'group',
            },
        visible = {
            },
        disable = {
            },
        invisible = {
            'ok',
            'cancel',
            'add',
            'edit',
            'delete',
            'notice',
            },
    },

    Edit = {
        enable = {
            'group',
            },
        visible = {
            },
        disable = {
            },
        invisible = {
            'ok',
            'cancel',
            'add',
            'edit',
            'delete',
            'notice',
            },
    },

    Add = {
        enable = {
            'group',
            },
        visible = {
            },
        disable = {
            },
        invisible = {
            'ok',
            'cancel',
            'add',
            'edit',
            'delete',
            'notice',
            },
    },

    Disable = {
        enable = {
            },
        visible = {
            'notice',
            },
        disable = {
            },
        invisible = {
            'group',
            },
    },

}



local Super = require 'Classes.DUI.ConfigComponent'


local Config = Super:New ( {

    ID = ConfigID,

    ComponentID = ComponentID,

    ControlSettings = ControlSettings,



    OnComponentEvent = function (self,...)
        --print ('hai cm ui event ',unpack (arg))
--[[
hai cm ui event  Controller Property hai ControllerDataLoaded Sat Oct 09 2010 11:35:10
]]
        local component = self:GetComponent ()
        local event = arg [1]

        if event == component.Events.DUI then
            self:UpdateControls ()
            self:UpdateDUIPage ()
        end

        Super.OnComponentEvent (self,unpack (arg))
    end,


    UpdateControls = function (self,name)
        local component = self:GetComponent ()
        self.Controls.source.Caption = component.Source or ''
        self.Controls.address.Caption = component.Address or ''
        self.Controls.hostname.Caption = component.HostName or ''
        self.Controls.listenon.Caption = component.xPLListenOnAddress or ''
        self.Controls.listento.Caption = component.xPLListenToAddresses or ''
        self.Controls.broadcast.Caption = component.xPLBroadcastAddress or ''
        self.Controls.mode.Caption = component:GetMode () or ''
        self.Controls.received.Caption = component.ReceivedBytes or ''
        self.Controls.sent.Caption = component.SentBytes or ''

        Super.UpdateControls (self)
    end,


    BuildControls = function (self)
        Super.BuildControls (self)
    end,


    OnShow = function (self)
        local c = assert (ComponentManager:GetComponentUsingID (componentid))
        local dir = c.DUIImageDir
        self.Controls.image.Filename = dir .. '\\xpl.png'

        Super.OnShow (self)
    end,


    AddMode = function (self)
    end,


    EditMode = function (self)
    end,


    SelectMode = function (self)
    end,


    OnShow = function (self)
        Super.OnShow (self)
    end,


    OnEvent = function (self, ID1, ID2, Control)
        Super.OnEvent (self,ID1,ID2,Control)
    end,


    -- called when Add selected
    AddEvent = function (self)
    end,


    -- called when edit selected
    EditEvent = function (self)
        Super.EditEvent (self)
    end,


    -- called when OK selected
    OkEvent = function (self)
        Super.OkEvent (self)
    end,


    -- called when cancel selected
    CancelEvent = function (self)
        Super.CancelEvent (self)
    end,


    DeleteEvent = function (self)
        Super.DeleteEvent (self)
    end,


} )


