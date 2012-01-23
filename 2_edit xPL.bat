@echo off
echo off
call x_variables.bat
start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\xPL.lua"
rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\UPnP*.lua"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\*.*"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\Support\*.*"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\Handlers\*.*"
rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\UPnP Devices\*.*"
rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\UPnP Devices\Interfaces\*.*"

start "xPLGirder" "%girdereditor%" "%girder%\plugins\treescript\xPL_actions.lua"
start "xPLGirder" "%girdereditor%" "ReadMe.txt"

rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\xPLHandlers\*.*"
rem start "xPLGirder" "%girderuieditor%" "%girder%\plugins\ui\xPLGirder.xml"
