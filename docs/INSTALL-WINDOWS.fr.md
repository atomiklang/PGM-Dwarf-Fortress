# Installer PGM sous Windows

**Télécharge [PGM-Installer-Windows-0.1.0-beta.7.exe](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.7/PGM-Installer-Windows-0.1.0-beta.7.exe), puis ouvre-le.** Aucun Python à installer. Parcours prévu pour Windows 64 bits, Dwarf Fortress 53.17 et DFHack 53.17-r1.

L’assistant5 est en anglais : les noms des boutons ci-dessous correspondent à son interface. Le contenu de traduction reste en bêta19.

1. Installe Dwarf Fortress et DFHack sur Steam. Lance le jeu une fois avec DFHack, puis ferme-le.
2. Abonne-toi à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et, pour le pack, à la [collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attends la fin des téléchargements.
3. Ouvre l’assistant et vérifie le dossier du jeu. Pour le retrouver : Steam → Dwarf Fortress → Gérer → Parcourir les fichiers locaux.
4. Pour le pack, utilise **Prepare modpack variants**, puis **Install modpack presets**. L’assistant prépare les variantes Born Normally et Accurate Domestic Animals depuis leurs abonnements d’origine. Si des sources manquent, vérifie les téléchargements Steam et le dossier Workshop choisi.
5. Lance le jeu avec DFHack. Avant de créer un monde, ouvre `gui/mod-manager`, applique **Normal (74 mods)** ou **PGM Full (87 mods)** et vérifie les dépendances. Full comprend Advanced Agriculture, Orchards et Fantastic Trees.
6. En forteresse, lance `traducfr-quetes` depuis le lanceur DFHack. Choisis la langue, puis **Aisé** ou **Gloire**, indépendamment du preset.

Pour les quêtes seules, le pack est facultatif : DFHack et PGM activé dans le nouveau monde suffisent. Les presets personnels restent locaux ; l’assistant conserve ceux présents et signale les conflits de nom.

## Traduction française Windows expérimentale, facultative

Elle est **désactivée par défaut**. Jeu fermé, clique sur **Check Windows files**, puis coche **Enable experimental Windows French translation (tested under Proton; native Windows gameplay unverified)** et clique sur **Install experimental translation**. **Restore Windows files** rétablit les fichiers précédents.

Le contenu19 a été testé sous Proton GE 11-12 : 1 418 cas ciblés, 4 000 appels concurrents, 609 infobulles et un widget de quêtes. Ce résultat ne valide pas Windows natif. Deux frontières d’affichage restent connues ; les paragraphes et couleurs natifs ainsi que la géométrie des écrans n’ont pas la parité Linux.

Sous Proton, le démarrage peut prendre environ 100 secondes. Patiente sans lancer plusieurs instances.

[DF-FR, par Zartuf](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224), reste un choix Windows facultatif. Choisis **DF-FR ou la traduction native PGM** : l’assistant refuse d’installer cette dernière si DF-FR est détecté. Les quêtes et presets sont indépendants de ce choix. Leur compatibilité complète avec DF-FR en partie reste un objectif, pas une validation acquise.

## Mettre à jour ou demander de l’aide

Ferme le jeu avant toute modification et conserve les sauvegardes de l’installation. Steam actualise les mods Workshop ; un nouvel assistant téléchargé doit ensuite être ouvert. Ne suppose pas qu’il a déjà remplacé la traduction installée.

**Restore previous presets** rétablit leur sauvegarde. Un fichier modifié depuis l’installation demande une vérification manuelle. Utilise **Save report** en cas de problème : les messages restent locaux, sans envoi automatique.

[Retour au choix Windows/Linux](../README.md) · [Notes et limites de la bêta](RELEASE-NOTES.md)

## Navigation de carte facultative

L’interface de l’assistant5 est en anglais. Ouvre **World map navigation…**, puis **Check before install**. Jeu fermé, choisis **Install navigation**. Ouvre une carte du monde, puis lance `gui/worldmap-zoom` dans DFHack : molette pour zoomer, bouton milieu pour déplacer la vue, sélection gauche conservée. L bascule les commandes compactes FR/EN. **Restore previous files** restaure les fichiers de navigation précédents. Cette option est indépendante de la traduction et des presets.

Sous Windows, coche **Enable experimental Windows navigation (tested under Proton only)** avant l’installation ; la restauration ne demande pas cette activation. Les gestes forteresse/embarquement Linux et la navigation forteresse sous Proton ont passé des tests ciblés. Windows natif en partie et l’embarquement Windows restent non testés. L’ouverture native de l’assistant ne valide pas une partie native. Une version du jeu/DFHack inconnue est refusée.

## Optional Windows-only mods / Mods Windows facultatifs

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate Windows-only options, following their authors’ current Workshop instructions. Do not subscribe to these two on Linux: their scripts can load independently of Normal/Full presets. Their DLLs are not bundled with PGM, and combined use with map navigation is unverified. Neither is added to the Linux presets or required by the main collection.

Dwarf Walking et Dwarf Actions sont des options Windows séparées, selon les instructions actuelles de leurs auteurs sur les pages liées. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger indépendamment des presets. Leurs DLL ne sont pas redistribuées ; leur cohabitation avec la navigation reste à valider. Ils ne sont ni ajoutés aux presets Linux ni requis par la collection principale.

