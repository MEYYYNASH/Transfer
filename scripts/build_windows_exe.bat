@echo off
echo ====================================================
echo  LINKORA — Building Native Windows Desktop EXE
echo ====================================================

set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo Error: C# compiler csc.exe not found at %CSC%
    pause
    exit /b 1
)

if not exist "dist" mkdir dist

echo Compiling windows_app\Program.cs...
"%CSC%" /target:winexe /out:"dist\LINKORA-windows-x64.exe" /platform:x64 /reference:System.Windows.Forms.dll,System.Drawing.dll,System.dll,System.Core.dll windows_app\Program.cs

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Windows EXE built: dist\LINKORA-windows-x64.exe
) else (
    echo.
    echo [ERROR] Build failed!
)
pause
