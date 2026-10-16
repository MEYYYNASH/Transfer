@echo off
echo ====================================================
echo  LINKORA — Building Signed Android Release APK
echo ====================================================

set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
set ANDROID_SDK=C:\Users\ASUS\AppData\Local\Android\Sdk
set BUILD_TOOLS=%ANDROID_SDK%\build-tools\35.0.0
set PLATFORM=%ANDROID_SDK%\platforms\android-36\android.jar

if not exist "%BUILD_TOOLS%\aapt2.exe" (
    echo Error: Android SDK build tools not found.
    pause
    exit /b 1
)

if not exist "dist" mkdir dist
if not exist "android_build\obj" mkdir android_build\obj

echo [1/6] Compiling resources...
"%BUILD_TOOLS%\aapt2.exe" compile --dir android_build\res -o android_build\compiled_res.zip

echo [2/6] Linking APK...
"%BUILD_TOOLS%\aapt2.exe" link -I "%PLATFORM%" --manifest android_build\AndroidManifest.xml -o android_build\unaligned.apk android_build\compiled_res.zip --auto-add-overlay

echo [3/6] Compiling Java classes...
javac -cp "%PLATFORM%" -d android_build\obj android_build\src\com\linkora\app\MainActivity.java

echo [4/6] Converting to DEX with D8...
call "%BUILD_TOOLS%\d8.bat" --release --min-api 24 --output android_build\obj android_build\obj\com\linkora\app\MainActivity.class

echo [5/6] Injecting classes.dex and Zipaligning...
jar -uf android_build\unaligned.apk -C android_build\obj classes.dex
"%BUILD_TOOLS%\zipalign.exe" -p -f 4 android_build\unaligned.apk dist\LINKORA-android-aligned.apk

echo [6/6] Signing APK...
if not exist "android_build\debug.keystore" (
    keytool -genkey -v -keystore android_build\debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
)

call "%BUILD_TOOLS%\apksigner.bat" sign --ks android_build\debug.keystore --ks-pass pass:android --out dist\LINKORA-android.apk dist\LINKORA-android-aligned.apk

echo.
echo [SUCCESS] Android APK built: dist\LINKORA-android.apk
pause
