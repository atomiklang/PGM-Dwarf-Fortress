# Compilation Windows de pgm-motion (prêt, NON lancé)
1. Le joueur se connecte une fois : `gh auth login` (dans son terminal).
2. Pousser ce dossier sur une branche `pgm-motion-windows` du dépôt atomiklang/PGM-Dwarf-Fortress (workflow + plugin/).
3. Lancer : `gh workflow run pgm-motion-windows.yml --ref pgm-motion-windows`, récupérer l'artefact.
4. Tester sous Proton dans Dossiers/Test Windows17/jeu (copie jetable), puis sur un vrai Windows.
Point à vérifier au premier essai : la ligne `dfhack_plugin(...)` dans plugins/CMakeLists.custom.txt (mécanisme des plugins externes de DFHack).
