# Install PGM on Linux

[**Download the graphical installer**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.2/PGM-Installer-Linux-0.1.0-beta.2.tar.gz)

Download the Linux archive, extract it and open **PGM-Installer**. Enable execution in the file properties if your desktop requires it.

Python and Tkinter are included: no terminal commands are needed for the graphical setup. The interface is currently in French. Windows x64 and native Linux x86-64 are supported targets; Linux requires glibc 2.35 or newer. This beta has automated GUI startup tests on Windows and Ubuntu 22.04; complete gameplay remains to be tested.

## Before opening the assistant

1. Install Dwarf Fortress **53.17** and matching **DFHack 53.17-r1** on Steam. Launch the game once with DFHack, then close it.
2. Subscribe to [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386). For the companion modpack, also subscribe to the [PGM collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Wait for downloads to finish.
3. In Steam, use Dwarf Fortress → Manage → Browse local files to locate the game directory.

## Prepare the modpack

1. Open the assistant and select the game directory if it was not detected. Use the DFHack field if the Linux loader cannot be found automatically.
2. For the companion modpack, click **Préparer les variantes du pack**. If Steam stores Workshop files in another library, select the directory ending in `steamapps/workshop/content/975370` in the Workshop field.
3. The default local mods folder is `%APPDATA%/Bay 12 Games/Dwarf Fortress/mods` on Windows and `$XDG_DATA_HOME/Bay 12 Games/Dwarf Fortress/mods` on Linux, with `~/.local/share` as the usual Linux data directory. You can choose another local mods folder explicitly.
4. Click **Installer les presets du pack**. Personal presets are retained. If a personal preset already uses the name Normal or PGM Full with different contents, installation stops without replacing it. Resolve that name conflict before retrying.
5. Start the game with DFHack. Before world generation, open `gui/mod-manager`, select **Normal** or **PGM Full** and check missing dependencies. Normal disables some demanding additions; Full includes the harder content.

The two generated variants are based on your subscribed copies of Born Normally **9** and Accurate Domestic Animals **105**. A changed upstream version requires reviewing the adaptation. A pre-existing different local copy is preserved, and the assistant stops with its path. The original Workshop files are never modified.

## Quests

For quests alone, DFHack and the PGM subscription are sufficient; variants and presets are for the companion modpack. Select PGM for the new world, then open `traducfr-quetes` in fortress mode. Choose Assisted or Glory. `traducfr-quetes langue fr` switches the journal to French.

`pgm-traduction-mods activer` enables the available translations for selected DFHack mod labels for the current session. `pgm-traduction-mods desactiver` disables that layer. Long help and all dynamic text are not fully covered.

## Optional native Linux French translation

With the game closed, click **Vérifier**, then **Installer la traduction**. The assistant checks the exact supported executable and the packaged files before changing anything. Existing files are backed up. F12 switches French/English in game. To remove the translation, close the game and click **Désinstaller la traduction** in the same assistant.

Use this route with the native Linux game, not the Windows game under Proton. An existing different translation hook requires manual review; the assistant stops rather than replacing it.

## Restore and update

**Restaurer les presets précédents** restores the preset file saved before installation. **Désinstaller la traduction** restores the native Linux translation files. A file edited since installation is preserved, and the assistant asks for manual review.

**Chercher une mise à jour** checks published installer versions. **Télécharger la mise à jour** downloads a verified executable; open the download folder and launch the new version afterward. **Automatic replacement of the application and automatic dictionary updates are not implemented in this beta.** Before changing the Linux translation, restore the old installation, then install with the new assistant, keeping the previous executable available until validation. Steam continues to update Workshop items.

## Help

Use **Enregistrer le rapport** to save local messages. No report is sent automatically. Close the game before any change, do not run the Linux assistant with sudo, and retain backups. If interrupted, keep the report and installation state before retrying or manually removing any lock file.

[Installer release notes](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/installer-v0.1.0-beta.2) · [Manual preparation files](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/PGM-Installation-0.1.0-beta.3.zip) · [Native Linux manual package](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/PGM-Linux-0.1.0-beta.3.zip)
