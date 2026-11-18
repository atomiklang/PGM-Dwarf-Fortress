# Installer PGM sous Windows

[**Télécharger l’installateur graphique**](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/installer-v0.1.0-beta.2/PGM-Installer-Windows-0.1.0-beta.2.exe)

Télécharger le .exe Windows puis l’ouvrir.

Python et Tkinter sont intégrés : aucune commande n’est nécessaire pour utiliser l’interface. Cibles : Windows x64 et Linux natif x86-64. Linux demande glibc 2.35 ou supérieure. Le démarrage de la fenêtre est testé automatiquement sur Windows et Ubuntu 22.04 ; les parties complètes restent à tester.

## Avant d’ouvrir l’assistant

1. Installer Dwarf Fortress **53.17** et **DFHack 53.17-r1** correspondant sur Steam. Lancer une fois le jeu avec DFHack, puis le fermer.
2. S’abonner à [PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3841490386). Pour le modpack, s’abonner aussi à la [collection PGM](https://steamcommunity.com/sharedfiles/filedetails/?id=3817551587). Attendre la fin des téléchargements.
3. Dans Steam, utiliser Dwarf Fortress → Gérer → Parcourir les fichiers locaux pour repérer le dossier du jeu.

## Préparer le modpack

1. Ouvrir l’assistant. Choisir le dossier du jeu s’il n’a pas été détecté. Le champ DFHack est utile sous Linux si sa bibliothèque n’est pas trouvée automatiquement.
2. Pour le modpack, cliquer sur **Préparer les variantes du pack**. Si les mods sont dans une autre bibliothèque Steam, choisir le dossier se terminant par `steamapps/workshop/content/975370` dans le champ Workshop.
3. Le dossier des mods locaux est normalement `%APPDATA%/Bay 12 Games/Dwarf Fortress/mods` sous Windows et `$XDG_DATA_HOME/Bay 12 Games/Dwarf Fortress/mods` sous Linux, généralement dans `~/.local/share`. Le champ dédié permet d’en choisir un autre.
4. Cliquer sur **Installer les presets du pack**. Les presets personnels sont conservés. Si un preset personnel différent s’appelle déjà Normal ou PGM Full, l’assistant s’arrête sans l’écraser : résoudre ce conflit de nom avant de réessayer.
5. Lancer le jeu avec DFHack. Avant de générer le monde, ouvrir `gui/mod-manager`, choisir **Normal** ou **PGM Full** et vérifier les dépendances manquantes. Normal retire certains ajouts exigeants ; Full propose les ajouts plus difficiles.

Les variantes sont générées à partir de vos abonnements Born Normally **9** et Accurate Domestic Animals **105**. Une autre version demande de revoir l’adaptation. Une copie locale différente déjà présente est conservée ; l’assistant indique son chemin et s’arrête. Les originaux du Workshop ne sont pas modifiés.

## Quêtes

Pour les quêtes seules, DFHack et l’abonnement PGM suffisent ; variantes et presets servent au modpack. Sélectionner PGM pour le nouveau monde, puis ouvrir `traducfr-quetes` en forteresse et choisir Aisé ou Gloire. `traducfr-quetes langue fr` met le journal en français.

`pgm-traduction-mods activer` active pour la session les traductions disponibles d’une sélection de libellés de mods DFHack. `pgm-traduction-mods desactiver` désactive cette couche. Les aides longues et tous les textes dynamiques ne sont pas encore entièrement couverts.

## Traduction française Windows, facultative

L’assistant **n’installe pas de hook de traduction native PGM Windows**. Vous pouvez utiliser [DF-FR, par Zartuf](https://steamcommunity.com/sharedfiles/filedetails/?id=3828139224), pour le jeu de base, avec PGM pour les quêtes et les presets. Suivre le `LISEZMOI.txt` de la version DF-FR téléchargée, en conservant les fichiers de hook précédents avant de modifier le chaînage. Ne pas remplacer à l’aveugle un autre hook de traduction.

Un démarrage de DF-FR 1.2.2 avec DFHack 53.17-r1 a été confirmé sous GE-Proton11-12. Une partie complète PGM sur Windows natif reste à tester.

## Restaurer et mettre à jour

**Restaurer les presets précédents** remet le fichier sauvegardé avant leur installation. **Désinstaller la traduction** restaure les fichiers de traduction Linux. Un fichier modifié depuis l’installation est conservé et demande une vérification manuelle.

**Chercher une mise à jour** vérifie les versions publiées. **Télécharger la mise à jour** récupère un exécutable vérifié ; ouvrir ensuite le dossier de téléchargement puis la nouvelle version. **Le remplacement automatique de l’application et la mise à jour automatique du dictionnaire ne sont pas encore disponibles dans cette bêta.** Pour changer la traduction Linux, restaurer l’ancienne installation puis installer la nouvelle, jeu fermé. Conserver l’ancien exécutable jusqu’à validation. Steam continue de mettre à jour les mods Workshop.

## En cas de problème

Utiliser **Enregistrer le rapport** pour conserver les messages localement. Rien n’est envoyé automatiquement. Fermer le jeu avant toute modification, ne pas lancer l’assistant Linux avec sudo et conserver les sauvegardes. Après une interruption, conserver le rapport et l’état d’installation avant de réessayer ou de retirer manuellement un verrou.

[Notes de l’installateur](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/tag/installer-v0.1.0-beta.2) · [Fichiers de préparation manuelle](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/PGM-Installation-0.1.0-beta.3.zip) · [Paquet Linux manuel](https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/PGM-Linux-0.1.0-beta.3.zip)
