@echo off
setlocal
title Fragrance App

rem ---------------------------------------------------------------------------
rem   start-app.bat            run on the Android phone emulator (starts it if needed)
rem   start-app.bat chrome     run in Google Chrome instead
rem   start-app.bat -d windows any other options are passed straight to "flutter run"
rem
rem Every mode also opens the admin site in its own Chrome window.
rem Press q in this window to quit: the app, the phone and the admin window all close.
rem ---------------------------------------------------------------------------

if not exist "%~dp0fragrance_app\pubspec.yaml" goto noapp
cd /d "%~dp0fragrance_app"

rem The name of the project folder inside C:\laragon\www (for example fregrance_all).
rem The web addresses below are built from it, so the folder can have any name.
for %%I in ("%~dp0.") do set "FOLDER=%%~nxI"
set "ADMIN_URL=http://localhost/%FOLDER%/fragrance_backend/admin/"
set "API_DEFINE=--dart-define=API_PATH=/%FOLDER%/fragrance_backend/api"

rem Use C:\flutter if flutter is not already on PATH
where flutter >nul 2>nul
if not errorlevel 1 goto haveflutter
if exist "C:\flutter\bin\flutter.bat" set "PATH=C:\flutter\bin;%PATH%"
where flutter >nul 2>nul
if errorlevel 1 goto noflutter

:haveflutter
rem Find the Android SDK: C:\Android\Sdk first, then Android Studio's default folder.
set "SDK="
if exist "C:\Android\Sdk\platform-tools\adb.exe" set "SDK=C:\Android\Sdk"
if not defined SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "SDK=%LOCALAPPDATA%\Android\Sdk"
if not defined SDK if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "SDK=%ANDROID_HOME%"
if defined SDK set "ANDROID_HOME=%SDK%"
if defined SDK set "PATH=%SDK%\platform-tools;%SDK%\emulator;%PATH%"

set "MODE="
set "RUNFAILED="
set "ADMIN_OPENED="

echo Flutter version:
call flutter --version
echo.
call flutter pub get
if errorlevel 1 goto end
echo.

rem ------------------------------- Admin site --------------------------------
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
rem The admin window uses its own Chrome profile so it can be closed again on quit
rem without touching your other Chrome windows.
set "ADMIN_PROFILE=%LOCALAPPDATA%\FragranceAdminChrome"

rem The app and the admin site both get their data from Laragon. Warn if it is not running.
where curl >nul 2>nul
if errorlevel 1 goto openadmin
curl -s -o nul -m 3 "%ADMIN_URL%"
if not errorlevel 1 goto openadmin
echo WARNING: Laragon does not seem to be running. Open Laragon and click "Start All",
echo          otherwise the app and the admin site will have no data.
echo.

:openadmin
echo Opening the admin site: %ADMIN_URL%
echo.
if not exist "%CHROME%" goto admindefault
start "" "%CHROME%" --user-data-dir="%ADMIN_PROFILE%" --no-first-run --no-default-browser-check --app="%ADMIN_URL%"
set "ADMIN_OPENED=1"
goto pickmode

:admindefault
rem Chrome is not installed: use the default browser (this one is not closed on quit).
start "" "%ADMIN_URL%"

:pickmode
if /i "%~1"=="chrome" goto chrome
if /i "%~1"=="phone" goto phone
if not "%~1"=="" goto custom
if defined SDK if exist "%SDK%\emulator\emulator.exe" goto phone
goto chrome

:custom
call flutter run "%API_DEFINE%" %*
if errorlevel 1 set "RUNFAILED=1"
goto cleanup

rem ------------------------------ Android phone ------------------------------
:phone
if not defined SDK goto nosdk
if not exist "%SDK%\emulator\emulator.exe" goto nosdk
set "MODE=phone"

rem Is a phone already running?
for /f "tokens=1,2" %%A in ('adb devices 2^>nul') do if "%%B"=="device" goto phonerun

rem No: start the first phone that was created in Android Studio's Device Manager.
set "AVD="
for /f "delims=" %%A in ('emulator -list-avds 2^>nul ^| findstr /v /b /c:"INFO" /c:"WARNING"') do if not defined AVD set "AVD=%%A"
if not defined AVD goto noavd

echo Starting the phone emulator "%AVD%"...
start "Android emulator" /min emulator -avd "%AVD%"

echo Waiting for the phone to finish starting. This can take a minute or two.
adb wait-for-device
set /a TRIES=0

:waitboot
adb shell getprop sys.boot_completed 2>nul | findstr /b "1" >nul
if not errorlevel 1 goto phonerun
set /a TRIES+=1
if %TRIES% geq 100 goto boottimeout
ping -n 4 127.0.0.1 >nul
goto waitboot

:phonerun
echo.
echo Starting the app on the phone. The first build takes several minutes.
echo When you are finished, press q here to close everything.
echo.
call flutter run -d emulator "%API_DEFINE%"
if errorlevel 1 set "RUNFAILED=1"
goto cleanup

:nosdk
echo The Android emulator was not found. Install Android Studio first,
echo or run "start-app.bat chrome" to use Chrome instead.
set "RUNFAILED=1"
goto cleanup

:noavd
echo No phone has been created yet. Open Android Studio, go to
echo More Actions - Virtual Device Manager, and create one. Then run this file again.
set "RUNFAILED=1"
goto cleanup

:boottimeout
echo The phone did not finish starting in time. Run this file again.
set "RUNFAILED=1"
goto cleanup

rem --------------------------------- Chrome ----------------------------------
:chrome
rem Make sure Flutter opens Google Chrome itself, not another browser.
if exist "%CHROME%" set "CHROME_EXECUTABLE=%CHROME%"
echo Starting the app in Chrome at phone size. The first build takes a few minutes.
echo When you are finished, press q here to close everything.
echo.
call flutter run -d chrome "%API_DEFINE%" --web-browser-flag "--disable-web-security" --web-browser-flag "--window-size=500,900"
if errorlevel 1 set "RUNFAILED=1"
goto cleanup

rem ------------------------- Close what this file opened ----------------------
:cleanup
echo.
if not "%MODE%"=="phone" goto closeadmin
echo Closing the phone emulator...
adb emu kill >nul 2>nul

:closeadmin
if not defined ADMIN_OPENED goto afterclean
echo Closing the admin window...
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'chrome.exe' -and $_.CommandLine -like '*FragranceAdminChrome*' -and $_.CommandLine -notlike '*--type=*' } | ForEach-Object { taskkill /pid $_.ProcessId | Out-Null }" >nul 2>nul

:afterclean
rem After a normal quit the window just finishes; after a problem it waits so you can read it.
if defined RUNFAILED goto end
goto done

:noapp
echo The app's code was not found in "%~dp0fragrance_app".
echo That folder should contain pubspec.yaml. If you got this project from GitHub,
echo pull the latest version: the app folder was missing from the first upload.
goto end

:noflutter
echo Flutter was not found.
echo Download the Flutter SDK for Windows from https://docs.flutter.dev/install/manual
echo and extract it so that C:\flutter\bin\flutter.bat exists, then run this file again.

:end
echo.
pause

:done
endlocal
