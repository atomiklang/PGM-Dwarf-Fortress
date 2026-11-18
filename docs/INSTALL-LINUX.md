# Installer PGM sous Linux

Ce guide couvre les quêtes et le modpack avec le jeu Linux natif. Le script de préparation des variantes a été testé sous Linux. Le complément de traduction natif est maintenant proposé dans une archive complète avec installateur et restauration.

## 1. Installer le jeu et DFHack

Installer Dwarf Fortress et DFHack depuis Steam dans des versions compatibles. La configuration de référence de la bêta est DF 53.17 avec DFHack 53.17-r1. Lancer une fois le jeu, vérifier que DFHack se charge, puis fermer le jeu.

[DFHack sur Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).

## 2. Installer PGM

S’abonner au mod PGM et attendre la fin du téléchargement Steam. Sélectionner PGM dans les mods lors de la création d’un nouveau monde.

Pour les quêtes seules, passer à l’étape 5. Pour jouer au modpack, poursuivre avec l’étape 3.

[PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386).

## 3. Télécharger les dépendances et créer les variantes

S’abonner aux éléments de la collection. Télécharger `PGM-Installation-0.1.0-beta.3.zip` depuis GitHub, puis l’extraire. Ouvrir un terminal dans le dossier extrait où se trouve `preparer-variantes.py`.

Vérifier que `python3 --version` fonctionne. Si Python est absent, installer Python 3.10 ou supérieur avec le gestionnaire de paquets de votre distribution.

L’exemple suivant correspond à une bibliothèque Steam classique. Remplacer le chemin Workshop si Steam ou les téléchargements du jeu se trouvent sur un autre disque.

```sh
python3 preparer-variantes.py \
  --workshop "$HOME/.local/share/Steam/steamapps/workshop/content/975370" \
  --mods "$HOME/.local/share/Bay 12 Games/Dwarf Fortress/mods"
```

Le dossier Workshop doit contenir `3635878659` et `3072627813`. Le script crée les variantes `born_normally_linux` et `pgm_accurate_domestic_graphics` à partir de Born Normally version 9 et Accurate Domestic Animals version 105.

Si une copie existante diffère, le script s’arrête et indique le chemin. Conserver cette copie avant de la déplacer puis de relancer. Chaque variante est préparée séparément. Si la seconde échoue, la première peut déjà être installée. La relance reconnaît les copies identiques.

Pour Steam Flatpak ou une bibliothèque déplacée, repérer les dossiers effectivement utilisés par votre installation. Le dossier utilisateur doit être celui où le jeu crée ses mods et ses sauvegardes. Vérifier ce chemin avant d’exécuter l’outil.

[Collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587) · [Téléchargements](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/v0.1.0-beta.3).

## 4. Appliquer les presets

Depuis Steam, ouvrir les fichiers locaux de Dwarf Fortress. Dans le dossier du jeu, repérer `dfhack-config`.

Faire une copie de `dfhack-config/mod-manager.json` s’il existe déjà. Sur une installation neuve, copier `presets/mod-manager.json` de l’archive à cet emplacement. Pour conserver des presets personnels actifs, fusionner les entrées des deux listes JSON.

Redémarrer le jeu. À la création du monde, ouvrir le gestionnaire de mods DFHack et appliquer **Normal** ou **PGM Full**. Contrôler les dépendances manquantes avant de générer le monde. Normal écarte certains ajouts exigeants. Full propose le pack complet et une difficulté accrue.

## 5. Tester le journal

En forteresse, ouvrir le lanceur DFHack et saisir `traducfr-quetes`. Choisir Aisé ou Gloire. Pour le français, saisir `traducfr-quetes langue fr`.

Vérifier l’ouverture du journal, la validation d’une première quête, puis sauvegarder et recharger pour contrôler le suivi. Si la commande est inconnue, vérifier que Steam a téléchargé PGM et que DFHack s’exécute, puis redémarrer.

Pour essayer une sélection de traductions des menus de mods, utiliser `pgm-traduction-mods activer`. Pour revenir à l’affichage précédent, utiliser `pgm-traduction-mods desactiver`. Ce réglage vaut pour la session. La couverture des textes reste partielle.

## 6. Installer la traduction native Linux

Télécharger `PGM-Linux-0.1.0-beta.3.zip` depuis la nouvelle release, puis extraire l’archive. Dans le dossier contenant `installer.py`, jeu fermé, lancer

```sh
python3 installer.py check --game "$HOME/.local/share/Steam/steamapps/common/Dwarf Fortress"
python3 installer.py install --game "$HOME/.local/share/Steam/steamapps/common/Dwarf Fortress"
```

Adapter le chemin à la bibliothèque Steam. Si DFHack est installé ailleurs, ajouter `--dfhack "/chemin/vers/DFHack"` aux deux commandes. Python 3.10 ou supérieur est nécessaire.

L’archive comprend le hook, le dictionnaire, les corrections, les modèles et les scripts de traduction DFHack. Le chargeur est celui de votre installation DFHack Linux. L’installateur vérifie les signatures du jeu, conserve les fichiers précédents et prépare le démarrage de la traduction des menus.

Après lancement via Steam avec DFHack, contrôler `traducfr/traducfr.log` et tester F12 pour basculer entre français et anglais. Pour restaurer la configuration précédente, fermer le jeu et utiliser

```sh
python3 installer.py uninstall --game "$HOME/.local/share/Steam/steamapps/common/Dwarf Fortress"
```

Conserver `.pgm-linux-install` dans le dossier du jeu. Il contient les sauvegardes et l’état nécessaire à la restauration. Si un fichier a changé depuis l’installation, l’outil indique le conflit avant de restaurer.

Le démarrage du vrai jeu Linux a été vérifié dans une copie isolée avec le Steam Linux Runtime. Le hook et le dictionnaire DFHack ont chargé, puis la désinstallation a restauré les fichiers précédents. Ce lancement hors du parcours Steam habituel a signalé l’absence d’identifiant Steam et une bibliothèque OpenGL manquante pour Stonesense. Le fonctionnement du Workshop, de Stonesense et une partie complète restent à valider. Le hook bêta 3 est reconstruit depuis la source jointe. Deux compilations ont produit le même binaire.

Les crédits et la provenance du corpus DFint sont fournis avec l’archive. Les conditions de redistribution du corpus restent à préciser avec ses mainteneurs.

[Télécharger le complément Linux](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/v0.1.0-beta.3).

## Windows sous Proton

Pour le jeu Windows sous Proton, suivre le [guide Windows](INSTALL-WINDOWS.md), notamment la section sur le préfixe Proton et les composants Windows. Le test de démarrage DF-FR + DFHack réalisé sous Proton ne valide pas une partie complète du pack.
