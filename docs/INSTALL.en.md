# Install PGM — choose your system

**DFHack is required.** Reference versions: Dwarf Fortress 53.17 and DFHack 53.17-r1. Subscribe to [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386); for the companion pack, also subscribe to the [collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Wait for Steam downloads to finish. Run the game once with DFHack, then close it.

The beta7 assistant interface is English. The game’s optional French translation and FR/EN quests are separate.

## Windows

Download and open [PGM-Installer-Windows-0.1.0-beta.7.exe](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Windows-0.1.0-beta.7.exe). Windows 64-bit; no separate Python installation needed.

Optional Windows translation is **experimental and disabled by default**. With the game closed, choose **Check Windows files**, enable **Enable experimental Windows French translation (tested under Proton; native Windows gameplay unverified)**, then choose **Install experimental translation**. Use **Restore Windows files** to restore previous files.

Content19 was tested under Proton GE 11-12: 1,418 targeted cases, 4,000 concurrent calls, 609 tooltips and a quest widget. Native Windows gameplay is not validated. Two display boundaries remain; native paragraphs, colours and screen geometry do not have Linux parity. Proton startup can take around 100 seconds: wait without launching multiple instances.

Choose either optional [DF-FR](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224) or native PGM translation. The assistant refuses native PGM installation when DF-FR is detected. Quests and presets are independent; complete compatibility in play remains to be validated.

## Linux

Download [PGM-Installer-Linux-0.1.0-beta.7.bin](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Linux-0.1.0-beta.7.bin), allow execution in its file properties and open it. Alternatively, extract the [.tar.gz archive](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Linux-0.1.0-beta.7.tar.gz) and open PGM-Installer. Choose one download. Python is included.

Native Linux x86-64 with glibc 2.35 or later is required. This route is for the native game, not Windows under Proton. Do not run the assistant as administrator. Optional French translation uses Linux content 0.1.0-beta.19: with the game closed, choose **Check files**, then **Install / update**. F12 switches FR/EN in game.

## Prepare the pack and start playing

1. Check the game folder selected by the assistant. Steam → Dwarf Fortress → Manage → Browse local files shows its location.
2. For the pack, prepare the compatibility variants, then install the pack presets. The assistant uses your original Born Normally and Accurate Domestic Animals Workshop downloads. If sources are missing, check subscriptions and the selected Workshop folder.
3. Start the game with DFHack. Before creating a world, open `gui/mod-manager` and apply **Normal (74 mods)** or **PGM Full (87 mods)**. Resolve missing dependencies before continuing. Subscribing alone does not apply a preset.
4. In fortress mode, open the DFHack launcher, run `traducfr-quetes` and select English. Choose **Assisted** for supplies at selected milestones or **Glory** for points and ranks. Quest mode is independent of the pack preset.

Normal is the easier introduction; Full contains the complete pack, including Advanced Agriculture, Orchards and Fantastic Trees. For quests alone, the companion pack is optional: enable PGM in the new world. Personal presets remain local and are preserved; name conflicts are reported.

## Updates and recovery

Close the game before changes. Keep installation backups. Steam updates Workshop mods. Downloading a new assistant does not automatically replace the running application or installed translation dictionary. To update Linux translation, open the new assistant, select the same game folder and choose **Install / update**. The old executable is not needed. Transactional migration retains a backup and refuses personally modified managed files for review. After a power failure, preserve installation state and the report; assisted recovery may be required. For different presets, restore the previous presets first, then reinstall.

Use the assistant’s restore actions for translation or presets, and save its report if something goes wrong. Reports stay local unless you choose to share them. Targeted tests and an isolated Linux startup do not constitute a complete playthrough. [Release notes](RELEASE-NOTES.md) · [French guides](../README.md#français--choisir-son-téléchargement).

## Optional world map navigation

Choose **World map navigation…**, then **Check before install**. With the game closed, choose **Install navigation**. Open a world map in the game and run `gui/worldmap-zoom` in DFHack: mouse wheel zooms, middle-button drag pans, and left-click selection stays enabled. The compact controls switch FR/EN with L. **Restore previous files** restores the previous navigation files. This feature manages its own scripts and plugin independently of translation and presets.

Windows requires **Enable experimental Windows navigation (tested under Proton only)** before installation; restoration needs no opt-in. Linux fortress/embark gestures and Proton Windows fortress navigation passed targeted tests. Native Windows gameplay and Windows embark navigation are untested. A native Windows installer smoke test does not validate native gameplay. Exact supported runtime hashes are required; an unknown build is refused.

## Optional Windows-only mods / Mods Windows facultatifs

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate Windows-only options, following their authors’ current Workshop instructions. Do not subscribe to these two on Linux: their scripts can load independently of Normal/Full presets. Their DLLs are not bundled with PGM, and combined use with map navigation is unverified. Neither is added to the Linux presets or required by the main collection.

Dwarf Walking et Dwarf Actions sont des options Windows séparées, selon les instructions actuelles de leurs auteurs sur les pages liées. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger indépendamment des presets. Leurs DLL ne sont pas redistribuées ; leur cohabitation avec la navigation reste à valider. Ils ne sont ni ajoutés aux presets Linux ni requis par la collection principale.

