@echo off
echo off
call x_variables.bat

rem check if provided installation directory exists
if not exist "%girder%" goto girnotfound

rem remove existing directories
rem handlers and documentation may frequently change files/names
rem hence remove completely to prevent orphaned files
echo.
echo Now empty documentation directory...
del /S/Q "docs"
echo.
echo Now empty handlers and support directory...
del /Q "luascript\components\xpl\Handlers\*.*"
del /Q "luascript\components\xpl\Support\*.*"

rem copy files
echo.
echo Now copying xPL component and message handling files...
copy "%girder%\luascript\Components\xPL.lua" luascript\Components\
xcopy /S/E/Y "%girder%\luascript\Components\xPL\*.*" luascript\components\xPL\
echo.
echo Now copying userinterface and action files...
xcopy /S/E/Y "%girder%\plugins\treescript\xpl*.*" plugins\treescript\
xcopy /S/E/Y "%girder%\plugins\ui\xpl*.*" plugins\ui\

rem start LuaDoc
echo.
echo Now starting LuaDoc to generate documentation...
rem rename luascript\xPLHandlers\xPLHandler_template.txt xPLHandler_template.lua
rem rename luascript\xPLHandlers\Block_hbeat_and_config.txt Block_hbeat_and_config.lua
cd luascript
"%girdocumenter%" -d ..\docs components ..\plugins\treescript\xpl_actions.lua
cd ..
rem "%girdocumenter%" -d docs plugins\treescript\xplgirder.lua luascript
rem rename luascript\xPLHandlers\xPLHandler_template.lua xPLHandler_template.txt
rem rename luascript\xPLHandlers\Block_hbeat_and_config.lua Block_hbeat_and_config.txt
start docs\index.html

rem done, success!
echo.
echo.
echo ============================================================
echo     Consolidated files back to source tree, incl. docs
echo ============================================================
echo.
goto exit

:girnotfound
echo.
echo Error: The girder installation directory wasn't found.
echo.
goto exit

:exit
echo Press any key to exit...
pause > nul
