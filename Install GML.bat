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
rem   addons\mod_loader\...
rem
rem This script:
rem   1. Extracts the game's global_script_class_cache.cfg.
rem   2. Merges it with Godot Mod Loader's class cache.
rem   3. Creates a timestamped backup of the current PCK.
rem   4. Patches only .godot/global_script_class_cache.cfg.
rem   5. Creates override.cfg and the mods folder after patching succeeds.
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

rem ---- Prepare work directory ---------------------------------

if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
mkdir "%EXTRACT_DIR%" >nul 2>&1

if not exist "%EXTRACT_DIR%" (
    echo [ERROR] Could not create temporary working directory.
    goto :fail
)

rem ---- Extract the game's current global class cache -----------

echo [1/5] Extracting the game's global class cache...

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

echo [2/5] Merging Godot Mod Loader and game class caches...

set "GAME_CACHE_ENV=%GAME_CACHE%"
set "MOD_CACHE_ENV=%MOD_CACHE%"
set "MERGED_CACHE_ENV=%MERGED_CACHE%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABFAHIAcgBvAHIAQQBjAHQAaQBvAG4AUAByAGUAZgBlAHIAZQBuAGMAZQAgAD0AIAAnAFMAdABvAHAAJwAKAAoAJABnAGEAbQBlACAAPQAgAEcAZQB0AC0AQwBvAG4AdABlAG4AdAAgAC0AUgBhAHcAIAAtAEwAaQB0AGUAcgBhAGwAUABhAHQAaAAgACQAZQBuAHYAOgBHAEEATQBFAF8AQwBBAEMASABFAF8ARQBOAFYACgAkAG0AbwBkACAAIAA9ACAARwBlAHQALQBDAG8AbgB0AGUAbgB0ACAALQBSAGEAdwAgAC0ATABpAHQAZQByAGEAbABQAGEAdABoACAAJABlAG4AdgA6AE0ATwBEAF8AQwBBAEMASABFAF8ARQBOAFYACgAKACMAIABEAG8AIABuAG8AdAAgAGQAZQBwAGUAbgBkACAAbwBuACAAdABoAGUAIABlAHgAYQBjAHQAIAB0AG8AcAAtAGwAZQB2AGUAbAAgACIAbABpAHMAdAA9AC4ALgAuACIAIABzAHkAbgB0AGEAeAAuAAoAIwAgAEcAbwBkAG8AdAAvAEcATQBMACAAZABlAHYAIAB2AGUAcgBzAGkAbwBuAHMAIABtAGEAeQAgAHcAcgBhAHAAIAB0AGgAZQAgAGEAcgByAGEAeQAgAGQAaQBmAGYAZQByAGUAbgB0AGwAeQAuAAoAIwAgAEkAbgBzAHQAZQBhAGQALAAgAGUAeAB0AHIAYQBjAHQAIABlAHYAZQByAHkAIABkAGkAYwB0AGkAbwBuAGEAcgB5AC0AbABpAGsAZQAgAGMAbABhAHMAcwAgAGUAbgB0AHIAeQAgAGYAcgBvAG0AIAB0AGgAZQAgAGYAaQBsAGUAcwAuAAoAJABvAGIAagBSAHgAIAA9ACAAJwAoAD8AcwApAFwAewAuACoAPwBcAH0AJwAKAAoAZgB1AG4AYwB0AGkAbwBuACAARwBlAHQALQBDAGwAYQBzAHMATwBiAGoAZQBjAHQAcwAoAFsAcwB0AHIAaQBuAGcAXQAkAHQAZQB4AHQALAAgAFsAcwB0AHIAaQBuAGcAXQAkAGwAYQBiAGUAbAApACAAewAKACAAIAAgACAAJABvAGIAagBlAGMAdABzACAAPQAgAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAEMAbwBsAGwAZQBjAHQAaQBvAG4AcwAuAEcAZQBuAGUAcgBpAGMALgBMAGkAcwB0AFsAcwB0AHIAaQBuAGcAXQAKAAoAIAAgACAAIABmAG8AcgBlAGEAYwBoACAAKAAkAG0AYQB0AGMAaAAgAGkAbgAgAFsAcgBlAGcAZQB4AF0AOgA6AE0AYQB0AGMAaABlAHMAKAAkAHQAZQB4AHQALAAgACQAbwBiAGoAUgB4ACkAKQAgAHsACgAgACAAIAAgACAAIAAgACAAJABvAGIAagAgAD0AIAAkAG0AYQB0AGMAaAAuAFYAYQBsAHUAZQAKAAoAIAAgACAAIAAgACAAIAAgACMAIABPAG4AbAB5ACAAawBlAGUAcAAgAG8AYgBqAGUAYwB0AHMAIAB0AGgAYQB0ACAAbABvAG8AawAgAGwAaQBrAGUAIABnAGwAbwBiAGEAbAAgAGMAbABhAHMAcwAgAGMAYQBjAGgAZQAgAGUAbgB0AHIAaQBlAHMALgAKACAAIAAgACAAIAAgACAAIABpAGYAIAAoACQAbwBiAGoAIAAtAG0AYQB0AGMAaAAgACcAIgBjAGwAYQBzAHMAIgBcAHMAKgA6ACcAIAAtAGEAbgBkACAAJABvAGIAagAgAC0AbQBhAHQAYwBoACAAJwAiAHAAYQB0AGgAIgBcAHMAKgA6ACcAKQAgAHsACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAkAG8AYgBqAGUAYwB0AHMALgBBAGQAZAAoACQAbwBiAGoAKQAKACAAIAAgACAAIAAgACAAIAB9AAoAIAAgACAAIAB9AAoACgAgACAAIAAgAGkAZgAgACgAJABvAGIAagBlAGMAdABzAC4AQwBvAHUAbgB0ACAALQBlAHEAIAAwACkAIAB7AAoAIAAgACAAIAAgACAAIAAgAHQAaAByAG8AdwAgACIAQwBvAHUAbABkACAAbgBvAHQAIABmAGkAbgBkACAAYQBuAHkAIABnAGwAbwBiAGEAbAAgAGMAbABhAHMAcwAgAGUAbgB0AHIAaQBlAHMAIABpAG4AIAB0AGgAZQAgACQAbABhAGIAZQBsACAAYwBsAGEAcwBzACAAYwBhAGMAaABlAC4AIgAKACAAIAAgACAAfQAKAAoAIAAgACAAIAByAGUAdAB1AHIAbgAgACQAbwBiAGoAZQBjAHQAcwAKAH0ACgAKAGYAdQBuAGMAdABpAG8AbgAgAEcAZQB0AC0AQwBsAGEAcwBzAE4AYQBtAGUAKABbAHMAdAByAGkAbgBnAF0AJABvAGIAagBlAGMAdABUAGUAeAB0ACkAIAB7AAoAIAAgACAAIAAjACAASABhAG4AZABsAGUAcwAgAGIAbwB0AGgAOgAKACAAIAAgACAAIwAgACAAIAAiAGMAbABhAHMAcwAiADoAIAAmACIATQBvAGQATABvAGEAZABlAHIATABvAGcAIgAKACAAIAAgACAAIwAgAGEAbgBkACAAcABvAHQAZQBuAHQAaQBhAGwAIAB2AGEAcgBpAGEAbgB0AHMAIAB3AGkAdABoAG8AdQB0ACAAdABoAGUAIABTAHQAcgBpAG4AZwBOAGEAbQBlACAAYQBtAHAAZQByAHMAYQBuAGQALgAKACAAIAAgACAAJABtAGEAdABjAGgAIAA9ACAAWwByAGUAZwBlAHgAXQA6ADoATQBhAHQAYwBoACgAJABvAGIAagBlAGMAdABUAGUAeAB0ACwAIAAnACIAYwBsAGEAcwBzACIAXABzACoAOgBcAHMAKgAmAD8AIgAoAFsAXgAiAF0AKwApACIAJwApAAoAIAAgACAAIABpAGYAIAAoACQAbQBhAHQAYwBoAC4AUwB1AGMAYwBlAHMAcwApACAAewAKACAAIAAgACAAIAAgACAAIAByAGUAdAB1AHIAbgAgACQAbQBhAHQAYwBoAC4ARwByAG8AdQBwAHMAWwAxAF0ALgBWAGEAbAB1AGUACgAgACAAIAAgAH0ACgAgACAAIAAgAHIAZQB0AHUAcgBuACAAJwAnAAoAfQAKAAoAJABnAGEAbQBlAE8AYgBqAGUAYwB0AHMAIAA9ACAAQAAoAEcAZQB0AC0AQwBsAGEAcwBzAE8AYgBqAGUAYwB0AHMAIAAkAGcAYQBtAGUAIAAnAGcAYQBtAGUAJwApAAoAJABtAG8AZABPAGIAagBlAGMAdABzACAAIAA9ACAAQAAoAEcAZQB0AC0AQwBsAGEAcwBzAE8AYgBqAGUAYwB0AHMAIAAkAG0AbwBkACAAIAAnAE0AbwBkACAATABvAGEAZABlAHIAJwApAAoACgAkAG0AbwBkAE4AYQBtAGUAcwAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAJwBTAHkAcwB0AGUAbQAuAEMAbwBsAGwAZQBjAHQAaQBvAG4AcwAuAEcAZQBuAGUAcgBpAGMALgBIAGEAcwBoAFMAZQB0AFsAcwB0AHIAaQBuAGcAXQAnACAAKABbAFMAeQBzAHQAZQBtAC4AUwB0AHIAaQBuAGcAQwBvAG0AcABhAHIAZQByAF0AOgA6AE8AcgBkAGkAbgBhAGwAKQAKAGYAbwByAGUAYQBjAGgAIAAoACQAbwBiAGoAZQBjAHQAVABlAHgAdAAgAGkAbgAgACQAbQBvAGQATwBiAGoAZQBjAHQAcwApACAAewAKACAAIAAgACAAJABuAGEAbQBlACAAPQAgAEcAZQB0AC0AQwBsAGEAcwBzAE4AYQBtAGUAIAAkAG8AYgBqAGUAYwB0AFQAZQB4AHQACgAgACAAIAAgAGkAZgAgACgAJABuAGEAbQBlACkAIAB7AAoAIAAgACAAIAAgACAAIAAgAFsAdgBvAGkAZABdACQAbQBvAGQATgBhAG0AZQBzAC4AQQBkAGQAKAAkAG4AYQBtAGUAKQAKACAAIAAgACAAfQAKAH0ACgAKACMAIABLAGUAZQBwACAAZwBhAG0AZQAgAGMAbABhAHMAcwBlAHMAIAB1AG4AbABlAHMAcwAgAEcATQBMACAAcwB1AHAAcABsAGkAZQBzACAAYQAgAGMAbABhAHMAcwAgAHcAaQB0AGgAIAB0AGgAZQAgAHMAYQBtAGUAIABnAGwAbwBiAGEAbAAgAG4AYQBtAGUALgAKACQAawBlAHAAdABHAGEAbQBlACAAPQAgAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAEMAbwBsAGwAZQBjAHQAaQBvAG4AcwAuAEcAZQBuAGUAcgBpAGMALgBMAGkAcwB0AFsAcwB0AHIAaQBuAGcAXQAKAGYAbwByAGUAYQBjAGgAIAAoACQAbwBiAGoAZQBjAHQAVABlAHgAdAAgAGkAbgAgACQAZwBhAG0AZQBPAGIAagBlAGMAdABzACkAIAB7AAoAIAAgACAAIAAkAG4AYQBtAGUAIAA9ACAARwBlAHQALQBDAGwAYQBzAHMATgBhAG0AZQAgACQAbwBiAGoAZQBjAHQAVABlAHgAdAAKACAAIAAgACAAaQBmACAAKAAoAC0AbgBvAHQAIAAkAG4AYQBtAGUAKQAgAC0AbwByACAAKAAtAG4AbwB0ACAAJABtAG8AZABOAGEAbQBlAHMALgBDAG8AbgB0AGEAaQBuAHMAKAAkAG4AYQBtAGUAKQApACkAIAB7AAoAIAAgACAAIAAgACAAIAAgACQAawBlAHAAdABHAGEAbQBlAC4AQQBkAGQAKAAkAG8AYgBqAGUAYwB0AFQAZQB4AHQAKQAKACAAIAAgACAAfQAKAH0ACgAKACQAYQBsAGwAIAA9ACAAQAAoACkACgAkAGEAbABsACAAKwA9ACAAJABtAG8AZABPAGIAagBlAGMAdABzAAoAJABhAGwAbAAgACsAPQAgACQAawBlAHAAdABHAGEAbQBlAAoACgBpAGYAIAAoACQAYQBsAGwALgBDAG8AdQBuAHQAIAAtAGUAcQAgADAAKQAgAHsACgAgACAAIAAgAHQAaAByAG8AdwAgACcATQBlAHIAZwBlAGQAIABjAGwAYQBzAHMAIABjAGEAYwBoAGUAIAB3AG8AdQBsAGQAIABiAGUAIABlAG0AcAB0AHkALgAnAAoAfQAKAAoAIwAgAFQAaABlACAAZwBhAG0AZQAgAGEAbAByAGUAYQBkAHkAIABwAHIAbwB2AGUAZAAgAGkAdAAgAGEAYwBjAGUAcAB0AHMAIAB0AGgAZQAgAHMAdABhAG4AZABhAHIAZAAgAEcAbwBkAG8AdAAgAGMAYQBjAGgAZQAgAHcAcgBhAHAAcABlAHIALgAKACMAIABQAHIAZQBzAGUAcgB2AGUAIAB0AGgAZQAgAGMAbABhAHMAcwAtAGUAbgB0AHIAeQAgAGQAaQBjAHQAaQBvAG4AYQByAGkAZQBzACAAZgByAG8AbQAgAHQAaABlACAAYwB1AHIAcgBlAG4AdAAgAEcATQBMACAAZABlAHYAIABjAGEAYwBoAGUACgAjACAAdgBlAHIAYgBhAHQAaQBtADsAIABvAG4AbAB5ACAAcgBlAGIAdQBpAGwAZAAgAHQAaABlACAAbwB1AHQAZQByACAAbABpAHMAdAAgAGMAbwBuAHQAYQBpAG4AZQByAC4ACgAkAG4AZQB3AEwAaQBuAGUAIAA9ACAAWwBFAG4AdgBpAHIAbwBuAG0AZQBuAHQAXQA6ADoATgBlAHcATABpAG4AZQAKACQAbwB1AHQAcAB1AHQAIAA9ACAAJwBsAGkAcwB0AD0AWwAnACAAKwAgACQAbgBlAHcATABpAG4AZQAgACsAIAAoACQAYQBsAGwAIAAtAGoAbwBpAG4AIAAoACcALAAnACAAKwAgACQAbgBlAHcATABpAG4AZQApACkAIAArACAAJABuAGUAdwBMAGkAbgBlACAAKwAgACcAXQAnAAoACgAkAHUAdABmADgAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAFUAVABGADgARQBuAGMAbwBkAGkAbgBnACgAJABmAGEAbABzAGUAKQAKAFsAUwB5AHMAdABlAG0ALgBJAE8ALgBGAGkAbABlAF0AOgA6AFcAcgBpAHQAZQBBAGwAbABUAGUAeAB0ACgAJABlAG4AdgA6AE0ARQBSAEcARQBEAF8AQwBBAEMASABFAF8ARQBOAFYALAAgACQAbwB1AHQAcAB1AHQALAAgACQAdQB0AGYAOAApAAoACgBXAHIAaQB0AGUALQBIAG8AcwB0ACAAKAAnACAAIAAgACAAIAAgAE0AbwBkACAATABvAGEAZABlAHIAIABjAGwAYQBzAHMAZQBzADoAIAAnACAAKwAgACQAbQBvAGQATwBiAGoAZQBjAHQAcwAuAEMAbwB1AG4AdAApAAoAVwByAGkAdABlAC0ASABvAHMAdAAgACgAJwAgACAAIAAgACAAIABHAGEAbQBlACAAYwBsAGEAcwBzAGUAcwAgAGsAZQBwAHQAOgAgACAAIAAnACAAKwAgACQAawBlAHAAdABHAGEAbQBlAC4AQwBvAHUAbgB0ACkACgBXAHIAaQB0AGUALQBIAG8AcwB0ACAAKAAnACAAIAAgACAAIAAgAFQAbwB0AGEAbAAgAGMAbABhAHMAcwBlAHMAOgAgACAAIAAgACAAIAAgACcAIAArACAAJABhAGwAbAAuAEMAbwB1AG4AdAApAAoA

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

echo [3/5] Creating backup...

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

echo [4/5] Patching Hearth and Hamlet.pck...

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

rem ---- Finalize Mod Loader setup -------------------------------

echo [5/5] Finalizing Mod Loader setup...

if not exist "%CD%\override.cfg" (
    >"%CD%\override.cfg" (
        echo [autoload_prepend]
        echo.
        echo ModLoader="*res://addons/mod_loader/mod_loader.gd"
        echo ModLoaderStore="*res://addons/mod_loader/mod_loader_store.gd"
    )

    if errorlevel 1 (
        echo.
        echo [ERROR] Could not create override.cfg.
        goto :fail
    )

    echo       Created: "%CD%\override.cfg"
) else (
    echo       override.cfg already exists - leaving it unchanged.

    findstr /C:"ModLoader=" "%CD%\override.cfg" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [WARNING] The existing override.cfg does not appear to contain
        echo the Godot Mod Loader autoload entries.
        echo.
        echo Expected:
        echo [autoload_prepend]
        echo ModLoader="*res://addons/mod_loader/mod_loader.gd"
        echo ModLoaderStore="*res://addons/mod_loader/mod_loader_store.gd"
        echo.
        echo The installer will continue without overwriting your file.
        echo.
    )
)

echo.

rem ---- Create mods folder --------------------------------------

echo       Setting up mods folder...

if not exist "%CD%\mods" (
    mkdir "%CD%\mods" >nul 2>&1

    if errorlevel 1 (
        echo.
        echo [ERROR] Could not create the mods folder.
        goto :fail
    )

    echo       Created: "%CD%\mods"
) else (
    echo       Mods folder already exists.
)

echo.

rem ---- Done ----------------------------------------------------

rmdir /s /q "%WORK_DIR%" >nul 2>&1

echo.
echo ============================================================
echo  SUCCESS
echo ============================================================
echo.
echo Godot Mod Loader setup completed:
echo   - override.cfg is present
echo   - mods folder is present
echo   - Hearth and Hamlet.pck contains the combined global class cache
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
