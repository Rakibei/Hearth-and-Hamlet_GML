@echo off
setlocal EnableExtensions
title Hearth and Hamlet - Godot Mod Loader PCK Patcher

rem ============================================================
rem Hearth and Hamlet - Godot Mod Loader PCK patcher
rem
rem Expected layout:
rem   patch_pck.bat
rem   Hearth and Hamlet.exe
rem   Hearth and Hamlet.pck
rem   override.cfg
rem   addons\mod_loader\...
rem
rem This script:
rem   1. Extracts the game's global_script_class_cache.cfg.
rem   2. Merges it with Godot Mod Loader's class cache.
rem   3. Creates a timestamped backup of the current PCK.
rem   4. Patches only .godot/global_script_class_cache.cfg.
rem
rem Re-running is safe: Mod Loader class entries are de-duplicated
rem by class name before the new cache is written.
rem ============================================================

cd /d "%~dp0"

set "GAME_PCK=%CD%\Hearth and Hamlet.pck"
set "GAME_EXE=%CD%\Hearth and Hamlet.exe"
set "GDRE=%CD%\addons\mod_loader\vendor\GDRE\gdre_tools.exe"
set "MOD_CACHE=%CD%\addons\mod_loader\setup\global_script_class_cache_mod_loader.cfg"
set "WORK_DIR=%CD%\_gml_patch_temp"
set "EXTRACT_DIR=%WORK_DIR%\extracted"
set "MERGED_CACHE=%WORK_DIR%\global_script_class_cache.cfg"
set "PATCHED_PCK=%WORK_DIR%\Hearth and Hamlet.patched.pck"

echo.
echo ============================================================
echo  Hearth and Hamlet - Godot Mod Loader PCK Patcher
echo ============================================================
echo.

rem ---- Validate required files --------------------------------

if not exist "%GAME_EXE%" (
    echo [ERROR] Hearth and Hamlet.exe was not found.
    echo.
    echo Place this BAT file in the Hearth and Hamlet game folder,
    echo then run it again.
    goto :fail
)

if not exist "%GAME_PCK%" (
    echo [ERROR] Hearth and Hamlet.pck was not found.
    goto :fail
)

if not exist "%GDRE%" (
    echo [ERROR] GDRE Tools was not found:
    echo "%GDRE%"
    echo.
    echo Make sure the Godot Mod Loader files are installed first.
    goto :fail
)

if not exist "%MOD_CACHE%" (
    echo [ERROR] Godot Mod Loader's global class cache was not found:
    echo "%MOD_CACHE%"
    echo.
    echo This installer expects the 4.x-dev Godot Mod Loader layout.
    goto :fail
)

if not exist "%CD%\override.cfg" (
    echo [WARNING] override.cfg was not found.
    echo The PCK can still be patched, but Godot Mod Loader will not
    echo start unless its autoloads are configured.
    echo.
)

rem ---- Prepare work directory ---------------------------------

if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
mkdir "%EXTRACT_DIR%" >nul 2>&1

if not exist "%EXTRACT_DIR%" (
    echo [ERROR] Could not create temporary working directory.
    goto :fail
)

rem ---- Extract the game's current global class cache -----------

echo [1/4] Extracting the game's global class cache...

"%GDRE%" --headless "--extract=%GAME_PCK%" "--output=%EXTRACT_DIR%" "--include=res://.godot/global_script_class_cache.cfg"

if errorlevel 1 (
    echo.
    echo [ERROR] GDRE failed while extracting the class cache.
    goto :cleanup_fail
)

set "GAME_CACHE="

if exist "%EXTRACT_DIR%\.godot\global_script_class_cache.cfg" (
    set "GAME_CACHE=%EXTRACT_DIR%\.godot\global_script_class_cache.cfg"
)

if not defined GAME_CACHE (
    for /r "%EXTRACT_DIR%" %%F in (global_script_class_cache.cfg) do (
        if not defined GAME_CACHE set "GAME_CACHE=%%~fF"
    )
)

if not defined GAME_CACHE (
    echo.
    echo [ERROR] global_script_class_cache.cfg could not be found
    echo after extracting the PCK.
    goto :cleanup_fail
)

echo       Found: "%GAME_CACHE%"
echo.

rem ---- Merge caches --------------------------------------------

echo [2/4] Merging Godot Mod Loader and game class caches...

set "GAME_CACHE_ENV=%GAME_CACHE%"
set "MOD_CACHE_ENV=%MOD_CACHE%"
set "MERGED_CACHE_ENV=%MERGED_CACHE%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$game=Get-Content -Raw -LiteralPath $env:GAME_CACHE_ENV;" ^
 "$mod=Get-Content -Raw -LiteralPath $env:MOD_CACHE_ENV;" ^
 "$rx='(?s)^\s*list\s*=\s*\[(.*)\]\s*$';" ^
 "$gm=[regex]::Match($game,$rx);" ^
 "$mm=[regex]::Match($mod,$rx);" ^
 "if(-not $gm.Success){throw 'Could not parse the game class cache.'};" ^
 "if(-not $mm.Success){throw 'Could not parse the Mod Loader class cache.'};" ^
 "$objRx='(?s)\{.*?\}';" ^
 "$gameObjects=@([regex]::Matches($gm.Groups[1].Value,$objRx) ^| ForEach-Object {$_.Value});" ^
 "$modObjects=@([regex]::Matches($mm.Groups[1].Value,$objRx) ^| ForEach-Object {$_.Value});" ^
 "function GetClass([string]$o){$m=[regex]::Match($o,'\"class\"\s*:\s*&\"([^\"]+)\"');if($m.Success){return $m.Groups[1].Value};return ''};" ^
 "$modNames=New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal);" ^
 "foreach($o in $modObjects){$n=GetClass $o;if($n){[void]$modNames.Add($n)}};" ^
 "$keptGame=New-Object System.Collections.Generic.List[string];" ^
 "foreach($o in $gameObjects){$n=GetClass $o;if((-not $n) -or (-not $modNames.Contains($n))){$keptGame.Add($o)}};" ^
 "$all=@($modObjects)+@($keptGame);" ^
 "if($all.Count -eq 0){throw 'Merged class cache would be empty.'};" ^
 "$out='list=['+[Environment]::NewLine+($all -join (','+[Environment]::NewLine))+[Environment]::NewLine+']';" ^
 "$utf8=New-Object System.Text.UTF8Encoding($false);" ^
 "[System.IO.File]::WriteAllText($env:MERGED_CACHE_ENV,$out,$utf8);" ^
 "Write-Host ('      Mod Loader classes: ' + $modObjects.Count);" ^
 "Write-Host ('      Game classes kept:   ' + $keptGame.Count);" ^
 "Write-Host ('      Total classes:       ' + $all.Count);"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to merge the global class caches.
    goto :cleanup_fail
)

if not exist "%MERGED_CACHE%" (
    echo.
    echo [ERROR] The merged global class cache was not created.
    goto :cleanup_fail
)

echo.

rem ---- Create backup -------------------------------------------

echo [3/4] Creating backup...

for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TIMESTAMP=%%I"

set "BACKUP_PCK=%CD%\Hearth and Hamlet.pck.backup-%TIMESTAMP%"

copy /b /y "%GAME_PCK%" "%BACKUP_PCK%" >nul

if errorlevel 1 (
    echo.
    echo [ERROR] Could not create a backup of the PCK.
    goto :cleanup_fail
)

echo       Backup: "%BACKUP_PCK%"
echo.

rem ---- Patch PCK -----------------------------------------------

echo [4/4] Patching Hearth and Hamlet.pck...

"%GDRE%" --headless "--pck-patch=%GAME_PCK%" "--patch-file=%MERGED_CACHE%=res://.godot/global_script_class_cache.cfg" "--output=%PATCHED_PCK%"

if errorlevel 1 (
    echo.
    echo [ERROR] GDRE failed while creating the patched PCK.
    goto :cleanup_fail_keep_backup
)

if not exist "%PATCHED_PCK%" (
    echo.
    echo [ERROR] GDRE did not create the patched PCK.
    goto :cleanup_fail_keep_backup
)

rem Replace the active PCK only after patching completed successfully.
move /y "%PATCHED_PCK%" "%GAME_PCK%" >nul

if errorlevel 1 (
    echo.
    echo [ERROR] The patched PCK was created, but Windows could not
    echo replace the active Hearth and Hamlet.pck.
    echo.
    echo Make sure Hearth and Hamlet is completely closed.
    echo The original backup is here:
    echo "%BACKUP_PCK%"
    goto :cleanup_fail_keep_backup
)

rem ---- Done ----------------------------------------------------

rmdir /s /q "%WORK_DIR%" >nul 2>&1

echo.
echo ============================================================
echo  SUCCESS
echo ============================================================
echo.
echo Hearth and Hamlet.pck now contains the combined Godot Mod
echo Loader + game global class cache.
echo.
echo Backup created:
echo "%BACKUP_PCK%"
echo.
echo You can now start Hearth and Hamlet normally through Steam.
echo.
pause
exit /b 0

:cleanup_fail
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%" >nul 2>&1
goto :fail

:cleanup_fail_keep_backup
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%" >nul 2>&1
goto :fail

:fail
echo.
echo Installation was not completed.
echo.
pause
exit /b 1
