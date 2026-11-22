# PGM — installer 0.1.0-beta.5 / Linux content 0.1.0-beta.19

## English

Installer5: English interface, local English guide, independent optional map navigation and clearer feature updates. Both source and executable interfaces were opened on their target operating systems. Windows executable is promoted unchanged from native CI45047022625. Linux release is rebuilt and smoke-tested on Ubuntu22.04; published SHA256 files identify the actual release binaries. Translation/quest content remains beta19; existing releases4/19 stay unchanged. Two rare update-validation errors can still appear in French.

Navigation: targeted Linux fortress/embark and Proton fortress tests; no native Windows gameplay or Windows embark validation. Windows options are disabled by default and require explicit opt-in.

- 85 bilingual quests, retaining the 78 original quest identifiers and existing progress. Seven additions and revised defense, preparation for deeper exploration and beekeeping guidance.
- Normal: 74 mods. PGM Full: 87 mods, including Advanced Agriculture, Orchards and Fantastic Trees. Personal presets are excluded from distribution.
- Optional Linux French translation: 936 extinct-creature fields, 268 short DFHack labels/help entries, 35 dialogue entries and 73 actor-aware reply templates added or revised in content19. Multiline dictionary reading and dynamic labels were corrected.
- Translation data: 59,396 entries and 1,873 templates. Inventory checked 16,782 display fields across 78 preset modules with no missing exact dictionary match. This does not establish complete procedural dialogue or DFHack script coverage.
- Existing saves and quest progress were not modified by the local content19 installation. Pack changes should be applied before creating a new world.

Validation: targeted native translation suites, DFHack Lua tests with simulated GUI primitives, and an isolated Linux startup. No complete gameplay validation. Rare screens and colour changes within dialogue remain to be observed in play. Experimental Windows content19 is disabled by default. Proton GE 11-12 validation covered 1,418 targeted cases, 4,000 concurrent calls, 609 tooltips and a quest widget. Two display boundaries remain. Native paragraphs, colours and geometry do not have Linux parity; native Windows gameplay is not validated. Proton startup may take around 100 seconds; do not launch multiple instances. Choose DF-FR or native PGM translation: the assistant refuses native installation if DF-FR is detected. Quests and presets remain independent; complete compatibility is not established.

## Français

Assistant5 : interface et guide local en anglais, navigation de carte facultative indépendante et mises à jour clarifiées. Interfaces source et exécutables ouvertes sur leurs systèmes cibles. Le .exe Windows validé est conservé ; Linux est reconstruit et ouvert sous Ubuntu22.04. Les empreintes publiées désignent les vrais fichiers diffusés. Contenu de traduction/quêtes toujours en bêta19, releases4/19 conservées. Deux erreurs rares de vérification des mises à jour restent en français.

- 85 quêtes FR/EN : conservation des 78 anciens identifiants et de la progression, sept ajouts. Défense rendue plus accessible, parcours vers les profondeurs et apiculture revus.
- Normal : 74 mods ; PGM Full : 87 mods, dont Advanced Agriculture, Orchards et Fantastic Trees. Aucun preset personnel distribué.
- Traduction française Linux19 : 936 champs de créatures disparues, 268 libellés/aides courts DFHack, 35 entrées de dialogue et 73 modèles avec acteur ajoutés ou révisés. Lecture des entrées multilignes et libellés dynamiques corrigée.
- 59 396 entrées et 1 873 modèles ; 16 782 champs d’affichage inventoriés sur 78 modules des presets, sans correspondance exacte manquante. Ce relevé ne garantit pas tous les dialogues procéduraux ni tous les scripts DFHack.
- L’installation locale19 n’a modifié ni sauvegarde ni progression de quête. Appliquer les changements de pack avant de créer un nouveau monde.

Validation : suites ciblées de traduction, essais Lua DFHack avec primitives graphiques simulées et démarrage Linux isolé. Aucune partie complète validée. Les écrans rares et les transitions de couleur au sein des dialogues restent à observer. Windows19 expérimental, désactivé par défaut : 1 418 cas ciblés, 4 000 appels concurrents, 609 infobulles et un widget de quêtes testés sous Proton GE 11-12. Deux frontières d’affichage persistent ; paragraphes, couleurs natifs et géométrie ne sont pas à parité Linux. Windows natif non validé. Démarrage Proton possible en environ 100 secondes : ne pas relancer plusieurs instances. Choisir DF-FR ou native PGM ; installation native refusée si DF-FR est détecté. Quêtes et presets indépendants ; compatibilité complète en partie non validée.


## Assistant update / Mise à jour de l’assistant

Linux translation updates use **Install / update** in the new application; the old executable is not required. Transactional migration keeps a backup and refuses personally modified managed files. Power failure may require assisted recovery. Different presets require restoring previous presets before reinstalling.

La traduction Linux se met à jour depuis **Install / update** dans la nouvelle application, sans ancien exécutable. Migration par étapes protégées, sauvegarde conservée et refus des fichiers gérés modifiés personnellement. Après une coupure de courant, une restauration assistée peut être nécessaire. Pour des presets différents, restaurer les précédents avant de réinstaller.

Reference: Dwarf Fortress 53.17 / DFHack 53.17-r1. Linux x86-64 assistant requires glibc 2.35; the translation hook requires glibc 2.34. Per-release CI results and published SHA256 files provide the build evidence; these tests do not validate a complete playthrough.

## Optional world map navigation

Choose **World map navigation…**, then **Check before install**. With the game closed, choose **Install navigation**. Open a world map in the game and run `gui/worldmap-zoom` in DFHack: mouse wheel zooms, middle-button drag pans, and left-click selection stays enabled. The compact controls switch FR/EN with L. **Restore previous files** restores the previous navigation files. This feature manages its own scripts and plugin independently of translation and presets.

Windows requires **Enable experimental Windows navigation (tested under Proton only)** before installation; restoration needs no opt-in. Linux fortress/embark gestures and Proton Windows fortress navigation passed targeted tests. Native Windows gameplay and Windows embark navigation are untested. A native Windows installer smoke test does not validate native gameplay. Exact supported runtime hashes are required; an unknown build is refused.

## Optional Windows-only mods / Mods Windows facultatifs

[Dwarf Walking](https://steamcommunity.com/sharedfiles/filedetails/?id=3826773394) and [Dwarf Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=3842882430) are separate Windows-only options, following their authors’ current Workshop instructions. Do not subscribe to these two on Linux: their scripts can load independently of Normal/Full presets. Their DLLs are not bundled with PGM, and combined use with map navigation is unverified. Neither is added to the Linux presets or required by the main collection.

Dwarf Walking et Dwarf Actions sont des options Windows séparées, selon les instructions actuelles de leurs auteurs sur les pages liées. Ne pas s’y abonner sous Linux : leurs scripts peuvent se charger indépendamment des presets. Leurs DLL ne sont pas redistribuées ; leur cohabitation avec la navigation reste à valider. Ils ne sont ni ajoutés aux presets Linux ni requis par la collection principale.

