# Installer PGM sous Linux

**Télécharge [PGM-Installer-Linux-0.1.0-beta.4.bin](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.4/PGM-Installer-Linux-0.1.0-beta.4.bin).** Il contient l’assistant et son environnement : aucun Python à installer. Alternative : extraire [l’archive .tar.gz](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.4/PGM-Installer-Linux-0.1.0-beta.4.tar.gz), puis ouvrir PGM-Installer.

Ce guide concerne Linux natif x86-64, avec glibc 2.35 ou plus récente, et Dwarf Fortress 53.17 avec DFHack 53.17-r1. La version Windows du jeu sous Proton suit un autre parcours.

1. Installe le jeu et DFHack sur Steam. Lance le jeu une fois avec DFHack, puis ferme-le.
2. Abonne-toi à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et, pour le pack, à la [collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attends la fin des téléchargements.
3. Dans les propriétés du fichier .bin téléchargé, autorise son exécution, puis ouvre-le. Ne le lance pas comme administrateur.
4. Vérifie le dossier du jeu proposé. Pour le retrouver : Steam → Dwarf Fortress → Gérer → Parcourir les fichiers locaux.
5. Pour le pack, utilise **Préparer les variantes du pack**, puis **Installer les presets du pack**. Si des sources manquent, vérifie les abonnements et le dossier Workshop indiqué dans l’assistant.
6. Pour la traduction, jeu fermé, utilise **Vérifier**, puis **Installer / mettre à jour**. Choisis DF-FR ou la traduction native PGM si une autre traduction est présente : la native PGM est refusée lorsque DF-FR est détecté. Le contenu Linux embarqué est la version 0.1.0-beta.19. Les fichiers précédents sont sauvegardés.
7. Lance le jeu avec DFHack. Avant de créer un monde, ouvre `gui/mod-manager`, applique **Normal (74 mods)** ou **PGM Full (87 mods)**, puis vérifie qu’aucune dépendance ne manque. L’abonnement seul n’applique pas le preset.
8. En forteresse, lance `traducfr-quetes` depuis le lanceur DFHack. Choisis le français, puis **Aisé** ou **Gloire**. F12 bascule la traduction native FR/EN.

Pour les quêtes seules, le pack et ses presets sont facultatifs : active PGM lors de la création du monde. Les variantes Born Normally et Accurate Domestic Animals sont préparées depuis tes abonnements d’origine ; elles ne demandent pas de téléchargement séparé. Full comprend Advanced Agriculture, Orchards et Fantastic Trees. Les presets personnels ne sont pas distribués ; l’assistant conserve ceux déjà présents et signale les conflits de nom.

## Mise à jour ou retour en arrière

Ferme toujours le jeu. Conserve les sauvegardes de l’installation. Pour actualiser la traduction, ouvre le nouvel assistant, sélectionne le même dossier du jeu et clique sur **Installer / mettre à jour**. L’ancien exécutable n’est pas nécessaire : la migration conserve une sauvegarde et remplace le contenu par étapes protégées. Si des fichiers gérés ont été modifiés personnellement, l’opération est refusée pour permettre leur vérification. Après une coupure de courant, conserve l’état et le rapport : une restauration assistée peut être nécessaire. Pour remplacer des presets différents, restaure d’abord les précédents, puis réinstalle-les. Steam met à jour les mods Workshop ; télécharger un nouvel assistant ne met pas automatiquement à jour le dictionnaire installé.

Pour retirer la traduction, utilise **Désinstaller la traduction**. Pour les presets, utilise **Restaurer les presets précédents**. En cas de problème, **Enregistrer le rapport** conserve les messages localement ; rien n’est envoyé automatiquement.

La bêta couvre un démarrage isolé Linux et des essais ciblés. Une partie complète et tous les écrans rares ne sont pas validés. [Retour au choix Windows/Linux](README.md).
