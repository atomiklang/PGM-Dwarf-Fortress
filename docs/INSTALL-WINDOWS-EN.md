# Install PGM on Windows

[Download the Windows player package](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/INSTALL-Windows-PGM-0.1.0-beta.3.zip).

Extract the whole ZIP and open `PGM-Windows/START-HERE.txt`. The archive includes the presets, compatibility generator and guides.

## Quick installation

1. Install Dwarf Fortress and matching DFHack through Steam. The beta reference is DF 53.17 with DFHack 53.17-r1.
2. Subscribe to PGM and the companion collection. Wait for Steam to finish downloading.
PGM: https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386
Collection: https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587
3. Install Python 3.10 or newer if needed. Close the game.
4. Generate the two compatibility variants using the command below. Replace the Workshop path if your Steam library is elsewhere.
Open PowerShell in this extracted folder. If py is unavailable, replace py -3 with python.

```powershell
py -3 .\preparer-variantes.py --workshop "C:\Program Files (x86)\Steam\steamapps\workshop\content\975370" --mods "$env:APPDATA\Bay 12 Games\Dwarf Fortress\mods"
```

5. In Steam, open Dwarf Fortress → Manage → Browse local files. Back up `dfhack-config/mod-manager.json` if it exists, then copy the supplied `presets/mod-manager.json` to that location. To retain personal presets, merge the two JSON lists instead of replacing the existing file.
6. Restart the game. Before creating a world, open `gui/mod-manager` from DFHack and apply **Normal** or **PGM Full**. Resolve missing dependencies before generating.
7. In fortress mode, run `traducfr-quetes` from DFHack and choose Assisted or Glory.

For quests alone, install DFHack, subscribe to PGM and open the journal in fortress mode. Variant generation and presets are required for the companion modpack.

## Optional French translation

Optional French base-game translation on Windows is provided through DF-FR. Follow the optional DF-FR section of the guide. The native PGM Windows translation hook is in development.

DF-FR installation and its DFHack chainloading setup are detailed in the [Windows guide](INSTALL-WINDOWS.md). Follow the README supplied with your downloaded DF-FR version. [DF-FR Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224).

## Beta validation

Linux installer and native hook startup were tested in an isolated game copy. Windows execution, native Windows interoperability with DF-FR and a complete playthrough remain to be validated. The package targets DF 53.17 with DFHack 53.17-r1.

[Detailed Windows guide in French](INSTALL-WINDOWS.md) · [Security review](../SECURITY-REVIEW.md).
