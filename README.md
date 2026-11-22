# PGM [EN/FR] — Starter Quest Mods

Installer beta5 now uses an English interface. Translation and quest content remains beta19; the game’s optional French translation is a separate feature. Map navigation is optional and independent.

## English — choose your download

**85 quests in English and French** guide you from your first seven dwarves through survival, industry, trade, defense and the growth of your fortress. **DFHack is required.**

| Your system | Download | Guide |
| --- | --- | --- |
| Windows 64-bit | [PGM-Installer-Windows-0.1.0-beta.5.exe](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Windows-0.1.0-beta.5.exe) | [English guide](docs/INSTALL.en.md#windows) |
| Native Linux x86-64 | [PGM-Installer-Linux-0.1.0-beta.5.bin](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Linux-0.1.0-beta.5.bin) | [English guide](docs/INSTALL.en.md#linux) |

Linux alternative: [.tar.gz archive](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Linux-0.1.0-beta.5.tar.gz). Choose one Linux download; you do not need both. Python is included.

Install matching Dwarf Fortress and DFHack versions, subscribe to [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) and, for the modpack, the [collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Let Steam finish downloading, close the game, then open the assistant.

Choose **Normal (74 mods)** for an easier introduction or **PGM Full (87 mods)** for the complete, more demanding pack. Advanced Agriculture, Orchards and Fantastic Trees belong to Full. Choose the quest mode separately: **Assisted** provides supplies at selected milestones; **Glory** uses points and ranks. You can use the quests without the companion pack.

In fortress mode, open the DFHack launcher, run `traducfr-quetes` and choose your language. PGM also includes configurable interface improvements and optional French localization for the base game and companion mods. Translation aims to cover the whole game; procedural dialogue and rare screens can still contain English.

**Beta status:** Linux content is 0.1.0-beta.19. Windows translation is experimental, disabled by default and tested only under Proton GE 11-12. Native Windows play and Linux-equivalent rendering are not validated. Quests and presets remain independent of the optional translation. See [release notes](docs/RELEASE-NOTES.md).

## Français — choisir son téléchargement

PGM propose une **traduction française du jeu et des mods du pack**, avec **85 quêtes FR/EN** pour découvrir Dwarf Fortress. **DFHack est obligatoire.** La traduction vise l’ensemble du jeu ; la bêta ne garantit pas la traduction de tous les dialogues procéduraux ou écrans rares.

| Ton système | Télécharger | Installation |
| --- | --- | --- |
| Windows 64 bits | [Assistant Windows (.exe)](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Windows-0.1.0-beta.5.exe) | [Guide Windows](docs/INSTALL-WINDOWS.fr.md) |
| Linux natif x86-64 | [Assistant Linux (.bin)](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Linux-0.1.0-beta.5.bin) | [Guide Linux](docs/INSTALL-LINUX.fr.md) |

Alternative Linux : [archive .tar.gz](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.5/PGM-Installer-Linux-0.1.0-beta.5.tar.gz). Un seul téléchargement suffit. Aucun Python à installer.

Commence avec **Normal (74 mods)** ou choisis **PGM Full (87 mods)** pour tous les ajouts et une partie plus exigeante. Advanced Agriculture, Orchards et Fantastic Trees sont réservés à Full. Les modes de quêtes **Aisé** et **Gloire** se choisissent indépendamment du preset.

L’assistant5 est en anglais ; les quêtes FR/EN et la traduction du jeu restent indépendantes. Navigation facultative depuis **World map navigation…** : zoom à la molette, déplacement au bouton milieu. Windows reste expérimental sur activation explicite ; partie Windows native non validée.

### Pourquoi PGM ?

Je joue sous Linux. Sur de longues sessions, l’anglais de Dwarf Fortress me fatiguait et essayer de tout comprendre finissait par me donner mal au crâne. J’ai commencé une traduction pour mon installation, puis les quêtes et le pack ont grandi pour partager ce que j’apprenais et rendre les premières heures plus accessibles.

Merci à [DFint](https://github.com/dfint) et aux contributeurs français dont le travail a servi de base à ma traduction locale, à Zartuf pour [DF-FR](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224), à Trainzack pour les graphismes crédités et à tous les auteurs des mods. DF-FR est un choix Windows facultatif. Choisis DF-FR ou la traduction native PGM : l’assistant refuse cette dernière si DF-FR est détecté. Les quêtes et presets sont indépendants ; la compatibilité complète en partie reste à valider. La traduction Windows PGM est expérimentale, désactivée par défaut et testée sous Proton uniquement.

[Notes de version](docs/RELEASE-NOTES.md) · [Toutes les publications](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases)

## Optional world map navigation

Choose **World map navigation…**, then **Check before install**. With the game closed, choose **Install navigation**. Open a world map in the game and run `gui/worldmap-zoom` in DFHack: mouse wheel zooms, middle-button drag pans, and left-click selection stays enabled. The compact controls switch FR/EN with L. **Restore previous files** restores the previous navigation files. This feature manages its own scripts and plugin independently of translation and presets.

Windows requires **Enable experimental Windows navigation (tested under Proton only)** before installation; restoration needs no opt-in. Linux fortress/embark gestures and Proton Windows fortress navigation passed targeted tests. Native Windows gameplay and Windows embark navigation are untested. A native Windows installer smoke test does not validate native gameplay. Exact supported runtime hashes are required; an unknown build is refused.

## Optional Windows-only mods / Mods Windows facultatifs

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate Windows-only options, following their authors’ current Workshop instructions. Do not subscribe to these two on Linux: their scripts can load independently of Normal/Full presets. Their DLLs are not bundled with PGM, and combined use with map navigation is unverified. Neither is added to the Linux presets or required by the main collection.

Dwarf Walking et Dwarf Actions sont des options Windows séparées, selon les instructions actuelles de leurs auteurs sur les pages liées. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger indépendamment des presets. Leurs DLL ne sont pas redistribuées ; leur cohabitation avec la navigation reste à valider. Ils ne sont ni ajoutés aux presets Linux ni requis par la collection principale.

