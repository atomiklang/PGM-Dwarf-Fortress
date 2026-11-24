# Assistant anglais bêta5 — candidat terminé

Windows et Linux construits, interfaces source et exécutables ouverts sur leurs systèmes respectifs. Interface, boutons, erreurs, mises à jour et guide local en anglais ; dictionnaires/traductions du jeu inchangés. Nouvelle option de navigation indépendante (précontrôle, installation, restauration), Windows expérimental désactivé par défaut. Aucun jeu joueur ni sauvegarde modifié par l’installation de ce candidat ; aucune release publique nouvelle.

## Changements

Sources neuves dans Installateur PGM20, anciennes sources19 et releases4/19 conservées. app/core/pack/linux_upgrade traduits ; navigation_bridge et moteur à neuf fichiers ajoutés, build/manifest et tests adaptés. Réduction de la hauteur minimale du journal pour éviter boutons coupés en configuration Windows. Restauration corrigée (signature réelle uninstall), roundtrip complet testé avec vrai moteur dans dossiers temporaires. Junctions/reparse points Windows refusés par lstat/attribut0x400 avant résolution ; racinesLinux utilisent les chemins réels pour les aliases système.

## Preuves

Linux Ubuntu22.04/GCC environnement existant :47tests (1Windowsspécifique ignoré), GUI source et binaire ouverts,40fichiers embarqués comparés au manifeste. Exécutable final ouvert aussi sur hôteLinux ; code0, avertissements Fontconfig de compatibilité configuration conservés dans release/linux-startup.log. Aucun nouveau crash lié observé ; ce smoke ne vaut pas contrôle visuel de tous les thèmes/écrans.

WindowsServer2022/Python3.12/PyInstaller6.22.3 : CI45047022625, commitff7727226958df4765cbc4e2ef52353ba57492b4 ;47tests (5Linuxspécifiques ignorés), testjunction natif exécuté, GUI source/mise en page/exécutable réussis,26données réellement embarquées vérifiées. Artifact14764550072 téléchargé ; ZIP SHA d8bfd3fb2f9d5767e177e8d2f5acba7636d5bd3204e0f7b24fc067a4e56383f3 et empreinte.exe du SHA256SUMS-Windows relues. Les noms courts Windows8.3 sont correctement canonicalisés dans le test. .gitattributes préserve les octets des payloads sur checkoutWindows ; les refus d’empreintes n’ont pas été désactivés.

Fichiers prêts dans release : .bin Linux, .tar.gz Linux avec README anglais et .exe Windows. VALIDATION.json récapitule empreintes et limites. Copie candidate Windows de construction, script de préparation, inventaire et rapports dans Dossiers/Windows installer20. Branche candidate/installer20-windows-native uniquement ; main343b7c91… inchangée, aucun tag ni release créé.

Le module de navigation a passé190contrôles sur forteresseLinux et190sousProton/Direct3D, avec zoom4x inspecté,0erreurSDL et arrêtlogique. Sur carteembarquementLinux :174gestes passent ; capture4x finale reste à refaire après attente de la génération réellement présentée (capture2x inspectée). Windows natif en partie et embarquementWindows non testés. Les tests natifs de cet assistant ne sont pas une partie Windows native.

## Suite / publication

Candidats prêts à revue/installation utilisateur, pas publiés. Ne pas fusionner cette branche sur main à l’aveugle : l’ancien workflow public publie encore installer-beta4 et son fetch recharge les données4. Avant publication5, adapter/geler un workflow de release5 avec les bons bundles, conserver versions4/19 immuables, puis vérifier les téléchargements publics. Ne pas déduire une compatibilité jeu Windows native du smoke de l’installateur.
