# Installer PGM sous Linux

**Télécharge [PGM-Installer-Linux-0.1.0-beta.7.bin](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Linux-0.1.0-beta.7.bin).** Il contient l’assistant et son environnement : aucun Python à installer. Alternative : extraire [l’archive .tar.gz](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Linux-0.1.0-beta.7.tar.gz), puis ouvrir PGM-Installer.

Ce guide concerne Linux natif x86-64, avec glibc 2.35 ou plus récente, et Dwarf Fortress 53.17 avec DFHack 53.17-r1. La version Windows du jeu sous Proton suit un autre parcours.

L’assistant5 est en anglais : les noms des boutons ci-dessous correspondent à son interface. Le contenu de traduction reste en bêta19.

1. Installe le jeu et DFHack sur Steam. Lance le jeu une fois avec DFHack, puis ferme-le.
2. Abonne-toi à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et, pour le pack, à la [collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attends la fin des téléchargements.
3. Dans les propriétés du fichier .bin téléchargé, autorise son exécution, puis ouvre-le. Ne le lance pas comme administrateur.
4. Vérifie le dossier du jeu proposé. Pour le retrouver : Steam → Dwarf Fortress → Gérer → Parcourir les fichiers locaux.
5. Pour le pack, utilise **Prepare modpack variants**, puis **Install modpack presets**. Si des sources manquent, vérifie les abonnements et le dossier Workshop indiqué dans l’assistant.
6. Pour la traduction, jeu fermé, utilise **Check files**, puis **Install / update**. Choisis DF-FR ou la traduction native PGM si une autre traduction est présente : la native PGM est refusée lorsque DF-FR est détecté. Le contenu Linux embarqué est la version 0.1.0-beta.19. Les fichiers précédents sont sauvegardés.
7. Lance le jeu avec DFHack. Avant de créer un monde, ouvre `gui/mod-manager`, applique **Normal (74 mods)** ou **PGM Full (87 mods)**, puis vérifie qu’aucune dépendance ne manque. L’abonnement seul n’applique pas le preset.
8. En forteresse, lance `traducfr-quetes` depuis le lanceur DFHack. Choisis le français, puis **Aisé** ou **Gloire**. F12 bascule la traduction native FR/EN.

Pour les quêtes seules, le pack et ses presets sont facultatifs : active PGM lors de la création du monde. Les variantes Born Normally et Accurate Domestic Animals sont préparées depuis tes abonnements d’origine ; elles ne demandent pas de téléchargement séparé. Full comprend Advanced Agriculture, Orchards et Fantastic Trees. Les presets personnels ne sont pas distribués ; l’assistant conserve ceux déjà présents et signale les conflits de nom.

## Mise à jour ou retour en arrière

Ferme toujours le jeu. Conserve les sauvegardes de l’installation. Pour actualiser la traduction, ouvre le nouvel assistant, sélectionne le même dossier du jeu et clique sur **Install / update**. L’ancien exécutable n’est pas nécessaire : la migration conserve une sauvegarde et remplace le contenu par étapes protégées. Si des fichiers gérés ont été modifiés personnellement, l’opération est refusée pour permettre leur vérification. Après une coupure de courant, conserve l’état et le rapport : une restauration assistée peut être nécessaire. Pour remplacer des presets différents, restaure d’abord les précédents, puis réinstalle-les. Steam met à jour les mods Workshop ; télécharger un nouvel assistant ne met pas automatiquement à jour le dictionnaire installé.

Pour retirer la traduction, utilise **Remove translation**. Pour les presets, utilise **Restore previous presets**. En cas de problème, **Save report** conserve les messages localement ; rien n’est envoyé automatiquement.

La bêta couvre un démarrage isolé Linux et des essais ciblés. Une partie complète et tous les écrans rares ne sont pas validés. [Retour au choix Windows/Linux](../README.md).

## Navigation de carte facultative

L’interface de l’assistant5 est en anglais. Ouvre **World map navigation…**, puis **Check before install**. Jeu fermé, choisis **Install navigation**. Ouvre une carte du monde, puis lance `gui/worldmap-zoom` dans DFHack : molette pour zoomer, bouton milieu pour déplacer la vue, sélection gauche conservée. L bascule les commandes compactes FR/EN. **Restore previous files** restaure les fichiers de navigation précédents. Cette option est indépendante de la traduction et des presets.

Sous Windows, coche **Enable experimental Windows navigation (tested under Proton only)** avant l’installation ; la restauration ne demande pas cette activation. Les gestes forteresse/embarquement Linux et la navigation forteresse sous Proton ont passé des tests ciblés. Windows natif en partie et l’embarquement Windows restent non testés. L’ouverture native de l’assistant ne valide pas une partie native. Une version du jeu/DFHack inconnue est refusée.

## Optional Windows-only mods / Mods Windows facultatifs

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate Windows-only options, following their authors’ current Workshop instructions. Do not subscribe to these two on Linux: their scripts can load independently of Normal/Full presets. Their DLLs are not bundled with PGM, and combined use with map navigation is unverified. Neither is added to the Linux presets or required by the main collection.

Dwarf Walking et Dwarf Actions sont des options Windows séparées, selon les instructions actuelles de leurs auteurs sur les pages liées. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger indépendamment des presets. Leurs DLL ne sont pas redistribuées ; leur cohabitation avec la navigation reste à valider. Ils ne sont ni ajoutés aux presets Linux ni requis par la collection principale.

