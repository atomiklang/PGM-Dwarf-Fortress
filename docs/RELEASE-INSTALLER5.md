# PGM installer beta5

English interface, clearer updates, and optional world-map navigation independent of translation and modpack presets. Translation and quest content remains beta19. Previous releases remain available unchanged.

Download the .exe for Windows64 or the .bin/.tar.gz for native Linux x86-64 (glibc2.35+). Python is included. Close the game, open the new assistant and select the same game folder. Downloading alone does not replace installed translation files. Keep installation backups; changed personal files are protected.

Optional map navigation: open a world map, run `gui/worldmap-zoom`, use the wheel to zoom and the middle button to pan. Windows navigation and translation require explicit experimental opt-in. Windows assistant startup has been tested natively; Windows gameplay and Windows embark navigation have not. Linux fortress/embark gestures and Proton fortress navigation have targeted validation, not full game coverage.

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate optional Windows-only mods maintained by their Workshop authors. Use their current author instructions. Do not subscribe to these two on Linux: Workshop scripts can load independently of Normal/Full presets. Their DLLs are not bundled here, and joint operation with map navigation is unverified. The Linux modpack presets are unchanged.

Windows executable: promoted byte-for-byte from native CI45047022625, commit ff7727226958df4765cbc4e2ef52353ba57492b4. Linux executable: rebuilt from reviewed source and exact validated data on Ubuntu22.04, then opened and checked before publication. Verify downloaded assets against SHA256SUMS files.

## Français

Assistant désormais en anglais, mise à jour simplifiée et navigation de carte facultative, indépendante de la traduction et des presets. Le contenu de traduction/quêtes reste en bêta19. Les releases précédentes sont conservées.

Télécharge le .exe Windows64 ou le .bin/.tar.gz Linux natif x86-64 (glibc2.35+). Ferme le jeu, ouvre le nouvel assistant puis sélectionne le même dossier. Aucun Python requis. Le téléchargement seul ne met pas la traduction installée à jour. Conserve les sauvegardes d’installation.

Navigation : ouvre une carte du monde, lance `gui/worldmap-zoom`, zoome à la molette et déplace la vue au bouton milieu. Sous Windows, traduction et navigation restent expérimentales, à activer explicitement. L’ouverture native de l’assistant ne valide pas une partie Windows native ni l’embarquement Windows.

Dwarf Walking et Dwarf Actions restent des choix Windows séparés, selon les instructions actuelles de leurs auteurs sur les pages liées ci-dessus. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger sans sélection dans les presets. Leurs DLL ne sont pas redistribuées ; la cohabitation avec la navigation reste à valider. Les presets Linux sont inchangés.

Known interface limit: two rare update-validation errors (missing release checksum and invalid download filename) can still appear in French. The tested Windows executable is preserved unchanged.

Limite connue : deux erreurs rares de vérification des mises à jour (empreinte absente et nom de téléchargement invalide) restent en français. L’exécutable Windows testé est conservé sans modification.
