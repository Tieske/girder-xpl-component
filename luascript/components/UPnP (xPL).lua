--[[


UPnP devices from xPL component

Export/Import UPnP devices to G5 Device Manager


--]]


local License = [[

(C) Copyright Michael Cumming

Permission is hereby granted for Promixis to distribute this component with Grider 5, free of charge. Michael Cumming reserves all copyrights and other intellectual property rights.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


]]



local DeviceClasses = {

    ['urn:schemas-upnp-org:device:MediaRenderer:1'] = require 'Components.UPnP Devices.Media Renderer',
    ['urn:schemas-upnp-org:device:DimmableLight:1'] = require 'Components.UPnP Devices.Dimmable Light',
}



require 'Classes.Date'

local PluginID = 13200
local PluginName = 'UPnP (xPL)'
local Global = false
local Description = 'Export/Import UPnP devices to G5 Device Manager via xPL component and UPnP 2 xPL gateway'
local ConfigFile = 'UPnP (xPL).cfg'
local Version = '0.0.1'


local DefaultSettings = {
    LogDirectory = 'UPnP (xPL)',

    LogSettings = {  -- note we move logging of device and direct component stuff that is HAI OmniLink related outside of the comprehensive CM logging file
        FileLogLevel = 0,
        ConsoleLogLevel = 4,
        DaysToKeep = 5,
        RemoteLogLevel = 0,
        FileName = 'UPnP',
        ConsoleName = 'UPnP',
    },

    CurrentUPnPDevices = {}, -- list of all currently enumerate upnp devices

}

local ComponentSubDirectory = 'UPnP (xPL)'


local Requires = {
    {
        Type = 'Version',
        Identifier = 'Pro',
    },

    { -- xPL
        Type = 'Component',
        Identifier = 13100,
    },
}


local Events = table.makeset ({
    'DeviceArrived',
    'DeviceLeft',
    'DeviceVariable',
})


local Super = require 'Components.Classes.Base'


local UPnP = Super:New ( {

    ID = PluginID,
    Name = PluginName,
    Description = Description,
    Global = Global,
    ConfigFile = ConfigFile,
    Version = Version,
    DefaultSettings = DefaultSettings,
    Requires = Requires,
    License = License,

    UPnPXPLHandler = false, -- ref to UPnP handler component

    SubscribeFunction = false,

    InterfaceDevices = {},

    Loaded = function (self)
        self.DUICopied = false

        self.ComponentSubDirectory = ComponentManager:GetComponentDirectory () .. '\\' .. ComponentSubDirectory

        -- copy ui xml file
        --[[
        local spath = self.ComponentSubDirectory..'\\DUI\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\ui\\'

        local res = win.CopyFile (spath ..'HAI OmniLink II.xml',dpath ..'HAI OmniLink II.xml',false)
        if not res then
            self:LogLocal (5,'Error copying dui xml file, error',win.GetLastError ())
            --return false
        end

        self.DUIImageDir = spath -- store dui files know where to find images

        -- copy treescript stub file
        local spath = self.ComponentSubDirectory..'\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\treescript\\'

        local res = win.CopyFile (spath ..'HAI OmniLink II UI.lua',dpath ..'HAI OmniLink II UI.lua',false)
        if not res then
            self:LogLocal (5,'error copying treescript ui files, error ',win.GetLastError (),spath ..'HAI OmniLink II.lua')
--            return false
        end

        self.DUICopied = true
]]
        return Super.Loaded (self)
    end,


    Initialize = function (self)
        self:AddEvents (Events)

        local b = Super.Initialize (self)
        if not self.DUICopied then
            self:SetStatus ('FailedDUI')
        end
        return b
    end,


    -- called by stub file in the treescript dir
    LoadUIFiles = function (self)
        local path = self.ComponentSubDirectory..'\\DUI\\'

        for fa in win.Files (path..'*.lua') do
          if math.band (fa.FileAttributes, win.FILE_ATTRIBUTE_DIRECTORY) == 0 then
            self:LogLocal (2,'Loading UI file ',fa.FileName)
            local succ,f,err = Protect (loadfile,path..fa.FileName)
            if succ and f then
                Protect (f)
            else
                self:LogLocal (5,'Error loading UI file ',fa.FileName)
                self:LogLocal (5,err)
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

        self.UPnPXPLHandler = assert (ComponentManager:GetComponentUsingID (13101))

        self.SubscribeFunction = function (...)
            self:XPLUPnPEventHandler (unpack (arg))
        end

        self.UPnPXPLHandler:Subscribe (self.SubscribeFunction)

        self.UPnPXPLHandler:RequestAnnounce ()

        idl = self.InterfaceDevices -- *********** delete

        return b
    end,


    Disable = function (self)
        self.UPnPXPLHandler:Unsubscribe (self.SubscribeFunction)
        return Super.Disable (self)
    end,


    LoadSettings = function (self)
        Super.LoadSettings (self)
    end,


    SaveSettings = function (self)
        Super.SaveSettings (self)
    end,


    GetComponentSubDirectory = function (self)
        return assert (self.ComponentSubDirectory)
    end,


    -- receives events from the xPL UPnP handler component
    XPLUPnPEventHandler = function (self,...)
        --print ('got upnp event',unpack (arg))
        local event = arg [1]

        if event == self.UPnPXPLHandler.Events.DeviceArrived then
            local pdevice = assert (arg [2])
            self:UPnPDeviceArrived (pdevice)
        elseif event == self.UPnPXPLHandler.Events.DeviceVariable then
            local pdevice = assert (arg [2])
            local pservice = assert (arg [3])
            local svar = assert (arg [4])
            self:UPnPDeviceVariableUpdate (pdevice,pservice,svar)
        end

    end,


    UPnPDeviceArrived = function (self,pdevice)
        if not self.InterfaceDevices [pdevice.deviceid] then
            local class = DeviceClasses [pdevice.type]

            if class then
                local idevice = assert (class:Create (pdevice.deviceid))
                self.InterfaceDevices [idevice:GetUUID ()] = idevice
            else
--                print ('no device for type',pdevice.type)
            end
        end
    end,


    UPnPDeviceVariableUpdate = function (self,pdevice,pservice,svar)
        local idevice = self.InterfaceDevices [pdevice.deviceid]
        if idevice then
            idevice:UPnPVariableUpdate (pservice,svar)
        end
    end,


    GetUPnPDevice = function (self,UUID)
        return self.UPnPXPLHandler:GetUPnPDevice (UUID)
    end,


    CreateLogger = function (self)
        local logdir = self:GetSettings ().LogDirectory
        local ls = self.Settings.LogSettings

        self.Logger = Classes.Logger:New ( {
            ConsoleName = ls.ConsoleName,
            Filename = ls.FileName,
            FileLogLevel = ls.FileLogLevel,
            ConsoleLogLevel = console or ls.ConsoleLogLevel,
            DaysToKeep = ls.DaysToKeep,
            SubDirectory = ilogdir,
        } )
    end,


    LogLocal = function (self,level,...)
        if self.Logger then
            self.Logger:Log (level,unpack (arg))
        else
            self:Log (level,unpack (arg))
        end
    end,


    Close = function (self)
        self:LogLocal (0,'Closing')
        Super.Close (self)
    end,


} )


return UPnP

