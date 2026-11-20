Assistant 0.1.0-beta.4 / contenu Linux 0.1.0-beta.19

Sources neuves, ancien Installateur PGM conservé. Aucun exécutable construit ici.
Reconstruire Linux sous Ubuntu 22.04 x86-64 et Windows sous Windows 2022 via CI,
puis vérifier chacun des exécutables et empreintes produits. Le .exe prépare les
presets et variantes ; un hook Windows éventuellement ajouté reste expérimental,
facultatif et désactivé par défaut. Aucun test Windows natif réalisé ici.

BUNDLE.json vérifie les fichiers de données embarqués (moteur Linux, payload,
presets et générateur). Il ne certifie pas les sources Python de l’application.
prepare_build.py vérifie les sept empreintes du payload19 et la preuve isolée
correspondante avant copie. App et core versionnent séparément assistant/contenu.
Le module importé linux_upgrade doit être inclus par PyInstaller sous Linux.

Migration Linux : dix fichiers déjà gérés, validation du jeu et état antérieur,
refus des modifications personnelles et liens, verrou exclusif, sauvegarde de
la génération précédente, écritures atomiques et rollback sur erreur. L’état
original et sa sauvegarde restent inchangés pour la désinstallation. Une coupure
pendant la migration conserve migration.json et migrations/<generation> ; la
suite est refusée et nécessite une récupération assistée. Pas de promesse de
récupération automatique après panne système. Tests simulés, pas validation moteur.
Les presets conservent leur parcours prudent : restaurer puis installer la
nouvelle version si les presets gérés changent ; profils personnels conservés.

Parcours : télécharger la nouvelle application, fermer l’ancienne, ouvrir la
nouvelle, sélectionner le jeu fermé, Installer / mettre à jour. Aucun ancien
exécutable nécessaire. Télécharger seul ne modifie pas la traduction.
