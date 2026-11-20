# Installer PGM sous Windows

**Télécharge [PGM-Installer-Windows-0.1.0-beta.4.exe](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.4/PGM-Installer-Windows-0.1.0-beta.4.exe), puis ouvre-le.** Aucun Python à installer. Parcours prévu pour Windows 64 bits, Dwarf Fortress 53.17 et DFHack 53.17-r1.

1. Installe Dwarf Fortress et DFHack sur Steam. Lance le jeu une fois avec DFHack, puis ferme-le.
2. Abonne-toi à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386) et, pour le pack, à la [collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attends la fin des téléchargements.
3. Ouvre l’assistant et vérifie le dossier du jeu. Pour le retrouver : Steam → Dwarf Fortress → Gérer → Parcourir les fichiers locaux.
4. Pour le pack, utilise **Préparer les variantes du pack**, puis **Installer les presets du pack**. L’assistant prépare les variantes Born Normally et Accurate Domestic Animals depuis leurs abonnements d’origine. Si des sources manquent, vérifie les téléchargements Steam et le dossier Workshop choisi.
5. Lance le jeu avec DFHack. Avant de créer un monde, ouvre `gui/mod-manager`, applique **Normal (74 mods)** ou **PGM Full (87 mods)** et vérifie les dépendances. Full comprend Advanced Agriculture, Orchards et Fantastic Trees.
6. En forteresse, lance `traducfr-quetes` depuis le lanceur DFHack. Choisis la langue, puis **Aisé** ou **Gloire**, indépendamment du preset.

Pour les quêtes seules, le pack est facultatif : DFHack et PGM activé dans le nouveau monde suffisent. Les presets personnels restent locaux ; l’assistant conserve ceux présents et signale les conflits de nom.

## Traduction française Windows expérimentale, facultative

Elle est **désactivée par défaut**. Jeu fermé, clique sur **Vérifier Windows**, puis coche **Activer la traduction Windows expérimentale (testée sous Proton, Windows natif non validé)** et clique sur **Installer Windows expérimental**. **Restaurer Windows** rétablit les fichiers précédents.

Le contenu19 a été testé sous Proton GE 11-12 : 1 418 cas ciblés, 4 000 appels concurrents, 609 infobulles et un widget de quêtes. Ce résultat ne valide pas Windows natif. Deux frontières d’affichage restent connues ; les paragraphes et couleurs natifs ainsi que la géométrie des écrans n’ont pas la parité Linux.

Sous Proton, le démarrage peut prendre environ 100 secondes. Patiente sans lancer plusieurs instances.

[DF-FR, par Zartuf](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224), reste un choix Windows facultatif. Choisis **DF-FR ou la traduction native PGM** : l’assistant refuse d’installer cette dernière si DF-FR est détecté. Les quêtes et presets sont indépendants de ce choix. Leur compatibilité complète avec DF-FR en partie reste un objectif, pas une validation acquise.

## Mettre à jour ou demander de l’aide

Ferme le jeu avant toute modification et conserve l’ancien assistant ainsi que ses sauvegardes. Steam actualise les mods Workshop ; un nouvel assistant téléchargé doit ensuite être ouvert. Ne suppose pas qu’il a déjà remplacé la traduction installée.

**Restaurer les presets précédents** rétablit leur sauvegarde. Un fichier modifié depuis l’installation demande une vérification manuelle. Utilise **Enregistrer le rapport** en cas de problème : les messages restent locaux, sans envoi automatique.

[Retour au choix Windows/Linux](README.md) · [Notes et limites de la bêta](RELEASE-NOTES.md)
