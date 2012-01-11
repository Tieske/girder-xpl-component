@echo off
echo off
call x_variables.bat
start "xPLGirder" "%girdereditor%" "%girder%\luascript\Components\xPLGirder.lua"
start "xPLGirder" "%girdereditor%" "%girder%\plugins\treescript\xPLGirder.lua"
start "xPLGirder" "%girdereditor%" "ReadMe.txt"
start "xPLGirder" "%girdereditor%" "%girder%\luascript\xPLHandlers\*.*"
start "xPLGirder" "%girderuieditor%" "%girder%\plugins\ui\xPLGirder.xml"
