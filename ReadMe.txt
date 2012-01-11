xPLGirder Component

============================================================================
Contents
============================================================================
1 - Copyright and license
2 - Installing xPLGirder
3 - Using xPLGirder
4 - xPL message schemas
5 - Message handlers
6 - Known issues
7 - Troubleshooting
8 - Changelog

Download: http://www.thijsschreijer.nl/blog/?page_id=507
Support : Girder forums @ http://www.promixis.com/forums/showthread.php?21059
UPnP tutorial: http://www.thijsschreijer.nl/blog/?p=569
Sources : xPL SVN @ http://code.google.com/p/xplproject/source/browse/ filed
          under 'tieske.xPL_Girder_plugin'

============================================================================
1 - Copyright and license
============================================================================

(c) Copyright 2011-2012 Richard A Fox Jr., Thijs Schreijer

This file is part of xPLGirder.

xPLGirder is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

xPLGirder is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with xPLGirder.  If not, see <http://www.gnu.org/licenses/>.


About xPL
=========
xPL is an open protocol intended to permit the control and monitoring of 
home automation devices. The primary design goal of xPL is to provide a rich
set of features and functionality, whilst maintaining an elegant, 
uncomplicated message structure. The protocol includes complete discovery 
and auto-configuration capabilities which support a fully “plug-n-play” 
architecture.
xPL aplications and devices are available for a wide range of platforms.
See: http://xplproject.org.uk/


About Girder
============
Made by Promixis, Girder is the award winning home and industrial automation
software that allows users of all skill level to make advanced scripts and 
macros to automate many functions both on the computer and around the house 
or office. Based on the Lua scripting language, Girder is a graphical user 
interface that allows easy access to devices like lights, security systems, 
home theater, and any or all PC's functions including full application 
control for any program.
See: http://www.promixis.com/


============================================================================
2 - Installing xPLGirder
============================================================================
First make sure you get xPL running. It requires an application called an
'xPL hub' on each PC you intent to use xPL on and you have to configure the
firewall to allow traffic on UDP port 3865.
An easy way to configure xPL is using the wizard like approach of the
xPLCheckPackage (use the standalone executable). See: 
http://www.thijsschreijer.nl/blog/?page_id=150 

To install xPLGirder use the following steps;
   1 Copy both directories found in the ZIP file to the Girder installation 
     directory. This will merge their contents into the existing
     installation. You may also use the 'install.bat' to install.
   2 Restart Girder or press F11 to reset the scripting engine
   3 Enter the Girder component manager and enable the xPLGirder component
     that is now shown in the list of available components
   4 Check the log for any errors, and make sure you read the known issues
     below (see 6 Known Issues).
Done!

If specific message handlers are required (see Using xPLGirder below) then
copy those files into the 'luascript\xPLHandlers\' directory and restart
Girder (or press F11 to restart the script engine).

============================================================================
3 - Using xPLGirder
============================================================================
The xPLGirder plugin has 2 uses;
   1 - receiving and sending events from/to Girder; this is done through the
       xPL message schemas detailed below in 'xPL message schemas'.
   2 - responding to generic xPL messages; this is done through the raised
       events in girder (a generic xPL event) or through the specific
       message handlers
In the action tree 2 actions are available, one for sending a generic xPL
message, the other is used to forward a Girder event (the one triggering the
action) to the xPL network.

============================================================================
4 - xPL message schemas
============================================================================

The schema used contains 1 trigger and 1 command message, no status messages
have been defined. For more information about the structure of xPL messages
in general see http://xplproject.org.uk/wiki/index.php?title=XPL_Specification_Document#The_xPL_Protocol:_.22Lite_on_the_wire.2C_by_design.22

Trigger message when a grider event is forwarded to xPL
=======================================================
xpl-trig
{
source=vendor.device-instance
target=*
hop=1
}
girder.basic
{
device= ...  Girder device ID
event= ... Girder eventstring
[pld1= ... event payload 1]
[pld2= ... event payload 2]
[pld3= ... event payload 3]
[pld4= ... event payload 4]
}


Command message to raise a Girder event inside Girder
=====================================================
xpl-cmnd
{
source=vendor.device-instance
target=vendor.device-instance
hop=1
}
girder.basic
{
device= ...  Girder device ID
event= ... Girder eventstring
[pld1= ... event payload 1]
[pld2= ... event payload 2]
[pld3= ... event payload 3]
[pld4= ... event payload 4]
}

============================================================================
5 - Message handlers
============================================================================
Message handlers are 'plugins' that enable the handling of specific incoming
xPL messages. They are coded in Lua script, an example file is included in
the folder 'luascript\xPLHandlers\'.
All handlers must be located in this directory and will be loaded by the
xPLGirder component when it starts.
A sample file is available, just rename the extension from '.txt' to '.lua',
and watch the Girder lua console when xPL messages arrive. The sample file
can be copied and modified to suit your purpose, instructions are included
as comments in the sample file.

============================================================================
6 - Known issues
============================================================================
1) does not properly restore from standby/hibernate
2) does not properly reconfigure network upon network adapter changes and/or
   lost connections. You must restart Girder to recover from this!
   See this post; http://www.promixis.com/forums/showthread.php?17944-Girder-5-Bug-Thread&p=144529#post144529

============================================================================
7 - Troubleshooting
============================================================================
When the plugin does not work as expected check the following;
1) Check the Component manager, to make sure the xPLGirder component is
   enabled.
2) Check the lua console for any errors, if so, continue at step 4
3) watch the Girder log, you should see the following messages at startup;
	xPLGirder	Status changed to: Online
	xPLGirder	Status changed to: Startup
	xPLGirder	Loaded handler SensorBasic
	xPLGirder	Loaded handler LogBasic
	xPLGirder	Loaded handler CmndGirderBasic
   The 'Loaded handler' messages may differ based upon what handlers you
   have enabled in the handler directory.
   The 'Startup' message means that Girder is trying to connect to the xPL
   network. And the 'Online' message means that it succeeded in doing so.
   If you do not get the 'Online' message, then try;
   a) Shutdown Girder and restart, make sure it is connected to the network 
      before you restart Girder. If the network connection changes while
      Girder is running, it fails (see 6 known issues).
   b) Try running the xPL CheckPackage wizard again (see 2 Installing) and
      check everything is ok. Restart Girder afterwards.
   c) Download an xPL Logger application (for example the one from this
      site; http://xpl.lhopital.org/) and watch whether you see xPL traffic
4) drop a support request in the Girder forum thread for xPLGirder (see
   'Contents' at the top of this readme file)      

============================================================================
8 - Changelog
============================================================================
03-jan-2012 version 0.1.6 by Thijs Schreijer
         Added 6 lua events to the xPLGirder component;
            - xPLMessage
            - xPLHandlerLoaded
            - xPLHandlerInitialized
            - xPLHandlerShutDown
            - xPLDeviceArrived (also a new Girder event)
            - xPLDeviceLeft (also a new Girder event)
         And the Status event has been updated to show the connection state.
         xPL Devices are now also monitored on their heartbeats, and removed
         if they time out.
         UPnP handler update to fix endless loop in re-requesting
         announcements when a device leaves before being completely
         announced.
28-dec-2011 version 0.1.5 by Thijs Schreijer
         The UPnP handler had a very subtle bug that could in sporadic
         cases prevent a device from being announced in Girder. Fixed.
05-dec-2011 version 0.1.4 by Thijs Schreijer
         More verbose error logging (stacktrace) for handler errors added.
         Updated the UPnP handler. The UPnP gateway was changed to chop too 
         large values into smaller pieces, the handler now handles this.
         several bugfixes
         changed ValueUpdate event to return variable ID instead of name
03-oct-2011 version 0.1.3 by Thijs Schreijer
         Added UPnP.basic handler
         Added more verbose logging while trying to connect to the xPL Hub, 
         to aid initial setup.
         Updated template handler code. Added a mutex to make the message
         handler thread safe.
         Fixed a 'Payload overflow' error (reported by Mike C).
         Added 'Troubleshooting' to the readme (this file).
09-jul-2011 version 0.1.2 by Thijs Schreijer
         Bugfix; the actions were not visible in the action tree
13-jun-2011 version 0.1.1 by Thijs Schreijer
         Bugfix in Sensor.Basic handler
         Handlers are now called using pcall to prevent a faulty plugin from
         crashing the component.
07-jun-2011 version 0.1.0 by Thijs Schreijer
         Offloaded the handling of girder.basic messages to a message handler
         Added a 'PC Remote' rf remote handler for RFXLAN devices, also the
         ATI remote wonder, ATI remote wonder plus and Medion RF remotes are
         supported, yet their key-table is still empty
         Added a 'x10.basic' handler, generic use but if used with RFXLAN it
         provides support for the following brands of RF equipment (the ones
         using address wheels);
           · X10
           · KlikAanKlikUit,
           · Chacon,
           · HomeEasy,
           · DomiaLite,
           · Domia,
           · ByeByeStandBy,
           · ELRO AB600,
           · NEXA
           · Proove
           · Intertechno
           · Duwi
           · Flamingo
           · Ikea Koppla
           · Waveman
           · HomeEasy HE105
           · RTS10
           · Harrison Gurtains
         Added a 'ac.basic' handler, for use with RFXLAN. It provides support 
         for the following brands of RF equipment (the ones using using a 
         program/learn button);
           · ANSLUT,
           · Chacon,
           · DI.O,
           · KlikAanKlikUit,
           · NEXA,
           · Proove,
           · Intertechno,
           · Düwi,
           · HomeEasy UK,
           · HomeEasy EU.
05-jun-2011 version 0.0.9 by Thijs Schreijer
         events generated for devices arriving and leaving
         events generated for status changes of xPL connection
         bug; hbeat.basic was not recognized as device arriving
         log messages for loading handlers
         includes 3 generic handlers, for the following message schemas;
            - log.basic
            - sensor.basic
            - hbeat.* and config.* (removes the events, to clean up log)
         handler template was updated
26-may-2011 version 0.0.8 by Thijs Schreijer
         updated vendor from 'slyfox' to 'tieske' so it can be added to the
         tieske 'xPL vendor plugin'.
         Updated the component and action IDs which are now formally
         approved
25-may-2011 version 0.0.7 by Thijs Schreijer
         Bug fix that would truncate xpl-values containing a '=' character
         eventstring changed to match regular xPL filter format
         Added feature to add specific message handlers (see files in folder 
         luascript/xPLHandlers)
16-feb-2011 version 0.0.6 by Richard A Fox Jr.
         Added reading ListenOnAddress, ListenToAddresses and 
         BroadcastAddress from registry - Thanks to Thijs Schreijer
         Changed self.Receiver:receive() to self.Receiver:receivefrom() to 
         accommodate checking for packets coming from ListenOnAddress - 
         Thanks to Thijs Schreijer
         Corrected problem of no data received when broadcast is set to 
         255.255.255.255. Added self.Receiver:setoption("broadcast", true)
         to StartReceiver method.
14-feb-2011 by Richard A Fox Jr.
         Added version key/value to the hbeat messages
         Prevent xpl-trig girder.basic messages from being sent to the 
         Girder event queue
         Changed eventstring to source\message_type:Schema=schema from 
         source:Schema=schema
