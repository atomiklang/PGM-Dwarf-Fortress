# PGM installer — English development candidate

Installer 0.1.0-beta.5, content 0.1.0-beta.19. This candidate has not been published. The released beta.4 installers remain unchanged.

## Install or update

1. Install Dwarf Fortress 53.17 and DFHack 53.17-r1 through Steam. Launch the game with DFHack once, then close it.
2. Open the installer for your operating system using your normal account. Do not use sudo.
3. Select the Dwarf Fortress folder. Set the DFHack folder if it is not detected automatically.
4. Choose the features you need. The French translation is optional; it does not change this installer's English interface.
5. For the modpack, subscribe to its Workshop collection, prepare the variants, then install the presets. Steam manages the Workshop downloads.

Linux: use Check files, then Install / update for the native French translation. Windows: enable the experimental translation checkbox before installing it. Its existing payload was tested under Proton; native Windows gameplay remains unverified. Restore actions preserve previous files and reject unexpected local edits.

## Optional world map navigation

Open World map navigation. Choose Check before install, then Install navigation with the game closed. It manages only its own scripts and DFHack plugin, independently of the translation and presets. The exact tested game/DFHack runtime hashes are required; an unknown build is refused.

Open a high-level world map in the game, then run `gui/worldmap-zoom` from DFHack's launcher. Mouse wheel zooms, middle-button drag pans, and normal left-click selection remains enabled. The compact controls switch between French and English with L. Restore previous files removes this optional feature and restores known previous bytes.

Linux fortress and embark gesture tests passed. Windows fortress navigation passed 190 checks under Proton/Direct3D, including resize and shutdown. Native Windows gameplay and Windows embark navigation have not been tested. The Windows option requires explicit experimental opt-in.

## Updates and reports

Use Check for updates, download the verified package, close this installer and open the new one. Select the same game folder and install the desired features. Downloading alone changes no game files. Save report records operation messages.

This is a local candidate, not a new public release. Source/UI tests, bundled-file checks and per-system executable checks must be recorded before publication. No saves are modified by the installer. Read the feature's validation records before making broader compatibility claims.
