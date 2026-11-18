# Installer PGM sous Windows

Ce guide couvre le mod, les quêtes et le modpack. Le hook natif PGM Windows est en développement. La traduction du jeu sous Windows utilise actuellement le parcours facultatif DF-FR.

## 1. Installer le jeu et DFHack

1. Installer Dwarf Fortress depuis Steam et le lancer une fois, puis le fermer.
2. Installer DFHack depuis Steam. Utiliser une version correspondant à celle du jeu. La configuration de référence de la bêta est Dwarf Fortress 53.17 avec DFHack 53.17-r1.
3. Vérifier que DFHack se charge au lancement du jeu et que son lanceur de commandes est accessible.

[DFHack sur Steam](https://store.steampowered.com/app/2346660/DFHack__Dwarf_Fortress_Modding_Engine/).

## 2. Installer PGM

S’abonner à PGM sur le Workshop et attendre la fin du téléchargement. Pour une nouvelle partie, sélectionner PGM dans les mods du monde. Les quêtes et les raccourcis nécessitent DFHack.

[PGM sur Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386).

Pour les quêtes seules, passer à l’étape 5. Pour le modpack, poursuivre avec l’étape 3.

## 3. Préparer le modpack et ses variantes locales

1. S’abonner aux éléments de la collection PGM et attendre la fin des téléchargements.
2. Télécharger `PGM-Installation-0.1.0-beta.3.zip` depuis la release GitHub, puis extraire tous ses fichiers dans un dossier facile à retrouver.
3. Installer Python 3.10 ou supérieur si nécessaire. Ouvrir un terminal dans le dossier extrait, où se trouve `preparer-variantes.py`.
4. Repérer la bibliothèque Steam où les mods Workshop de Dwarf Fortress ont été téléchargés. Le dossier attendu se termine par `steamapps\workshop\content\975370` et contient notamment `3635878659` et `3072627813`.
5. Exécuter la commande PowerShell suivante en remplaçant le premier chemin par le vôtre.

```powershell
py -3 .\preparer-variantes.py --workshop "D:\SteamLibrary\steamapps\workshop\content\975370" --mods "$env:APPDATA\Bay 12 Games\Dwarf Fortress\mods"
```

Si Python a été installé avec une commande `python` au lieu de `py`, remplacer `py -3` par `python`.

L’outil crée `born_normally_linux` et `pgm_accurate_domestic_graphics` à partir des originaux. Le nom interne `born_normally_linux` est conservé sur Windows pour correspondre aux presets. Les versions sources acceptées sont Born Normally 9 et Accurate Domestic Animals 105. En cas de version différente, une adaptation de l’outil est nécessaire.

Si une variante existe déjà avec un contenu différent, l’outil affiche son chemin et s’arrête. Conserver cette copie avant de la déplacer et de réessayer. Si la seconde variante échoue, la première peut déjà être installée. Relancer la même commande est possible.

[Collection Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587) · [Release GitHub](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/v0.1.0-beta.3) · [Python pour Windows](https://www.python.org/downloads/windows/).

## 4. Installer les presets et créer le monde

1. Depuis Steam, ouvrir les fichiers locaux de Dwarf Fortress. Le dossier du jeu contient `Dwarf Fortress.exe`.
2. Repérer `dfhack-config` dans ce dossier. S’il existe déjà un fichier `mod-manager.json`, en faire une copie. Sur une installation neuve, copier le fichier `presets\mod-manager.json` de l’archive dans `dfhack-config`.
3. Si des presets personnels existent, fusionner les entrées JSON avec celles du fichier fourni, ou conserver le fichier original à part avant d’essayer les presets PGM. Le fichier est une liste de presets.
4. Redémarrer le jeu. À la création du monde, ouvrir le gestionnaire de mods DFHack et choisir **Normal** ou **PGM Full**.
5. Contrôler la liste des dépendances manquantes avant de générer le monde. L’abonnement à la collection fournit les mods, et le preset détermine leur sélection et leur ordre.

Normal retire certains ajouts exigeants. PGM Full propose le pack complet et une difficulté plus élevée.

## 5. Ouvrir et vérifier les quêtes

En forteresse, saisir `traducfr-quetes` dans le lanceur DFHack. Choisir Aisé ou Gloire. Pour mettre le journal en français, utiliser `traducfr-quetes langue fr`.

Aisé apporte du matériel à certaines étapes. Gloire suit le même parcours avec des points et des rangs. Ce choix est indépendant du preset Normal ou Full.

Vérifier une première quête, sa validation, puis sauvegarder et recharger la partie pour contrôler le suivi. Si la commande est inconnue, vérifier le téléchargement de PGM, le chargement de DFHack et redémarrer le jeu.

La commande `pgm-traduction-mods activer` traduit une sélection de libellés de Military Reequip, Better Prepare Carefully et Better Combat Log pour la session. `pgm-traduction-mods desactiver` restaure l’affichage précédent. Les aides longues et tous les textes dynamiques ne sont pas encore couverts.

## 6. Facultatif, traduire le jeu avec DF-FR

S’abonner à DF-FR puis suivre le `LISEZMOI.txt` de sa version téléchargée.

Dans la version 1.2.2 utilisée pour le test, copier `dfhooks.dll` et le dossier `dffr` depuis DF-FR vers le dossier du jeu. Si DFHack y fournit déjà `dfhooks.dll`, le renommer en `dfhooks_chain.dll` avant d’installer celui de DF-FR. Conserver les fichiers précédents pour pouvoir revenir à la configuration initiale. Si une chaîne existe déjà, examiner la configuration avant de remplacer un fichier.

Pour la configuration testée, `dfhooks_dfhack.ini` contient `hack/dfhooks_dfhack.dll`. Au redémarrage, vérifier `dffr/dffr.log` et le chargement de DFHack.

Le démarrage de DF-FR 1.2.2 et DFHack 53.17-r1 a été confirmé sous GE-Proton11-12. Cela reste un essai de démarrage sous Linux avec Proton. L’utilisation complète de PGM avec DF-FR sur un Windows natif reste à tester.

[DF-FR, par Zartuf](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224).

## Si vous utilisez Proton sous Linux

Choisir soit le parcours Linux natif, soit le parcours Windows sous Proton. Pour ce dernier, le dossier utilisateur Windows est dans le préfixe du jeu, généralement `steamapps/compatdata/975370/pfx/drive_c/users/steamuser/AppData/Roaming/Bay 12 Games/Dwarf Fortress/`. Le script Python peut être lancé depuis Linux en lui donnant ce dossier `mods` comme destination. Utiliser les composants DFHack et DF-FR Windows avec le jeu Windows.
