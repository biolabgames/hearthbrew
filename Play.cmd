@echo off
set "GODOT_ENGINE=%~dp0..\..\Godot_v4.7-stable_win64.exe"
if exist "%GODOT_ENGINE%" (
  start "" "%GODOT_ENGINE%" --path "%~dp0."
) else (
  echo Open project.godot in Godot 4.7 and press F5.
  echo The launcher expects this folder inside your Steam games folder.
  pause
)
