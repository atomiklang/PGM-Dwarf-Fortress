# PGM [EN/FR] — Starter Quest Mods

78 quests to help you learn Dwarf Fortress, with your expedition leader as a guide. **DFHack required.**

## Install PGM / Installer PGM

**Choose your system / Choisis ton système**

| System / Système | Download / Téléchargement | Tutorial / Tutoriel |
| --- | --- | --- |
| **Windows** | [**Download Windows setup ZIP**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/INSTALL-Windows-PGM-0.1.0-beta.3.zip) | [English](docs/INSTALL-WINDOWS-EN.md) · [Français](docs/INSTALL-WINDOWS.md) |
| **Linux** | [**Download Linux setup ZIP**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/INSTALL-Linux-PGM-0.1.0-beta.3.zip) | [English](docs/INSTALL-LINUX-EN.md) · [Français](docs/INSTALL-LINUX.md) |

**Extract the entire ZIP, then open `START-HERE.txt` in its folder.** Each player package includes the presets, compatibility tool and platform guide. The Linux package also includes the native French translation under `traduction-linux`. Windows base-game translation currently uses the optional DF-FR route described in its guide. The native PGM Windows translation hook is in development.

**Extrais entièrement le ZIP, puis ouvre `START-HERE.txt` dans son dossier.** Le paquet Windows contient les presets, l’outil de préparation et son tutoriel. Le paquet Linux contient aussi la traduction native française. Sous Windows, la traduction du jeu avec DF-FR est une étape facultative expliquée dans le tutoriel. L’installation demande actuellement Python 3.10 ou supérieur et quelques commandes guidées.

## English — start here

1. Install Dwarf Fortress and a matching version of [DFHack on Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).
2. Subscribe to [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) and the [PGM modpack collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Wait for Steam to finish downloading.
3. Download the setup ZIP for your system from the table above. Extract it and follow `START-HERE.txt` to prepare the two local compatibility variants and install the presets.
4. Before generating a world, open `gui/mod-manager` in DFHack and choose **Normal** or **PGM Full**. Check for missing dependencies.
5. In fortress mode, open `traducfr-quetes` in DFHack. Choose Assisted or Glory.

For quests alone, install DFHack, subscribe to PGM and open the journal in fortress mode. The setup ZIP is useful for the companion modpack and optional translation.

## Français — commencer ici

1. Installer Dwarf Fortress et une version correspondante de [DFHack sur Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).
2. S’abonner à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et à la [collection du modpack](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attendre la fin des téléchargements.
3. Télécharger le ZIP Windows ou Linux dans le tableau ci-dessus. L’extraire et suivre `START-HERE.txt` pour préparer les deux variantes locales et installer les presets.
4. Avant de générer le monde, ouvrir `gui/mod-manager` dans DFHack et choisir **Normal** ou **PGM Full**. Vérifier les dépendances manquantes.
5. En forteresse, ouvrir `traducfr-quetes` dans DFHack et choisir Aisé ou Gloire. La commande `traducfr-quetes langue fr` met le journal en français.

Pour les quêtes seules, DFHack et l’abonnement PGM suffisent. Le ZIP de préparation sert au modpack et à la traduction facultative.

## Which asset do I need? / À quoi servent les fichiers ?

| File / Fichier | Purpose / Utilisation |
| --- | --- |
| **INSTALL-Windows-PGM…zip** | **Player setup for Windows / Paquet joueur Windows.** Presets, compatibility tool and tutorials. |
| **INSTALL-Linux-PGM…zip** | **Player setup for Linux / Paquet joueur Linux.** Same preparation files, plus the complete native Linux translation. |
| PGM-Installation…zip | Common preparation files alone / Fichiers de préparation seuls, déjà présents dans les deux paquets joueurs. |
| PGM-Linux…zip | Native Linux translation alone / Traduction Linux seule, déjà présente dans le paquet joueur Linux. |
| PGM-Workshop…zip | Mod upload folder for the author and manual mod installation / Dossier de publication du mod pour l’auteur et installation manuelle. Steam subscribers receive the mod through Steam. |
| …SHA256SUMS.txt | Optional archive integrity checks / Empreintes permettant de vérifier les archives téléchargées. |
| Source code (zip / tar.gz) | GitHub repository snapshot for contributors / Copie automatique du dépôt pour les contributeurs. Use the player setup ZIP for installation. |

[All beta 3 assets / Tous les fichiers de la bêta 3](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/v0.1.0-beta.3).

## Beta status / État de la bêta

Reference configuration is DF 53.17 with DFHack 53.17-r1. Linux installation, native hook startup and restoration were tested in an isolated game copy. Windows execution and a complete playthrough remain to be validated. Assisted/Glory quest modes and Normal/Full modpack presets are independent choices.

La référence est DF 53.17 avec DFHack 53.17-r1. L’installation Linux, le démarrage du hook et la restauration ont été vérifiés dans une copie isolée du jeu. Les essais Windows et une partie complète restent à réaliser. Les modes Aisé/Gloire sont indépendants des presets Normal/Full.

Beta 3 supersedes the earlier installers and native hooks. [Security review / Rapport de sécurité](SECURITY-REVIEW.md).

## Credits / Crédits

Thanks to Zartuf for [DF-FR](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224), to [DFint](https://github.com/dfint) and its French translation contributors, to Trainzack for the credited interface artwork, and to the companion mod authors. Credits and provenance are included in the packages. DFint corpus redistribution terms remain to be clarified with its maintainers.
