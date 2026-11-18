# PGM — installateur graphique Windows et Linux

Sources de l’assistant distribué dans les [publications GitHub](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/installer-v0.1.0-beta.2).

## Pour les joueurs

- **Windows x64 :** télécharger `PGM-Installer-Windows-0.1.0-beta.2.exe` et l’ouvrir.
- **Linux x86-64 :** télécharger `PGM-Installer-Linux-0.1.0-beta.2.tar.gz`, extraire l’archive et ouvrir `PGM-Installer`. Autoriser l’exécution dans les propriétés du fichier si nécessaire.

Python et Tkinter sont intégrés aux exécutables. Aucun droit administrateur n’est nécessaire. Linux demande glibc 2.35 ou supérieure. Les autres distributions que l’environnement Ubuntu 22.04 de compilation restent à tester.

L’assistant prépare les variantes locales du pack, installe/restaure les presets en conservant les presets personnels et installe/restaure la traduction Linux native pour Dwarf Fortress 53.17. Installer le jeu, DFHack et les abonnements Workshop via Steam auparavant, puis fermer le jeu. L’interface est actuellement en français.

Le fichier `.bin` est l’exécutable Linux autonome utilisé aussi par le téléchargement de mise à jour ; l’archive `.tar.gz` est conseillée pour une première installation.

## Limites explicites de la bêta

- La traduction native Windows n’est pas fournie. Le parcours DF-FR facultatif reste dans le guide Windows.
- Les quêtes, PGM et les mods Workshop restent téléchargés et mis à jour via Steam.
- La recherche de mise à jour télécharge une nouvelle application et vérifie son SHA-256. Ouvrir ensuite cette nouvelle version. Le remplacement automatique de l’application et la mise à jour automatique du dictionnaire restent à développer.
- Avant de changer la traduction Linux, restaurer l’installation précédente, puis installer la nouvelle version, jeu fermé. Conserver l’installateur précédent jusqu’à validation.
- Les bibliothèques Steam supplémentaires et les dossiers particuliers peuvent être sélectionnés manuellement.
- Les fichiers modifiés localement sont conservés : leur restauration demande alors une fusion manuelle.
- Le test automatique du lancement de l’interface ne remplace pas un test complet en jeu, en particulier sous Windows.

## Pour reconstruire

Le workflow racine `.github/workflows/installer.yml` fabrique les deux exécutables sur les systèmes cibles. Les sources sont dans `installer/` sur GitHub. Le workflow récupère les paquets bêta 3 existants en vérifiant leurs empreintes SHA-256 fixées dans `prepare_build.py`, exécute les tests, vérifie le lancement de l’interface, construit les exécutables, vérifie leur lancement puis publie les fichiers uniquement si les deux systèmes réussissent.

En local, utiliser Python 3.12 avec Tkinter et PyInstaller 6.22.3 : `python prepare_build.py`, `python -m unittest discover -s tests`, `python build.py`, puis `python package_build.py`. Sous Linux, les tests graphiques utilisent aussi Xvfb. La construction produit un seul exécutable, qui inclut Python, Tkinter et les fichiers nécessaires.

Les empreintes vérifient l’intégrité des fichiers GitHub ; elles ne constituent pas une signature indépendante du compte éditeur. Les exécutables ne possèdent pas de certificat commercial de signature.
