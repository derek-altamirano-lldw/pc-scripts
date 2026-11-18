@echo off
:: Define your source and destination paths (keep the quotation marks)
set "SOURCE=C:\Users\the_r\GitHub\totk_compendium_plus\public\data"
set "DESTINATION=C:\Users\the_r\My Drive (info@livelovedigitalworks.com)\Live Love Digital Works\Applications\TotK Compendium+\data"

set "LOGFILE=%~dpn0.html"

"C:\Program Files\WinMerge\WinMergeU.exe" /r /u /noninteractive /or "%LOGFILE%" "%SOURCE%" "%DESTINATION%"

if %errorlevel% equ 0 (
    echo Folders are completely identical.
) else if %errorlevel% equ 1 (
    echo Differences detected! Check your HTML report.
	goto :END
) else (
    echo An error occurred during comparison.
	GOTO :END
)

:: Generates a log file with the exact same path and name as this .cmd file
set "LOGFILE=%~dpn0.log"

:: Execute Robocopy to sync folders
:: robocopy "%SOURCE%" "%DESTINATION%" /MIR /XO /FFT /R:2 /W:5 /TEE /LOG:"%LOGFILE%"

:END
pause
