@echo off
echo off
call x_variables.bat
echo ============================================================
echo   Installing xPLGirder plugin
echo.
echo   Girder directory: %girder%
echo   Documentation directory: %girder%\%girderdoc%\xPLGirder
echo.
echo   This will overwrite existing files and empty the
echo   xPLHandler and documentation directories.
echo.
echo   If the directories are not correct, then abort and update
echo   the file 'x_variables.bat' accordingly.
echo.
echo ============================================================
echo.
echo Press any key to continue, or CTRL+C to abort
pause > nul

rem check if provided installation directory exists
if not exist "%girder%" goto girnotfound

rem remove existing directories
rem handlers and documentation may frequently change files/names
rem hence remove completely to prevent orphaned files
echo.
echo Now removing documentation directory...
rd /S/Q "%girder%\%girderdoc%\xPLGirder"
echo.
echo Now removing xPLHandlers directory...
rd /S/Q "%girder%\luascript\xPLHandlers"

rem create empty directories and copy files
echo.
echo Now creating documentation directory...
md "%girder%\%girderdoc%\xPLGirder"
echo.
echo Now creating xPLHandlers directory...
md "%girder%\luascript\xPLHandlers"
echo.
echo Now copying documentation...
xcopy /S/E docs\*.* "%girder%\%girderdoc%\xPLGirder"
echo.
echo Now copying xPL component and message handling files...
xcopy /S/E/Y luascript\*.* "%girder%\luascript\"
echo.
echo Now copying userinterface and action files...
xcopy /S/E/Y plugins\*.* "%girder%\plugins\"

rem done, success!
echo.
echo.
echo ============================================================
echo     Installation completed
echo ============================================================
echo.
start "Documentation" "%girder%\%girderdoc%\xPLGirder\index.html"
goto exit

:girnotfound
echo.
echo Error: The girder installation directory wasn't found.
echo.
goto exit

:exit
echo Press any key to exit...
pause > nul
