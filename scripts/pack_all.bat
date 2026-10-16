@echo off
echo ====================================================
echo  LINKORA — Building Both Android APK and Windows EXE
echo ====================================================

call scripts\build_windows_exe.bat
call scripts\build_android_apk.bat

echo.
echo ====================================================
echo  All packages created in folder: dist\
echo ====================================================
dir dist\*.apk dist\*.exe
pause
