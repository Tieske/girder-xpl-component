@echo off
echo off
call x_variables.bat
rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\xPLGirder.lua"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\xPL.lua"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\support\*.*"

start "xPLGirder" "%girdereditor%" "%girder%\plugins\treescript\xPLGirder.lua"
rem start "xPLGirder" "%girdereditor%" "ReadMe.txt"

rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\xPLHandlers\*.*"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\Handlers\*.*"

rem start "xPLGirder" "%girderuieditor%" "%girder%\plugins\ui\xPLGirder.xml"
