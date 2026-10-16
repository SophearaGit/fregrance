@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ================================================================
rem  pull-main.bat  -  get the newest work from GitHub (main)
rem
rem  Brings what others pushed to main into the branch you are on.
rem  Changes you have not saved yet are kept (put aside and put back).
rem ================================================================
cd /d "%~dp0"

where git >nul 2>nul || (echo Git is not installed or not on PATH. & goto :fail)
git rev-parse --is-inside-work-tree >nul 2>nul || (echo This folder is not a Git project. & goto :fail)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
echo.
echo  Branch: !BRANCH!
echo  Getting the latest main from GitHub...
echo.

rem Keep this computer's own database settings (never pushed, never overwritten).
git update-index --skip-worktree fragrance_backend/config.php >nul 2>nul
if exist "fragrance_backend\config.php" copy /y "fragrance_backend\config.php" "%TEMP%\fragrance-config-backup.php" >nul

git pull --no-rebase --no-edit --autostash origin main
set "PULL_FAILED=!errorlevel!"
if not exist "fragrance_backend\config.php" if exist "%TEMP%\fragrance-config-backup.php" copy /y "%TEMP%\fragrance-config-backup.php" "fragrance_backend\config.php" >nul

if not "!PULL_FAILED!"=="0" (
    echo.
    echo  Your work and the new changes touched the same lines.
    echo  Open the files marked "both modified" in VS Code ^(Source Control^),
    echo  pick which version to keep, save, then run push-main.bat.
    goto :fail
)

echo.
echo  Done. You have the latest main.
echo  If the app is running, press R in its terminal to restart it.
echo.
pause
exit /b 0

:fail
echo.
echo  Stopped. Nothing was lost; read the message above.
echo.
pause
exit /b 1
