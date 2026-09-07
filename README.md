<div align="center">

# Hearth and Hamlet - Godot Mod Loader

<img alt="Godot Modding Logo" src="icon.png" width="256" />

</div>

<br />

An easy-to-install setup for adding **Godot Mod Loader** support to **Hearth and Hamlet**.

This repository includes the required Godot Mod Loader files and an installer that patches the game's PCK with the required global class cache.

## Installation

1. Open your **Hearth and Hamlet** installation folder.

   In Steam:

   **Library → Hearth and Hamlet → Manage → Browse local files**

   The default location is usually:

   ```text
   C:\Program Files (x86)\Steam\steamapps\common\Hearth and Hamlet
   ```

2. Download this repository or the latest release.

3. Extract the contents directly into the **Hearth and Hamlet** folder.

   Your game folder should contain files similar to:

   ```text
   Hearth and Hamlet/
   ├── Hearth and Hamlet.exe
   ├── Hearth and Hamlet.pck
   ├── Install GML.bat
   └── addons/
       └── mod_loader/
   ```

4. Run:

   ```text
   Install GML.bat
   ```

5. Wait for the installer to report:

   ```text
   SUCCESS
   ```

6. Start **Hearth and Hamlet** normally through Steam.

## What the installer does

The installer automatically:

- Extracts the game's current global script class cache.
- Merges it with Godot Mod Loader's class cache.
- Creates a timestamped backup of `Hearth and Hamlet.pck`.
- Patches the merged cache into the game's PCK.
- Creates `override.cfg` with the required Godot Mod Loader autoloads.
- Creates a `mods` folder.

The `override.cfg` and `mods` folder are only created after the PCK patch completes successfully.

## Installing Mods

After installing Godot Mod Loader, place compatible mod ZIP files inside:

```text
Hearth and Hamlet\mods\
```

For example:

```text
Hearth and Hamlet/
└── mods/
    └── Rakibei-ToggleHarvest.zip
```

Then launch the game normally.

## Updating Hearth and Hamlet

A game update may replace `Hearth and Hamlet.pck`.

If that happens, run:

```text
Install GML.bat
```

again so the installer can extract the new game's class cache and patch Godot Mod Loader back into it.

Because the class caches are merged during installation, the installer uses the classes from the currently installed version of the game rather than relying on a pre-generated merged cache.

## Backup

Before modifying the PCK, the installer creates a backup similar to:

```text
Hearth and Hamlet.pck.backup-[Date]-[Time]
```

Keep this file if you want an easy way to restore the unpatched PCK.

## Uninstalling

To remove Godot Mod Loader:

1. Close the game.
2. Delete `override.cfg`.
3. Delete the `mods` folder if you no longer need your installed mods.
4. Delete the added `addons` folder.
5. Restore one of the installer-created PCK backups by renaming it to:

   ```text
   Hearth and Hamlet.pck
   ```

Alternatively, use Steam's **Verify integrity of game files** option to restore the original game files.

## Notes

- The installer must be run from the **Hearth and Hamlet** installation folder.
- Make sure the game is closed before running the installer.
- Godot Mod Loader is not officially built into Hearth and Hamlet; this repository provides the files and patching required to load it.
