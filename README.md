# PGM [EN/FR] — Starter Quest Mods

78 quests to help you learn Dwarf Fortress, with your expedition leader as a guide. **DFHack required.**

## Install PGM / Installer PGM

**Graphical installer beta — no Python or terminal needed / Installateur graphique bêta — sans Python ni terminal**

| System / Système | Download / Téléchargement | Tutorial / Tutoriel |
| --- | --- | --- |
| **Windows x64** | [**Download the Windows .exe**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.2/PGM-Installer-Windows-0.1.0-beta.2.exe) | [English](docs/INSTALL-WINDOWS-EN.md) · [Français](docs/INSTALL-WINDOWS.md) |
| **Linux x86-64** | [**Download the Linux archive**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.2/PGM-Installer-Linux-0.1.0-beta.2.tar.gz) | [English](docs/INSTALL-LINUX-EN.md) · [Français](docs/INSTALL-LINUX.md) |

**Windows:** open the .exe. **Linux:** extract the archive and open **PGM-Installer**. Python and the window toolkit are included. Linux requires glibc 2.35 or newer. Install Dwarf Fortress, matching DFHack and Workshop subscriptions through Steam first, then close the game.

**Windows :** ouvrir le .exe. **Linux :** extraire l’archive puis ouvrir **PGM-Installer**. Python et les composants graphiques sont inclus. Linux demande glibc 2.35 ou supérieure. Installer le jeu, DFHack correspondant et les abonnements Workshop via Steam, puis fermer le jeu avant de lancer l’installation.

The assistant prepares compatibility variants, installs/restores presets and handles the native Linux French translation. Windows game translation uses the optional DF-FR route in the guide. Native PGM Windows translation is not included. Updates currently download a verified new installer to open afterward; automatic dictionary updates are not implemented yet.

L’assistant prépare les variantes, installe/restaure les presets et gère la traduction Linux native. La traduction du jeu Windows passe par DF-FR suivant le guide. La recherche de mise à jour télécharge un nouvel installateur vérifié à ouvrir ensuite ; la mise à jour automatique du dictionnaire reste à développer.

[Installer release notes / Notes de l’installateur](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/installer-v0.1.0-beta.2) · [Sources](installer/README.md)

## English — start here

1. Install Dwarf Fortress and a matching version of [DFHack on Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).
2. Subscribe to [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) and the [PGM modpack collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Wait for Steam to finish downloading.
3. Download the graphical assistant from the table above. Prepare the local variants and install the presets using its buttons.
4. Before generating a world, open `gui/mod-manager` in DFHack and choose **Normal** or **PGM Full**. Check for missing dependencies.
5. In fortress mode, open `traducfr-quetes` in DFHack. Choose Assisted or Glory.

For quests alone, install DFHack, subscribe to PGM and open the journal in fortress mode. The assistant is useful for the companion modpack and optional translation.

## Français — commencer ici

1. Installer Dwarf Fortress et une version correspondante de [DFHack sur Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).
2. S’abonner à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et à la [collection du modpack](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attendre la fin des téléchargements.
3. Télécharger l’assistant Windows ou Linux dans le tableau ci-dessus. Préparer les variantes locales et installer les presets avec ses boutons.
4. Avant de générer le monde, ouvrir `gui/mod-manager` dans DFHack et choisir **Normal** ou **PGM Full**. Vérifier les dépendances manquantes.
5. En forteresse, ouvrir `traducfr-quetes` dans DFHack et choisir Aisé ou Gloire. La commande `traducfr-quetes langue fr` met le journal en français.

Pour les quêtes seules, DFHack et l’abonnement PGM suffisent. L’assistant sert au modpack et à la traduction facultative.

## Which asset do I need? / À quoi servent les fichiers ?

| File / Fichier | Purpose / Utilisation |
| --- | --- |
| **PGM-Installer-Windows…exe** | **Recommended Windows assistant / Assistant Windows conseillé.** |
| **PGM-Installer-Linux…tar.gz** | **Recommended Linux assistant / Assistant Linux conseillé.** |
| PGM-Installer-Linux…bin | Standalone Linux executable / Exécutable Linux seul. |
| PGM-Installation…zip | Common preparation files alone / Fichiers de préparation seuls, également intégrés à l’assistant. |
| PGM-Linux…zip | Native Linux translation alone / Traduction Linux seule, également intégrée à l’assistant Linux. |
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
