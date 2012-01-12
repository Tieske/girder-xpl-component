@echo off
echo off

rem   This file contains environment variables used by the 
rem   batch files.


rem   do NOT include trailing backslashes

rem the main girder directory
set girder=C:\Program Files\Promixis\Girder5

rem documentation directory within girder directory
set girderdoc=manual

rem editor for lua files
rem set girdereditor=C:\Program Files\JGsoft\EditPadPro6\EditPadPro.exe
set girdereditor=C:\Program Files\Lua\5.1\scite\scite.exe

rem editor for GUI files
set girderuieditor=%girder%\designer.exe

rem LuaDoc path (executable file)
set girdocumenter=%LUA_SOURCEPATH%\luadoc_start.lua