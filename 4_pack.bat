@echo off
echo off

echo ============================================================
echo   Packing and zipping xPLGirder plugin
echo.
echo   This will first call the pack and generate docs script
echo   and then create a zip file with the package.
echo.
echo ============================================================
echo.
echo Press any key to continue, or CTRL+C to abort
pause > nul

rem  temp directory 
set packdir=xPLGirder_Install
rem delete it if it exists
rmdir /S/Q %packdir%

rem  make sure we've got the latest and greatest
call 3_consolidate_and_document.bat

rem  make a temp directory with files to be packed
md %packdir%
md %packdir%\luascript
xcopy /S/E/Y luascript %packdir%\luascript
md %packdir%\docs
xcopy /S/E/Y docs %packdir%\docs
md %packdir%\plugins
xcopy /S/E/Y plugins %packdir%\plugins
copy copying*.* %packdir%
copy readme.txt %packdir%
copy x_variables.bat %packdir%
copy 1_install.bat %packdir%\install.bat

rem delete previous archive and pack temp directory
del xPLGirder.zip
"c:\program files\7-zip\7z.exe" a -r xPLGirder.zip %packdir%\*.*
rem delete temp dir again
rmdir /S/Q %packdir%
