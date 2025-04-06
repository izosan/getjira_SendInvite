@echo off
setlocal enabledelayedexpansion

echo ACE Deployment Calendar Invite Generator
echo =======================================
echo.

:input_version
set /p release_version=Enter release version (e.g., W15.2025.04.07): 

if "!release_version!"=="" (
    echo Release version cannot be empty. Please try again.
    goto input_version
)

echo.
echo Creating calendar invite for release version: !release_version!
echo.

:: Run the PowerShell script with the provided release version as a parameter
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Get-JiraIssuesAndCreateCalendarInvite.ps1" -ReleaseVersion "!release_version!"

echo.
echo Process completed.
echo.

pause