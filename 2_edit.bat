@echo off
echo off
call x_variables.bat
start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\xPL.lua"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\*.*"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\support\*.*"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\components\xpl\Handlers\*.*"

start "xPLGirder" "%girdereditor%" "%girder%\plugins\treescript\xPL_actions.lua"
start "xPLGirder" "%girdereditor%" "ReadMe.txt"

rem start "xPLGirder" "%girdereditor%" "%girder%\luascript\xPLHandlers\*.*"
rem start "xPLGirder" "%girderuieditor%" "%girder%\plugins\ui\xPLGirder.xml"
