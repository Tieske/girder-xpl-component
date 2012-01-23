--[[

Config

--]]


local ConfigID = 13205

local ControlSettings = {   -- table to change controls based on Mode changes
    Select = {
        enable = {
            },
        visible = {
            },
        disable = {
            },
        invisible = {
        },
    },

    Disable = {
        enable = {
            },
        visible = {
            },
        disable = {
            },
        invisible = {
            },
    },

}


local Super = require 'Classes.DUI.ConfigComponent'


local Config = Super:New ( {

    ID = ConfigID,

    ComponentID = 13200,

    ControlSettings = ControlSettings,

    UpdateControls = function (self)
        local c = self:GetComponent ()
        self.Controls.about.Caption = (c and c.License) or 'Component not enabled'
        --self.Controls.version.Caption = ('Version ' .. (c and c.License) or 'NA')

        Super.UpdateControls (self)
    end,


    OnShow = function (self)
        self:UpdateControls ()
        Super.OnShow (self)
    end,

} )


