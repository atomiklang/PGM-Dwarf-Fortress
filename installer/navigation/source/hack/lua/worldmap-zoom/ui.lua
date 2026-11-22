-- PGM compact bilingual interface. Original renderer remains World Map Zoom/Zlib.
local M={}
local labels={
 fr={title='Carte du monde',reset='Réinit.',close='Fermer',help='Molette : zoom | Milieu : déplacer',on='Clic gauche : actif',off='Clic gauche : bloqué',
  missing='Module de carte absent ou incompatible : installer le plugin adapté au système et à DF 53.17 / DFHack 53.17-r1.',
  version='Cette version demande DFHack 53.17-r1 et ses définitions de structures originales.',stopped='Navigation arrêtée : ',attach='Impossible d’activer le rendu de la carte : '},
 en={title='World map',reset='Reset',close='Close',help='Wheel: zoom | Middle drag: pan',on='Left click: on',off='Left click: blocked',
  missing='Map renderer missing or incompatible: install the plugin for your OS and DF53.17 / DFHack53.17-r1.',
  version='This version requires DFHack53.17-r1 and its original structure definitions.',stopped='Navigation stopped: ',attach='Could not activate map renderer: '},
}
function M.text(key,language)
 local lang=labels[language] and language or 'fr'
 local value=assert(labels[lang][key],'Unknown map UI label: '..tostring(key))
 return value
end
function M.dftext(key,language)
 local s=M.text(key,language)
 return dfhack and dfhack.utf2df and dfhack.utf2df(s) or s
end
return M
