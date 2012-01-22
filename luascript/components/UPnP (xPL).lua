--[[


UPnP devices from xPL component

Export/Import UPnP devices to G5 Device Manager


--]]


local License = [[

(C) Copyright Michael Cumming

Permission is hereby granted for Promixis to distribute this component with Grider 5, free of charge. Michael Cumming reserves all copyrights and other intellectual property rights.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


]]


local xPLUPnPComponentID = 13101

-- upnp devices we can export to the g5 DM
local DeviceClasses = {
 
    ['urn:schemas-upnp-org:device:MediaRenderer:1'] = require 'Components.UPnP (xPL).UPnP Devices.Media Renderer',
    ['urn:schemas-upnp-org:device:DimmableLight:1'] = require 'Components.UPnP (xPL).UPnP Devices.Dimmable Light',
}



require 'Classes.Date'

local PluginID = 13200
local PluginName = 'UPnP (xPL)'
local Global = 'UPnPxPL'
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
    
    KnownUPnPDevices = {}, -- list off all previously seen upnp devices indexed by uuid

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
    
    InterfaceDevices = {}, -- device list that interface with the g5 dm and upnp/xpl indexed by uuid
    
    KnownUPnPDevices = {}, -- list of all uupnp devices we have seen indexed by uuid

    Loaded = function (self)
        self.DUICopied = false

        self.ComponentSubDirectory = ComponentManager:GetComponentDirectory () .. '\\' .. ComponentSubDirectory

        -- copy ui xml file
        local spath = self.ComponentSubDirectory..'\\DUI\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\ui\\'

        local res = win.CopyFile (spath ..'UPnP (xPL).xml',dpath ..'UPnP (xPL).xml',false)
        if not res then
            self:LogLocal (5,'Error copying dui xml file, error',win.GetLastError ())
            --return false
        end

        self.DUIImageDir = spath -- store dui files know where to find images

        -- copy treescript stub file
        local spath = self.ComponentSubDirectory..'\\'
        local dpath = win.GetDirectory ('GIRDERDIR')..'\\plugins\\treescript\\'

        local res = win.CopyFile (spath ..'UPnP (xPL) UI.lua',dpath ..'UPnP (xPL) UI.lua',false)
        if not res then
            self:LogLocal (5,'error copying treescript ui files, error ',win.GetLastError (),spath ..'UPnP (xPL) UI.lua')
--            return false
        end

        self.DUICopied = true

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

        local pdevices = self.UPnPXPLHandler:GetUPnPDevices ()
        for _,pdevice in pairs (pdevices) do
            self:UPnPDeviceArrived (pdevice)
        end
        
        -- shouldn't need to do this
        --self.UPnPXPLHandler:RequestAnnounce ()
        
        --idl = self.InterfaceDevices -- *********** delete
        
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
        elseif event == self.UPnPXPLHandler.Events.DeviceLeft then
            local pdevice = assert (arg [2])
            self:UPnPDeviceLeft (pdevice)
        elseif event == self.UPnPXPLHandler.Events.DeviceVariable then
            local pdevice = assert (arg [2])
            local pservice = assert (arg [3])
            local svar = assert (arg [4])
            self:UPnPDeviceVariableUpdate (pdevice,pservice,svar)
        end
            
        self:Event (unpack (arg))  -- our events types are the same as for the upnp handler
    end,
    
    
    UPnPDeviceArrived = function (self,pdevice)
        self.Settings.KnownUPnPDevices [pdevice.deviceid] = {
            UUID = pdevice.deviceid,
            Name = pdevice.name,
            Type = pdevice.type,
        }

        local idevice = self.InterfaceDevices [pdevice.deviceid]
        if idevice then
            --print ('updating interface device')
            idevice:SetUPnPDevice (pdevice)
            idevice:SetStatus ('Ok')
        else
            local class = DeviceClasses [pdevice.type]
        
            if class then
                local idevice = assert (class:Create (pdevice.deviceid))
                idevice:SetStatus ('Ok')
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
    
    
    UPnPDeviceLeft = function (self,pdevice)
        local idevice = self.InterfaceDevices [pdevice.deviceid]
        if idevice then
            idevice:SetStatus ('Not Available')
        end
    end,
    
    
    GetUPnPDevice = function (self,UUID)
        return self.UPnPXPLHandler:GetUPnPDevice (UUID)
    end,

    
	UPnPRequestAnnounce = function (self)
        local c = assert (ComponentManager:GetComponentUsingID (xPLUPnPComponentID))
        
        c:RequestAnnounce ()
    end,
    
    
    GetInterfaceDevices = function (self)
        return self.InterfaceDevices 
    end,


    GetKnownUPnPDevices = function (self)    
        return self.Settings.KnownUPnPDevices
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

