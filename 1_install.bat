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
echo   handlers, support and documentation directories.
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
rd /S/Q "%girder%\%girderdoc%\xPL"
echo.
echo Now removing Handlers directory...
rd /S/Q "%girder%\luascript\components\xpl\Handlers"
echo.
echo Now removing Support directory...
rd /S/Q "%girder%\luascript\components\xpl\Support"
echo.
echo Now removing older version Handlers directory...
rd /S/Q "%girder%\luascript\xPLHandlers"

pause

rem create empty directories and copy files
echo.
echo Now creating documentation directory...
md "%girder%\%girderdoc%\xPL"
echo.
echo Now creating xPL component directory...
md "%girder%\luascript\components\xPL"
echo.
echo Now creating Handlers directory...
md "%girder%\luascript\components\xpl\Handlers"
echo.
echo Now creating Support directory...
md "%girder%\luascript\components\xpl\Support"

pause

echo.
echo Now copying documentation...
xcopy /S/E docs\*.* "%girder%\%girderdoc%\xPL"
echo.
echo Now copying xPL component, message handling and support files...
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
start "Documentation" "%girder%\%girderdoc%\xPL\index.html"
goto exit

:girnotfound
echo.
echo Error: The girder installation directory wasn't found.
echo.
goto exit

:exit
echo Press any key to exit...
pause > nul
