@echo off
setlocal EnableDelayedExpansion

:: Script: safeedit.bat
:: Purpose: Safely edit files with backup and logging functionality
:: Bonventure 2336318

:init
set "LOGFILE=backup_log.txt"
set "EDITOR=notepad"
set "MAXLOGS=5"

:: Check if running in command-line mode
if "%~1" neq "" (
    if /I "%~1"=="-restore" (
        call :restore_backup
        exit /b
    )
    if not "%~2"=="" (
        echo Error: Too many parameters entered.
        echo Usage: %~nx0 [filename] or %~nx0 -restore
        exit /b 1
    )
    set "FILENAME=%~1"
    goto :process_file
)

:interactive
echo My Safe File Editor
echo ================
echo [1] Edit a file
echo [2] Restore last backup
set /p "CHOICE=Select an option (1 or 2): "

if "!CHOICE!"=="1" (
    set /p "FILENAME=Enter the filename to edit: "
    if "!FILENAME!"=="" goto :interactive
    goto :process_file
) else if "!CHOICE!"=="2" (
    call :restore_backup
    exit /b
) else (
    echo Invalid choice. Try again.
    goto :interactive
)

:process_file
if not exist "!FILENAME!" (
    echo File does not exist. Creating new file...
    goto :edit_file
)

copy /y "!FILENAME!" "!FILENAME!.bak" >nul
if errorlevel 1 (
    echo Error: Could not create backup file.
    exit /b 1
)

:: Timestamp Logging
for /f "tokens=2 delims==" %%A in ('wmic os get localdatetime /value') do set datetime=%%A
set "DATE=!datetime:~0,4!-!datetime:~4,2!-!datetime:~6,2!"
set "TIME=!datetime:~8,2!:!datetime:~10,2!:!datetime:~12,2!"

:: Log backup
set "TEMPLOG=%TEMP%\templog.txt"
echo [!DATE! !TIME!] Backup created: !FILENAME! ? !FILENAME!.bak> "!TEMPLOG!"
if exist "!LOGFILE!" type "!LOGFILE!" >> "!TEMPLOG!"

:: Keep only last 5 log entries
set "count=0"
for /f "delims=" %%a in ('type "!TEMPLOG!"') do (
    set /a "count+=1"
    if !count! leq %MAXLOGS% echo %%a>> "!LOGFILE!.new"
)

move /y "!LOGFILE!.new" "!LOGFILE!" >nul
del "!TEMPLOG!" 2>nul
echo Backup created: !FILENAME!.bak

:edit_file
start /wait %EDITOR% "!FILENAME!"
echo File editing completed.
exit /b 0

:restore_backup
echo Restore Last Backup
echo ===================
set /p "FILENAME=Enter the filename to restore: "

if exist "!FILENAME!.bak" (
    copy /y "!FILENAME!.bak" "!FILENAME!" >nul
    echo Backup restored: !FILENAME!.bak ? !FILENAME!
) else (
    echo Error: No backup found for "!FILENAME!".
)
exit /b 0
