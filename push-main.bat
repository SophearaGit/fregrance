@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ================================================================
rem  push-main.bat  -  save your work and send it to GitHub (main)
rem
rem  1. Saves (commits) every change in the project.
rem  2. Brings in what others pushed to main, so nothing is lost.
rem  3. Sends your work to main on GitHub.
rem     On another branch (e.g. raa) it also updates that branch
rem     on GitHub, and creates it there the first time.
rem ================================================================
cd /d "%~dp0"

where git >nul 2>nul || (echo Git is not installed or not on PATH. & goto :fail)
git rev-parse --is-inside-work-tree >nul 2>nul || (echo This folder is not a Git project. & goto :fail)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
echo.
echo  Branch: !BRANCH!
echo.

rem ---- 1. Save changes -------------------------------------------
rem Private per-computer settings must never go to GitHub (the file stays on this PC).
git update-index --skip-worktree fragrance_backend/config.php >nul 2>nul
git add -A
git diff --cached --quiet
if errorlevel 1 (
    git status --short
    echo.
    set "MSG="
    set /p "MSG=Describe your change, or just press Enter: "
    if "!MSG!"=="" set "MSG=Update from %COMPUTERNAME%"
    git commit -m "!MSG!" || goto :fail
) else (
    echo  No new changes to save.
)

rem ---- 2. Get the latest main ------------------------------------
echo.
echo  Getting the latest main from GitHub...
git pull --no-rebase --no-edit origin main
if errorlevel 1 (
    echo.
    echo  Your work and someone else's changed the same lines.
    echo  Open the files marked "both modified" in VS Code ^(Source Control^),
    echo  pick which version to keep, save, then run this file again.
    goto :fail
)

rem ---- 3. Send it to GitHub ---------------------------------------
echo.
if /i "!BRANCH!"=="main" (
    git push origin main || goto :fail
) else (
    echo  Updating branch !BRANCH! on GitHub...
    git push -u origin "!BRANCH!" || goto :fail
    echo  Sending !BRANCH! into main...
    git push origin HEAD:main || goto :fail
)

rem Put branches that only exist on this computer (like raa) on GitHub too.
for /f "delims=" %%r in ('git for-each-ref --format^=%%^(refname:short^) refs/heads') do (
    git ls-remote --exit-code --heads origin %%r >nul 2>nul
    if errorlevel 2 (
        echo  Creating branch %%r on GitHub...
        git push -u origin %%r
    )
)

echo.
echo  Done. Your work is on GitHub (main).
echo.
pause
exit /b 0

:fail
echo.
echo  Stopped. Nothing was lost; read the message above.
echo.
pause
exit /b 1
