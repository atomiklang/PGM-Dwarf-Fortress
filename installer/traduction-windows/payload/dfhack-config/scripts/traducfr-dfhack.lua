-- traducfr-dfhack : traduit l'interface de DFHack avec le dictionnaire de traducfr.
-- Projet d'Atomiklang avec Claude. Lance automatiquement par dfhack-config/init/dfhack.init.
-- Principe : le texte exact affiche par DFHack est cherche dans traducfr/dictionnaire.csv ;
-- s'il est connu, la traduction est affichee, sinon l'anglais reste. F12 (hook traducfr) = FR/EN.
--@ module = true

local gui = require('gui')
local WrappedLabel = require('gui.widgets.labels.wrapped_label')
local dialogs = require('gui.dialogs')

local CHEMIN = dfhack.getDFPath() .. '/traducfr/dictionnaire.csv'

dico = dico or {}
local cache_traductions, nb_cache = {}, 0
local CACHE_MAX = 2048

-- Two quoted CSV fields, including doubled quotes and embedded newlines.
local function csv_pair19(record)
    local fields,at={},1
    for col=1,2 do
        if record:sub(at,at)~='"' then return end
        at=at+1
        local chunks={}
        while true do
            local q=record:find('"',at,true)
            if not q then return end
            chunks[#chunks+1]=record:sub(at,q-1)
            if record:sub(q+1,q+1)=='"' then
                chunks[#chunks+1]='"';at=q+2
            else at=q+1;break end
        end
        fields[col]=table.concat(chunks)
        if col==1 then
            if record:sub(at,at)~=',' then return end
            at=at+1
        end
    end
    local rest=record:sub(at)
    if rest~='' and rest~='\r' then return end
    return fields[1],fields[2]
end
local function charger()
    local f=io.open(CHEMIN,'rb')
    if not f then
        dfhack.printerr('traducfr-dfhack : dictionnaire introuvable ('..CHEMIN..')')
        return 0
    end
    local d,n,parts,bytes,in_quotes={},0,{},0,false
    for line in f:lines() do
        parts[#parts+1]=line;bytes=bytes+#line+1
        local at=1
        while true do
            local q=line:find('"',at,true)
            if not q then break end
            if in_quotes and line:sub(q+1,q+1)=='"' then at=q+2
            else in_quotes=not in_quotes;at=q+1 end
        end
        if bytes>1048576 then
            -- Match the native field bound; a broken local record must not grow forever.
            parts,bytes,in_quotes={},0,false
        elseif not in_quotes then
            local k,v=csv_pair19(table.concat(parts,'\n'))
            if k and k~='' and v and v~='' and d[k]==nil then d[k]=v;n=n+1 end
            parts,bytes={},0
        end
    end
    f:close()
    dico=d
    cache_traductions,nb_cache={},0
    return n
end

local function actif()
    return rawget(_G, 'PGM_WINDOWS_FR') ~= false
end

-- textes avec un nombre (notifications DFHack) : motif anglais -> fonction qui ‚crit le fran‡ais
local function pl(n, un, plusieurs) return tonumber(n) == 1 and un or plusieurs end
local MOTIFS = {
    { '^(%d[%d, ]*) mins ago$', function(n) return 'il y a ' .. n .. ' min' end },
    { '^missing (%d+) nemesis records?$', function(n) return n .. pl(n, ' fiche nemesis absente', ' fiches nemesis absentes') end },
    { '^task starvation: (%d+) unclaimed jobs?$', function(n) return n .. pl(n, ' tƒche sans travailleur', ' tƒches sans travailleur') end },

    { '^(%d+) petitions? outstanding$', function(n) return n .. pl(n, ' p‚tition en attente', ' p‚titions en attente') end },
    { '^(%d+) agitated animals?$', function(n) return n .. pl(n, ' animal agit‚', ' animaux agit‚s') end },
    { '^(%d+) invaders?$', function(n) return n .. pl(n, ' envahisseur', ' envahisseurs') end },
    { '^(%d+) hostiles?$', function(n) return n .. pl(n, ' cr‚ature hostile', ' cr‚atures hostiles') end },
    { '^(%d+) injured citizens?(.*)$', function(n, reste)
        return n .. pl(n, ' citoyen bless‚', ' citoyens bless‚s') .. (reste == '; no functional hospital!' and ' ; pas d\'h“pital en ‚tat !' or reste) end },
    { '^(%d+) starving, dehydrated, or drowsy units?$', function(n) return n .. pl(n, ' affam‚, assoiff‚ ou ‚puis‚', ' affam‚s, assoiff‚s ou ‚puis‚s') end },
    { '^(%d+) thieving or mischievous creatures?$', function(n) return n .. pl(n, ' voleur ou farceur', ' voleurs ou farceurs') end },
    { '^(%d+) groups? of citizens %a+ stranded$', function(n) return n .. pl(n, ' groupe de citoyens isol‚', ' groupes de citoyens isol‚s') end },
    { '^(%d+) squads? needs? rescue$', function(n) return n .. pl(n, ' escouade … secourir', ' escouades … secourir') end },
    { '^(%d+) traders? %a+ ready to trade$', function(n) return n .. pl(n, ' marchand prˆt … commercer', ' marchands prˆts … commercer') end },
    { '^(%d+) production mandates? near deadline$', function(n) return n .. pl(n, ' mandat bient“t expir‚', ' mandats bient“t expir‚s') end },
    { '^It has been (%d+) minutes since your last save%.$', function(n) return 'DerniŠre sauvegarde il y a ' .. n .. ' minutes.' end },
}
local HUMEUR = {
    ecstatic='euphoriques', ['very happy']='trŠs heureux', happy='heureux',
    content='satisfaits', unhappy='m‚contents', ['very unhappy']='trŠs m‚contents',
    miserable='mis‚rables',
}
-- Only anchored display formats sourced from DFHack widgets. Captured names stay opaque.
local function texte_menu19(s)
    local n = s:match('^Burrow (%d+)$')
    if n then return 'Terrier ' .. n end
    n = s:match('^Stockpile (%d+)$')
    if n then return 'Stock ' .. n end
    n = s:match('^Current stockpiles: (%d+)$')
    if n then return 'Stocks actuels : ' .. n end
    n = s:match('^default: (%-?%d+)$')
    if n then return 'd‚faut : ' .. n end
    n = s:match('^at least (%-?%d+)$')
    if n then return 'au moins ' .. n end
    n = s:match('^at most (%-?%d+)$')
    if n then return 'au plus ' .. n end
    n = s:match('^current: (%-?%d+)$')
    if n then return 'actuel : ' .. n end
    n = s:match('^You have (%d+) items? selected for trade$')
    if n then return n .. pl(n, ' objet choisi pour le commerce', ' objets choisis pour le commerce') end
    local name
    n,name = s:match('^(%d+) order%(s%) would be enqueued for\n(.+)%.$')
    if n then return n .. pl(n,' ordre serait ajout‚ pour\n',' ordres seraient ajout‚s pour\n') .. name .. '.' end
    n,name = s:match('^(%d+) order%(s%) enqueued for\n(.+)%.$')
    if n then return n .. pl(n,' ordre ajout‚ pour\n',' ordres ajout‚s pour\n') .. name .. '.' end
    if s=='Orders enqueued' then return 'Ordres ajout‚s' end
    if s=='Orders would be enqueued' then return 'Ordres pr‚vus' end
    local types,items,squads=s:match('^(%d+) item types?, (%d+) items? total across (%d+) squads?$')
    if types then return types .. pl(types," type d'objet, "," types d'objets, ") .. items .. pl(items,' objet pour ',' objets pour ') .. squads .. pl(squads,' escouade',' escouades') end
    local tabs={Enabled='Activ‚',Autostart='Au d‚part'}
    local groups={automation="d'automatisation",bugfix='de correction',gameplay='de jeu'}
    local group_names={automation='automatisation',bugfix='correctifs',gameplay='jeu'}
    local tab,group=s:match('^Are you sure you want to restore (%a+)\ndefaults for (%a+) tools%?$')
    if tab and tabs[tab] and groups[group] then return "R‚tablir les valeurs de l'onglet " .. tabs[tab] .. '\npour les outils ' .. groups[group] .. ' ?' end
    tab,group=s:match('^(%a+) defaults restored for (%a+) tools%.$')
    if tab and tabs[tab] and group_names[group] then return 'Valeurs r‚tablies : ' .. tabs[tab] .. ' / ' .. group_names[group] .. '.' end
    local value=s:match('^Cannot find stockpile settings directory: "(.*)"$')
    if value then return 'Dossier des r‚glages de stock introuvable : "' .. value .. '"' end
    value=s:match('^invalid included element: "(.*)"$')
    if value then return '‚l‚ment inclus invalide : "' .. value .. '"' end
    value=s:match('^invalid mode: "(.*)"$')
    if value then return 'mode invalide : "' .. value .. '"' end

end

-- Lot 23 (PGM) : textes DFHack et Detailed Weather construits avec des nombres.
-- Fonction pure : pgm23(s, dico, pl) -> traduction ou nil. dico = dictionnaire exact.
local function pgm23(s, dico, pl)
    local function d(x) return dico[x] or dico[x:lower()] end
    local n, job, ticks = s:match('^task starvation: (%d+) unclaimed jobs? %(oldest: (.+), (%d+) ticks%)$')
    if n then
        local j = d(job) or job
        return n .. pl(n, ' tƒche d‚laiss‚e', ' tƒches d‚laiss‚es') .. ' (plus ancienne : ' .. j:lower() .. ', ' .. ticks .. ' ticks)'
    end
    local plante, mot, v = s:match('^(.+), (%a+) %((%d+)/100%)$')
    local GRASS = {lush='dense', thick='assez dense', thin='peu dense', sparse='rare'}
    if plante and GRASS[mot] then return (d(plante) or plante) .. ', ' .. GRASS[mot] .. ' (' .. v .. '/100)' end
    local neige, q = s:match('^(.+) %((%d+)/255%)$')
    local SNOW = {['deep snow']='neige ‚paisse', snow='neige', ['a dusting of snow']='fine couche de neige'}
    if neige and SNOW[neige] then return SNOW[neige] .. ' (' .. q .. '/255)' end
    local AIR = {['very humid']='trŠs humide', humid='humide', average='moyen', dry='sec', ['very dry']='trŠs sec'}
    local a, pc, force = s:match('^air (.-) %((%d+)%%(.-)%)$')
    if a and AIR[a] then return 'air ' .. AIR[a] .. ' (' .. pc .. ' %' .. (force == ', forced' and ', forc‚' or '') .. ')' end
    local vie = s:match('^Wildlife: (.*)$')
    if vie then
        local out = {}
        for part in (vie .. ', '):gmatch('(.-), ') do
            local k, nom = part:match('^(%d+) (.+)$')
            out[#out + 1] = k and (k .. ' ' .. (d(nom) or nom)) or part
        end
        return 'Faune : ' .. table.concat(out, ', ')
    end
    return nil
end
-- Termes de m‚t‚o s‚par‚s par ® ; ¯ (aprŠs la temp‚rature)
local METEO23 = {
    drizzling='bruine', raining='pluie', ['raining heavily']='forte pluie', ['pouring with rain']='pluie torrentielle',
    ['snowing lightly']='faible neige', snowing='neige', ['snowing heavily']='forte neige', ['a blizzard blowing']='blizzard',
    mist='brume', fog='brouillard', ['thick fog']='brouillard ‚pais', calm='calme',
}
local VENT23 = {light='vent l‚ger', breezy='brise', strong='vent fort', gale='tempˆte'}
local DIR23 = {east="de l'est", west="de l'ouest", north='du nord', south='du sud',
    ['north-east']='du nord-est', ['north-west']='du nord-ouest', ['south-east']='du sud-est', ['south-west']='du sud-ouest'}
local function meteo23(terme)
    local base, forced = terme:match('^(.-)( %(forced%))$')
    base = base or terme
    local suffixe = forced and ' (forc‚)' or ''
    if METEO23[base] then return METEO23[base] .. suffixe end
    local f, dir = base:match('^(%a+) wind from the (.+)$')
    if f and VENT23[f] and DIR23[dir] then return VENT23[f] .. ' ' .. DIR23[dir] .. suffixe end
    return nil
end

local function texte_menu(s)
    local r23=pgm23(s,dico,pl)
    if r23 then return r23 end
    local added=texte_menu19(s)
    if added then return added end
    if s == 'hazel tree: in leaf' then return 'noisetier en feuilles' end
    local humeur = s:match('^Units: (.+)$')
    if humeur and HUMEUR[humeur] then return 'Habitants ' .. HUMEUR[humeur] end
    local version = s:match('^Military Reequip%s+v([%d.]+)$')
    if version then return 'R‚‚quipement militaire v' .. version end
    local lignes = s:match('^Results: %((%d+) lines?%)$')
    if lignes then return 'R‚sultats : ' .. lignes .. pl(lignes, ' ligne', ' lignes') end
    local n, total, filtres = s:match('^Gear list %((%d+)/(%d+) sections%)(.-) | Enter on header to expand/collapse$')
    if n then
        local filtre = filtres ~= '' and ' | filtres actifs' or ''
        return ('Mat‚riel (%s/%s sections)%s | Entr‚e : ouvrir ou r‚duire'):format(n, total, filtre)
    end
    local objets, sections = s:match('^Worn clothing %((%d+) items?, (%d+) sections?%) | filter: .+ | Enter to inspect/collapse$')
    if objets then
        return ('Habits us‚s (%s objets, %s sections) | Entr‚e : inspecter ou r‚duire'):format(objets, sections)
    end
    local types = s:match('^Forge Preview %((%d+) item types?%) | set materials right, F to queue$')
    if types then return ('Aper‡u forge (%s types) | Choisir les mat‚riaux, F : commander'):format(types) end
    local erreur = s:match('^Preview error: (.+)$')
    if erreur then return "Erreur d'aper‡u : " .. erreur end
    local temp, suite = s:match('^(-?%d+) C(.*)$')
    if not temp then temp, suite = s:match('^(-?%d+) øC(.*)$') end
    if temp and (suite == '' or suite:match('^[ ,;]')) then
        suite = suite:gsub('^ under cover', ' … couvert'):gsub('^ underground', ' sous terre')
        suite = suite:gsub(', air very humid ', ', air trŠs humide '):gsub(', air humid ', ', air humide '):gsub(', air very dry ', ', air trŠs sec '):gsub(', air dry ', ', air sec ')
        local meteo = {
            calm = 'calme', drizzling = 'bruine', raining = 'pluie',
            ['raining heavily'] = 'forte pluie', ['pouring with rain'] = 'pluie torrentielle',
        }
        local directions = {east="de l'est", west="de l'ouest", north='du nord', south='du sud',
            northeast='du nord-est', northwest='du nord-ouest', southeast='du sud-est', southwest='du sud-ouest',
            ['north east']='du nord-est', ['north west']='du nord-ouest', ['south east']='du sud-est', ['south west']='du sud-ouest'}
        suite = suite:gsub('; ([^;]+)', function(terme)
            local m23 = meteo23(terme)
            if m23 then return '; ' .. m23 end
            if meteo[terme] then return '; ' .. meteo[terme] end
            local direction = terme:match('^breezy wind from the (.+)$')
            if direction and directions[direction] then return '; brise ' .. directions[direction] end
            return '; ' .. terme
        end)
        return temp .. ' øC' .. suite
    end
end

local function traduire_sans_cache(s)
    if type(s) ~= 'string' or s == '' or not actif() then return s end
    local t = dico[s]
    if t then return t end
    -- motifs avec nombre : seulement si le texte commence par un chiffre ou un mot connu (rapide)
    local c = s:byte(1)
    if (c and c >= 48 and c <= 57) or s:sub(1, 8) == 'Wildlife' or s:sub(1, 11) == 'It has been' or s:sub(1, 8) == 'missing '
            or s:sub(1, 17) == 'task starvation: ' then
        for _, m in ipairs(MOTIFS) do
            local a, b = s:match(m[1])
            if a then return m[2](a, b) end
        end
    end
    if s == ' to ' then return ' … ' end
    local avant, milieu, apres = s:match('^(%s*)(.-)(%s*)$')
    if milieu and milieu ~= '' then
        t = dico[milieu]
        if not t then
            t = texte_menu(milieu)
        end
        if t then return avant .. t .. apres end
    end
    return s
end

-- Cache repeated labels and misses; cap dynamic dates, names and counters.
function traduire(s)
    if type(s) ~= 'string' or s == '' or not actif() then return s end
    local cached = cache_traductions[s]
    if cached ~= nil then return cached end
    local result = traduire_sans_cache(s)
    if result == s and s:find('\n', 1, true) then
        result = s:gsub('[^\r\n]+', traduire_sans_cache)
    end
    if #s <= 1024 then
        if nb_cache >= CACHE_MAX then cache_traductions, nb_cache = {}, 0 end
        cache_traductions[s] = result
        nb_cache = nb_cache + 1
    end
    return result
end

-- Copy display tokens only. Never alter note contents, callbacks or source tables.
function traduire_message(text)
    if type(text) == 'string' then return traduire(text) end
    if type(text) ~= 'table' or not actif() then return text end
    local result = {}
    for key, value in pairs(text) do result[key] = value end
    for i, token in ipairs(text) do
        if type(token) == 'string' then
            result[i] = traduire(token)
        elseif type(token) == 'table' and type(token.text) == 'string' then
            local copy = {}
            for key, value in pairs(token) do copy[key] = value end
            copy.text = traduire(token.text)
            result[i] = setmetatable(copy, getmetatable(token))
        end
    end
    return setmetatable(result, getmetatable(text))
end

-- Translate prompt text before DialogWindow computes the label width.
for _, name in ipairs({'showMessage', 'showYesNoPrompt', 'showInputPrompt', 'showListPrompt'}) do
    if type(dialogs[name]) == 'function' then
        local key = '__traducfr_' .. name
        if not dialogs[key] then dialogs[key] = dialogs[name] end
        local original = dialogs[key]
        dialogs[name] = function(title, text, ...)
            return original(traduire(title), traduire_message(text), ...)
        end
    end
end

-- Notification widths must be computed from translated text, not English glyphs.
local function installer_notifications()
    local ok, module = pcall(reqscript, 'gui/notify')
    if not ok or not module or not module.NotifyOverlay then return end
    local class = module.NotifyOverlay
    if class.__traducfr_onupdate then return end
    class.__traducfr_onupdate = class.overlay_onupdate
    class.overlay_onupdate = function(self, ...)
        local list = self.subviews and self.subviews.list
        if list and not list.__traducfr_setChoices then
            list.__traducfr_setChoices = list.setChoices
            list.setChoices = function(view, choices, ...)
                local translated = choices
                if type(choices) == 'table' and actif() then
                    translated = {}
                    for i, choice in ipairs(choices) do
                        if type(choice) == 'table' then
                            local copy = {}
                            for key, value in pairs(choice) do copy[key] = value end
                            copy.text = traduire_message(choice.text)
                            translated[i] = setmetatable(copy, getmetatable(choice))
                        else translated[i] = choice end
                    end
                end
                return view.__traducfr_setChoices(view, translated, ...)
            end
        end
        return class.__traducfr_onupdate(self, ...)
    end
end

local n = charger()

-- 1. Tout texte dessine par DFHack passe par Painter:string
if not gui.Painter.__traducfr_string then
    gui.Painter.__traducfr_string = gui.Painter.string
end
local string_origine = gui.Painter.__traducfr_string
gui.Painter.string = function(self, text, ...)
    return string_origine(self, traduire(text), ...)
end

-- Les cadres rendent leur titre sans passer par Painter:string.
if not gui.__traducfr_paint_frame then
    gui.__traducfr_paint_frame = gui.paint_frame
end
local cadre_origine = gui.__traducfr_paint_frame
gui.paint_frame = function(dc, rect, style, titre, ...)
    return cadre_origine(dc, rect, style, traduire(titre), ...)
end

-- 2. Les textes longs (aides, infobulles) sont traduits AVANT d'etre coupes en lignes
if not WrappedLabel.__traducfr_wrap then
    WrappedLabel.__traducfr_wrap = WrappedLabel.getWrappedText
end
local wrap_origine = WrappedLabel.__traducfr_wrap
WrappedLabel.getWrappedText = function(self, width)
    local source = self.text_to_wrap
    if not source or width <= 0 or not actif() then return wrap_origine(self, width) end
    local contenu = source
    if type(source) == 'function' then contenu = source() end
    if type(contenu) == 'table' then
        contenu = traduire_message(contenu)
    else
        contenu = traduire(contenu)
    end
    self.text_to_wrap = contenu
    local ok, resultat = pcall(wrap_origine, self, width)
    self.text_to_wrap = source
    if not ok then error(resultat, 0) end
    return resultat
end

if not dfhack_flags or not dfhack_flags.module then
    print(('traducfr-dfhack : %d traductions chargees pour DFHack'):format(n))
end

-- Active mod scripts can become available after the world-loaded overlay scan.
dfhack.onStateChange.traducfr_overlays = function(code)
    if code ~= SC_MAP_LOADED then return end
    installer_notifications()
    if not dfhack.world.isFortressMode()
            or not dfhack.findScript('traducfr-quetes') then return end
    local overlay = require('plugins.overlay')
    if not overlay.get_state().db['traducfr-quetes.quetes'] then overlay.rescan() end
end

installer_notifications()

-- AA: output-only translation, scoped to the eight original mod scripts.
local AA_TEXT = {
    ["Advanced Harvesting:\010\010This module returns the farming behavior from before DF 52.03:\010When a farm plot is harvested the plant's growths are obtained along with the plant item. Unlike the original behavior, farmers will only pick stockpileable growths in order to avoid clutter."] = "R\130colte avanc\130e\010\010Ce module r\130tablit le fonctionnement des cultures ant\130rieur \133 DF 52.03 : lors de la r\130colte d'un terrain agricole, les produits de la plante sont r\130cup\130r\130s avec la plante elle-m\136me. Pour \130viter l'encombrement, les cultivateurs ne ramassent que les produits pouvant \136tre entrepos\130s.",
    ["Enforces placing the Prepared Ground workshop only on plantable tiles and converts it to a sapling on reaction completion."] = "Le Terrain pr\130par\130 ne peut \136tre construit que sur une case cultivable. Une fois la transformation termin\130e, cet atelier devient un jeune arbre.",
    ["Byproduct System:\010\010This module adds byproducts to certain vanilla jobs in Fortress Mode.\010It currently only produces bark when making wooden blocks and furniture. It can be disabled if you do not want to deal with byproducts from vanilla jobs."] = "Sous-produits\010\010Ce module ajoute des sous-produits \133 certaines t\131ches du jeu de base en mode Forteresse. Il produit actuellement de l'\130corce lors de la fabrication de blocs et de meubles en bois. D\130sactive-le si tu ne souhaites pas g\130rer ces sous-produits.",
    ["Sensible Seed Caps:\010\010This module changes the specific and fortress seed caps to more sane values of 50 and 30000, respectively. This allows obtaining seeds for every crop and receiving new seeds from reactions when merchants arrive with many seeds. Yes, merchant seeds count against your fortress caps even without buying them.\010\010Note that the issue the seed caps were implemented to fix was resolved years ago. Even 200,000 seeds in a fortress would not significantly affect FPS in modern Dwarf Fortress versions.\010\010The default fortress seed cap is 3000. Once this limit is reached, seeds begin being DELETED from stockpiles, oldest first, maintaining equal amounts of each species. This only allows 19 seeds of each species if you manage to collect them all.\010\010The math:\010    Default Total cap: 3000.\010    Default Specific cap: 200.\010    Vanilla seeds = 157 x 200 = 31,400.\010        3000 / 157 = 19 per species.\010    AA seeds = 112 x 200 = 22,400.\010        3000 / 112 = 26 per species.\010\010    Sensible Total cap: 30000 (maximum).\010    Sensible Specific cap: 50.\010    Sensible caps = 112 x 50 = 5,600.\010        Max species below Total = 600.\010\010Even if you only farm subterranean crops 50 of each species is still more than enough for secure food production, while allowing up to 600 species of crops without worrying about the Total cap causing depletion."] = "Plafonds de graines adapt\130s\010\010Ce module r\138gle le plafond par esp\138ce sur 50 et le plafond de la forteresse sur 30 000. Il permet de r\130cup\130rer des graines de chaque culture, y compris lorsque des marchands en apportent beaucoup : leurs graines comptent dans le plafond de ta forteresse, m\136me sans achat.\010\010Selon l'auteur, le probl\138me \133 l'origine de ces plafonds a \130t\130 corrig\130 depuis des ann\130es ; m\136me 200 000 graines n'affecteraient pas sensiblement les performances des versions modernes du jeu.\010\010Le plafond total par d\130faut est de 3 000. Lorsqu'il est atteint, les graines les plus anciennes commencent \133 \136tre supprim\130es des stocks, en maintenant des quantit\130s \130gales entre esp\138ces. Si tu poss\138des toutes les esp\138ces du jeu de base, cela ne laisse qu'environ 19 graines de chacune.\010\010Calculs pr\130sent\130s par le mod :\010  Plafond total par d\130faut : 3 000.\010  Plafond par esp\138ce par d\130faut : 200.\010  Jeu de base : 157 esp\138ces x 200 = 31 400 graines.\010    3 000 / 157 = environ 19 par esp\138ce.\010  Advanced Agriculture : 112 esp\138ces x 200 = 22 400 graines.\010    3 000 / 112 = environ 26 par esp\138ce.\010\010  Plafond total propos\130 : 30 000 (maximum).\010  Plafond propos\130 par esp\138ce : 50.\010  112 esp\138ces x 50 = 5 600 graines.\010  Jusqu'\133 600 esp\138ces peuvent ainsi rester sous le plafond total.\010\010M\136me avec seulement des cultures souterraines, 50 graines par esp\138ce suffisent, selon le mod, pour une production alimentaire stable. Le plafond total permet alors de conserver jusqu'\133 600 esp\138ces sans suppression li\130e \133 cette limite.",
    ["Cooking Gives Seeds:\010\010This module makes cooking produce seeds from plants and plant growths which should produce seeds. It can be disabled. Seeds produced will never exceed seed caps."] = "Graines issues de la cuisine\010\010Ce module r\130cup\138re les graines des plantes et des r\130coltes cuisin\130es qui peuvent en fournir. Il peut \136tre d\130sactiv\130. La production respecte toujours les plafonds de graines.",
    ["Shrub Cleanup:\010\010This module removes dead plants once a month to simulate them rotting away. Otherwise, shrubs and saplings that die due to not growing in certain seasons (namely winter) never naturally decay and eventually end up covering the ground."] = "Nettoyage des plantes mortes\010\010Une fois par mois, ce module retire les plantes mortes pour simuler leur d\130composition. Sans lui, les plantes et jeunes arbres qui meurent pendant certaines saisons, notamment l'hiver, ne disparaissent pas naturellement et finissent par couvrir le sol.",
    ["Enabled Advanced Harvesting."] = "R\130colte avanc\130e activ\130e.",
    ["Disabled Advanced Harvesting."] = "R\130colte avanc\130e d\130sactiv\130e.",
    ["Enabled Byproduct System."] = "Production de sous-produits activ\130e.",
    ["Disabled Byproduct System."] = "Production de sous-produits d\130sactiv\130e.",
    ["Enabled Cooking Gives Seeds."] = "R\130cup\130ration des graines en cuisine activ\130e.",
    ["Disabled Cooking Gives Seeds."] = "R\130cup\130ration des graines en cuisine d\130sactiv\130e.",
    ["Enabled Shrub Cleanup."] = "Nettoyage des plantes mortes activ\130.",
    ["Disabled Shrub Cleanup."] = "Nettoyage des plantes mortes d\130sactiv\130.",
    ["Changed seed caps to recommended values."] = "Plafonds de graines r\130gl\130s sur les valeurs recommand\130es.",
    ["Enable requires a module to be specified."] = "Indique le module \133 activer apr\138s enable.",
    ["\010Advanced Agriculture\010===========\010\010Tags: fort | gameplay | jobs | plants\010\010Controls the Advanced Agriculture modules.\010\010If a module is not specified after status, then the\010state of every module will be displayed.\010\010Note that seedcaps is globally enabled or disabled as it\010affects game settings. All other modules will have\010per-world settings.\010\010Available commands:\010    enable <module>\010    disable <module>\010    help <module (optional)>\010    status <module (optional)>\010\010Available modules:\010    byproducts: Creates byproducts from jobs\010    harvesting: Provides growths on farm plot harvest\010    seedcaps: Changes game seed caps to sane values\010    seedsfromcooking: Cooking creates seeds\010    shrubcleanup: Removes dead shrubs seasonally\010\010Usage\010-----\010    advanced-agriculture status\010    advanced-agriculture enable seedcaps\010    advanced-agriculture disable harvesting\010"] = "Advanced Agriculture\010====================\010\010Gestion des modules d'Advanced Agriculture.\010\010Sans nom de module apr\138s status, l'\130tat de tous les modules est affich\130.\010Le r\130glage seedcaps est global, car il modifie les param\138tres du jeu.\010Les autres modules sont configur\130s s\130par\130ment pour chaque monde.\010\010Commandes \133 saisir telles quelles :\010  advanced-agriculture enable <module>\010  advanced-agriculture disable <module>\010  advanced-agriculture help [module]\010  advanced-agriculture status [module]\010\010Modules :\010  byproducts : sous-produits de fabrication, notamment l'\130corce.\010  harvesting : produits des plantes r\130cup\130r\130s \133 la r\130colte.\010  planting : plantation sur terrain pr\130par\130 ; module obligatoire.\010  seedcaps : plafonds de graines adapt\130s.\010  seedsfromcooking : graines r\130cup\130r\130es en cuisine.\010  shrubcleanup : retrait r\130gulier des plantes mortes.\010\010Exemples :\010  advanced-agriculture status\010  advanced-agriculture enable seedcaps\010  advanced-agriculture disable harvesting\010\010Utilise help suivi du nom d'un module pour lire son aide.",
    ["\010\010AA-ban-cooking\010=================\010Tags: fort | productivity | items | plants\010\010Command: AA-ban-cooking\010\010\009Protect useful items from being cooked.\010\010Some cookable ingredients have other important uses. For example, seed giving plants and growths can be cooked, but if you cook them all, then your farmers will have no seeds to plant in the fields. Similarly, thread producing items can be cooked, but if you do that, then your weavers will have nothing to weave into cloth and your doctors will have nothing to use for stitching up injured dwarves.\010\010If you open the Kitchen screen, you can select individual item types and choose to ban them from cooking. To prevent all your booze from being cooked, for example, you\226\128\153d select the Booze tab and then click each of the visible types of booze to prevent them from being cooked. Only types that you have in stock are shown, so if you acquire a different type of booze in the future, you have to come back to this screen and ban the new types.\010\010Instead of doing all that clicking, ban-cooking can ban entire classes of items (e.g. all types of booze) in one go. It can even ban types that you don\226\128\153t have in stock yet, so when you do get some in stock, they will already be banned. It will never ban items that are only good for eating or cooking, like meat or non-plantable nuts. It is usually a good idea to run ban-cooking all as one of your first actions in a new fort.\010\010If you want to re-enable cooking for a banned item type, you can go to the Kitchen screen and un-ban whatever you like by clicking on the \226\128\156cook\226\128\157 icon. You can also un-ban an entire class of items with the ban-cooking --unban option.\010Usage\010\010ban-cooking <type|all> [<type> ...] [<options>]\010\010Valid types are:\010    all (everything below)\010    booze (drinks)\010    brew (brewable plants and growths)\010    honey\010    mill (millable plants and growths)\010    milk\010    oil\010    plant_milk (only plant milks that can be processed into tofu)\010    roast (growths that have processing chains, such as coffee cherries)\010    syrup\010    seed_items (plants and growths which produce seeds)\010    seeds\010    tallow\010    thread (plants and growths which can be spun into thread)\010\010It is possible to include multiple types or all types in a single ban-cooking command: ban-cooking oil tallow will ban both oil and tallow from cooking. ban-cooking all will ban all of the above types.\010\010\010"] = "AA-ban-cooking\010==============\010\010Prot\138ge les ingr\130dients utiles en interdisant leur utilisation en cuisine.\010\010Certaines plantes fournissent des graines ou des fibres. Si tu les cuisines toutes, il ne restera plus de quoi semer, tisser ou suturer les blessures. D'autres produits servent au brassage ou \133 des transformations utiles.\010\010Dans l'\130cran Cuisine, tu peux interdire chaque type d'ingr\130dient s\130par\130ment. Seuls les types pr\130sents dans tes r\130serves y apparaissent : les nouveaux produits demanderaient donc une nouvelle intervention.\010\010Cette commande prot\138ge des cat\130gories enti\138res, m\136me si tu ne les poss\138des pas encore. Elle ne prot\138ge pas les aliments qui servent uniquement \133 \136tre mang\130s ou cuisin\130s, comme la viande ou les noix non cultivables.\010\010Usage (commande propre \133 cette variante du mod) :\010  AA-ban-cooking <type|all> [<type> ...] [options]\010\010Types \133 saisir tels quels :\010  all : toutes les cat\130gories ci-dessous.\010  booze : boissons alcoolis\130es.\010  brew : plantes et r\130coltes pouvant \136tre brass\130es.\010  honey : miel.\010  mill : plantes et r\130coltes pouvant \136tre moulues.\010  milk : lait.\010  oil : huile.\010  plant_milk : laits v\130g\130taux pouvant donner du tofu.\010  roast : r\130coltes \133 transformer, comme les cerises de caf\130.\010  syrup : sirop.\010  seed_items : plantes et r\130coltes fournissant des graines.\010  seeds : graines.\010  tallow : suif.\010  thread : plantes et r\130coltes pouvant fournir du fil.\010\010Exemples :\010  AA-ban-cooking all\010  AA-ban-cooking oil tallow\010  AA-ban-cooking --unban oil\010\010Tu peux aussi r\130autoriser chaque ingr\130dient dans Cuisine, avec l'ic\147ne de cuisson. L'option --unban r\130autorise une cat\130gorie enti\138re. L'option --verbose affiche les types trait\130s ; --help affiche cette aide.\010\010Le texte d'origine emploie parfois ban-cooking : ici, utilise AA-ban-cooking pour cette variante.",
}

local AA_MAIN_HELP="\010Advanced Agriculture\010===========\010\010Tags: fort | gameplay | jobs | plants\010\010Controls the Advanced Agriculture modules.\010\010If a module is not specified after status, then the\010state of every module will be displayed.\010\010Note that seedcaps is globally enabled or disabled as it\010affects game settings. All other modules will have\010per-world settings.\010\010Available commands:\010    enable <module>\010    disable <module>\010    help <module (optional)>\010    status <module (optional)>\010\010Available modules:\010    byproducts: Creates byproducts from jobs\010    harvesting: Provides growths on farm plot harvest\010    seedcaps: Changes game seed caps to sane values\010    seedsfromcooking: Cooking creates seeds\010    shrubcleanup: Removes dead shrubs seasonally\010\010Usage\010-----\010    advanced-agriculture status\010    advanced-agriculture enable seedcaps\010    advanced-agriculture disable harvesting\010"
local AA_BAN_HELP="\010\010AA-ban-cooking\010=================\010Tags: fort | productivity | items | plants\010\010Command: AA-ban-cooking\010\010\009Protect useful items from being cooked.\010\010Some cookable ingredients have other important uses. For example, seed giving plants and growths can be cooked, but if you cook them all, then your farmers will have no seeds to plant in the fields. Similarly, thread producing items can be cooked, but if you do that, then your weavers will have nothing to weave into cloth and your doctors will have nothing to use for stitching up injured dwarves.\010\010If you open the Kitchen screen, you can select individual item types and choose to ban them from cooking. To prevent all your booze from being cooked, for example, you\226\128\153d select the Booze tab and then click each of the visible types of booze to prevent them from being cooked. Only types that you have in stock are shown, so if you acquire a different type of booze in the future, you have to come back to this screen and ban the new types.\010\010Instead of doing all that clicking, ban-cooking can ban entire classes of items (e.g. all types of booze) in one go. It can even ban types that you don\226\128\153t have in stock yet, so when you do get some in stock, they will already be banned. It will never ban items that are only good for eating or cooking, like meat or non-plantable nuts. It is usually a good idea to run ban-cooking all as one of your first actions in a new fort.\010\010If you want to re-enable cooking for a banned item type, you can go to the Kitchen screen and un-ban whatever you like by clicking on the \226\128\156cook\226\128\157 icon. You can also un-ban an entire class of items with the ban-cooking --unban option.\010Usage\010\010ban-cooking <type|all> [<type> ...] [<options>]\010\010Valid types are:\010    all (everything below)\010    booze (drinks)\010    brew (brewable plants and growths)\010    honey\010    mill (millable plants and growths)\010    milk\010    oil\010    plant_milk (only plant milks that can be processed into tofu)\010    roast (growths that have processing chains, such as coffee cherries)\010    syrup\010    seed_items (plants and growths which produce seeds)\010    seeds\010    tallow\010    thread (plants and growths which can be spun into thread)\010\010It is possible to include multiple types or all types in a single ban-cooking command: ban-cooking oil tallow will ban both oil and tallow from cooking. ban-cooking all will ban all of the above types.\010\010\010"
local AA_NAMES = {
    ['advanced-agriculture']=true, ['AA-ban-cooking']=true,
    ['internal/advanced-harvesting']=true, ['internal/advanced-planting']=true,
    ['internal/byproduct-system']=true, ['internal/seed-caps']=true,
    ['internal/seeds-from-cooking']=true, ['internal/shrub-cleanup']=true,
}
function traduire_aa(s)
    if type(s)~='string' or not actif() then return s end
    if AA_TEXT[s] then return AA_TEXT[s] end
    -- helpdb may strip the RST title/tags; use unique full-help signatures.
    if s:find('Controls the Advanced Agriculture modules.',1,true)
            and s:find('advanced-agriculture enable seedcaps',1,true) then
        return AA_TEXT[AA_MAIN_HELP]
    end
    if s:find('Protect useful items from being cooked.',1,true)
            and s:find('plant_milk',1,true) then
        return AA_TEXT[AA_BAN_HELP]
    end
    local module,state=s:match('^Module ([%w_-]+) is (enabled)%.$')
    if not module then module,state=s:match('^Module ([%w_-]+) is (disabled)%.$') end
    if module then return 'Module '..module..' : '..(state=='enabled' and 'activ‚.' or 'd‚sactiv‚.') end
    module=s:match('^(.-) is not a valid module%.$')
    if module then return 'Module inconnu : '..module..'.' end
    module=s:match('^(.-) can only be used in Fortress Mode%.$')
    if module then return module..' fonctionne uniquement en mode Forteresse.' end
    local n=s:match('^unbanned (%d+) types%.$')
    if n then return n..' types r‚autoris‚s en cuisine.' end
    n=s:match('^banned (%d+) types%.$')
    if n then return n..' types interdits en cuisine.' end
    local item=s:match('^(.-) has been unbanned!$')
    if item then return traduire(item)..' : cuisine r‚autoris‚e.' end
    item=s:match('^(.-) has been banned!$')
    if item then return traduire(item)..' : cuisine interdite.' end
    return s
end
local function aa_original(name)
    if not AA_NAMES[name] or type(dfhack.findScript)~='function' then return false end
    local path=dfhack.findScript(name)
    if type(path)~='string' then return false end
    path=path:gsub('\\','/')
    return path:match('/advanced_agriculture[^/]*/scripts_modactive/')~=nil
        or path:match('/advanced_agriculture[^/]*/scripts_modinstalled/')~=nil
end
local aa_print=print
local function aa_output(...)
    local args=table.pack(...)
    for i=1,args.n do if type(args[i])=='string' then args[i]=traduire_aa(args[i]) end end
    return aa_print(table.unpack(args,1,args.n))
end
if type(dfhack.run_script_with_env)=='function' then
    if not dfhack.__pgm_aa_run_original then
        dfhack.__pgm_aa_run_original=dfhack.run_script_with_env
    end
    local original=dfhack.__pgm_aa_run_original
    dfhack.run_script_with_env=function(vars,name,flags,...)
        if not aa_original(name) or (vars and vars.print~=nil) then
            local returned=table.pack(original(vars,name,flags,...))
            return table.unpack(returned,1,returned.n)
        end
        local scoped={}
        for k,v in pairs(vars or {}) do scoped[k]=v end
        scoped.print=aa_output
        if not scoped.dfhack then
            scoped.dfhack=setmetatable({script_help=function(requested,extension)
                if requested==nil or requested==name then
                    if name=='AA-ban-cooking' then return AA_BAN_HELP end
                    if name=='advanced-agriculture' then return AA_MAIN_HELP end
                end
                return dfhack.script_help(requested,extension)
            end},{__index=dfhack})
        end
        -- Keep this frame: DFHack discovers the current script name via debug locals.
        local returned=table.pack(original(scoped,name,flags,...))
        return table.unpack(returned,1,returned.n)
    end
    -- Already-loaded modules: only adjust their own output environment.
    -- Do not execute/load any mod, callback, command or gameplay function here.
    for path,script in pairs(dfhack.internal and dfhack.internal.scripts or {}) do
        if type(path)=='string' and type(script.env)=='table' then
            local normalized=path:gsub('\\','/')
            for name in pairs(AA_NAMES) do
                if aa_original(name) and normalized==dfhack.findScript(name):gsub('\\','/')
                        and (rawget(script.env,'print')==nil or rawget(script.env,'print')==aa_output) then
                    script.env.print=aa_output
                end
            end
        end
    end
end

-- PGM v30 : aide DFHack en francais (traducfr/aide_dfhack.txt, cp850).
-- Format : "@@ nom" puis "court: resume" puis l'aide complete. Outil absent -> aide anglaise intacte.
local AIDE_FR=nil
local AIDE_DONNEES=[==[
@@ 3dveins
court: R‚‚crit les filons pour qu'ils s'‚tendent en 3D.
@@ adaptation
court: RŠgle l'adaptation aux cavernes d'une cr‚ature.
@@ add-recipe
court: Ajoute des recettes d'artisanat … une civilisation.
@@ add-spatter
court: Ajoute poisons et effets magiques aux armes.
@@ add-thought
court: Ajoute une pens‚e … la cr‚ature choisie.
@@ advtools
court: Outils pratiques pour le mode aventure.
@@ agitation-rebalance
court: Faune agit‚e et invasions de cavernes moins tenaces.
@@ alias
court: Cr‚e des raccourcis pour d'autres commandes DFHack.
@@ allneeds
court: R‚sume les besoins d'un nain ou de toute la forteresse.
@@ animal-control
court: Voir, abattre ou castrer des groupes d'animaux.
@@ aquifer
court: Ajoute, retire ou modifie des aquifŠres.
@@ armoks-blessing
court: Donne des caract‚ristiques sup‚rieures aux nains.
@@ assign-attributes
court: RŠgle les attributs physiques et mentaux.
@@ assign-beliefs
court: RŠgle les croyances et valeurs d'une cr‚ature.
@@ assign-facets
court: RŠgle les traits de personnalit‚.
@@ assign-goals
court: RŠgle les objectifs et rˆves d'une cr‚ature.
@@ assign-minecarts
court: Attribue des wagonnets aux itin‚raires de transport.
@@ assign-preferences
court: Voir ou r‚gler les pr‚f‚rences d'une cr‚ature.
@@ assign-skills
court: RŠgle les comp‚tences d'une cr‚ature.
@@ autobutcher
court: Abat automatiquement le b‚tail en surplus.
@@ autocheese
court: Lance la fabrication de fromage selon le lait en stock.
@@ autochop
court: Coupe des arbres quand le stock de b–ches baisse.
autochop
========

tiquettes : fort | auto | plants

Commande : "autochop"

  Coupe des arbres quand le stock de b–ches baisse.

Marque automatiquement des arbres … couper quand les b–ches manquent. Il peut aussi garder certains terriers sans arbres : les caravanes ont toujours un chemin jusqu'au d‚p“t, et aucun arbre ne pousse contre vos murs pour offrir un passage aux envahisseurs.

Une fois par jour de jeu, autochop compte vos b–ches et marque des arbres. Les b–ches interdites ou inaccessibles (zones cach‚es, sous l'eau...) ne comptent pas, et les arbres inaccessibles ne sont jamais marqu‚s.

Pour la fenˆtre de r‚glage, voir gui/autochop.


Utilisation
-----------

   enable autochop
   autochop [status]
   autochop (designate|undesignate)
   autochop target <max> [<min>]
   autochop (chop|nochop) <terrier>[,<terrier>...]
   autochop (clearcut|noclearcut) <terrier>[,<terrier>...]
   autochop (protect|unprotect) <type>[,<type>...] <terrier>[,<terrier>...]


Exemples
--------

Garder environ 200 b–ches en stock, coup‚es partout o— c'est accessible :

   enable autochop

Garder environ 500 b–ches, coup‚es dans le terrier "TreeFarm", et garder d‚gag‚s le chemin des caravanes et les abords du mur ("CaravanPath" et "OuterWall") :

   enable autochop
   autochop target 500
   autochop chop TreeFarm
   autochop clearcut CaravanPath,OuterWall

Retirer d'un terrier ("PicnicArea") tous les arbres qui ne donnent pas de nourriture :

   autochop clearcut PicnicArea
   autochop protect brewable,edible,cookable PicnicArea
   autochop designate


Commandes
---------

"status"
   Affiche le r‚glage actuel et les statistiques utiles.

"designate"
   Marque tout de suite des arbres selon le r‚glage, mˆme si "autochop" n'est pas activ‚.

"undesignate"
   Retire le marquage de tous les arbres.

"target <max> [<min>]"
   Nombre de b–ches voulu en stock. Sans minimum, il vaut 20 % de moins que le maximum. Par d‚faut "200" (minimum "160").

"(no)chop <terrier>[,<terrier>...]"
   Ne coupe que dans ces terriers au lieu de toute la carte. Terriers par nom ou par identifiant.

"(no)clearcut <terrier>[,<terrier>...]"
   Garde ces terriers sans arbres : tout arbre qui y apparaŒt est marqu‚ … couper en priorit‚ 2.

"(un)protect <type>[,<type>...] <terrier>[,<terrier>...]"
   pargne les arbres qui donnent ces nourritures : "brewable" (… brasser), "edible" (comestible), "cookable" (… cuisiner).
@@ autoclothing
court: GŠre les ordres de fabrication de vˆtements.
autoclothing
============

tiquettes : fort | auto | workorders

Commande : "autoclothing"

  GŠre les ordres de fabrication de vˆtements.

D‚finissez un ® uniforme ¯ pour vos civils : "autoclothing" suit le stock de ces vˆtements (y compris ceux d‚j… port‚s) et cr‚e des ordres de travail quand le stock passe sous le seuil voulu par citoyen.

Pour choisir entre autoclothing et tailor, voir la derniŠre partie.


Utilisation
-----------

   autoclothing
   autoclothing <matiŠre> <objet>
   autoclothing <matiŠre> <objet> <quantit‚>
   autoclothing clear <matiŠre> <objet>

"<matiŠre>" : "cloth" (tissu), "silk" (soie), "yarn" (laine) ou "leather" (cuir). "<objet>" : tout ce que votre civilisation sait fabriquer, comme "dress" (robe) ou "mitten" (moufle).

La quantit‚ est **par citoyen** : gardez des valeurs faibles. "1" en fait un par citoyen, "2" donne … chacun un vˆtement de rechange. "1" suffit en g‚n‚ral.

Sans paramŠtre, affiche le r‚sum‚ des vˆtements g‚r‚s et la situation de la forteresse. Avec une matiŠre et un objet mais sans quantit‚, affiche le r‚glage actuel.


Exemples
--------

"autoclothing cloth "short skirt" 1"
   Chaque citoyen aura une jupe courte en tissu (tant qu'il y a du tissu).

"autoclothing cloth dress"
   Affiche le nombre de robes en tissu pr‚vu par citoyen.

"autoclothing clear cloth "short skirt""
   Arrˆte la fabrication des jupes courtes en tissu r‚gl‚e plus haut.


Lequel activer : autoclothing ou tailor ?
-----------------------------------------

Les deux cr‚ent des ordres pour les vˆtements n‚cessaires, mais ne choisissent pas de la mˆme fa‡on quand et quoi commander.

Activez "autoclothing" si :

* vous voulez r‚gler chaque type de vˆtement pour d‚cider pr‚cis‚ment ce que portent vos citoyens ;
* vous voulez une r‚serve de vˆtements avant d'en avoir besoin.

Activez tailor si :

* vous voulez des citoyens habill‚s, peu importe comment ;
* vous voulez un outil qui marche bien sans r‚glage.

Vous pouvez activer les deux : r‚glez quelques types dans "autoclothing" (par exemple des robes pour presque tout le monde) et laissez tailor g‚rer le reste.
@@ autodump
court: Rassemble ou d‚truit les objets marqu‚s … jeter.
@@ autofarm
court: Choisit automatiquement les cultures des champs.
@@ autofish
court: GŠre la pˆche selon le stock de poisson.
@@ autolabor
court: GŠre automatiquement les m‚tiers des nains.
@@ autonestbox
court: Place les femelles pondeuses dans les nichoirs.
autonestbox
===========

tiquettes : fort | auto | animals

Commande : "autonestbox"

  Place les femelles pondeuses dans les nichoirs.

Cr‚ez des enclos/pƒturages sur les cases de nichoirs construits. Si l'enclos fait plus de 1x1, le nichoir doit ˆtre dans le coin en haut … gauche. Un seul animal par enclos, quelle que soit sa taille. Les pondeuses qui broutent (comme les oiseaux-‚lans) sont ignor‚es : elles mourraient de faim sur 1x1. Seuls les animaux domestiques, ou apprivois‚s avec un dresseur attitr‚, sont plac‚s : une pondeuse sauvage … moiti‚ dress‚e pourrait saccager vos nichoirs en redevenant sauvage.


Utilisation
-----------

"enable autonestbox"
   Cherche en continu les pondeuses sans enclos et les place dans les nichoirs.

"autonestbox"
   Affiche l'‚tat actuel.

"autonestbox now"
   Lance une recherche et un placement tout de suite, mˆme si le module n'est pas activ‚.
@@ autonick
court: Donne des surnoms uniques au hasard aux nains.
autonick
========

tiquettes : fort | productivity | units

Commande : "autonick"

  Donne des surnoms uniques au hasard aux nains.

Les surnoms sont tir‚s au hasard dans le fichier "dfhack-config/autonick.txt", que vous pouvez remplir avec vos noms pr‚f‚r‚s.

Les nains qui ont d‚j… un surnom le gardent, et personne d'autre ne re‡oit ce surnom.

S'il y a moins de surnoms que de nains, les nains restants n'en ont pas.


Utilisation
-----------

   autonick all [<options>]

Avec la commande "repeat", les nouveaux migrants re‡oivent un surnom automatiquement :

   repeat -name autonick -time 3 -timeUnits months -command [ autonick all ]


Options
-------

"-q", "--quiet"
   N'indique pas combien de nains ont re‡u un surnom.


Format du fichier
-----------------

Le fichier "dfhack-config/autonick.txt" est simple :

* un surnom par ligne ;
* les lignes vides, celles qui commencent par "#" et les doublons sont ignor‚s.

Ajoutez tous les surnoms que vous voulez !
@@ autoslab
court: Grave des dalles pour les citoyens fant“mes.
@@ autotraining
court: Envoie les nains s'entraŒner pour leur besoin martial.
@@ ban-cooking
court: Empˆche de cuisiner les ingr‚dients utiles.
ban-cooking
===========

tiquettes : fort | productivity | items | plants

Commande : "ban-cooking"

  Empˆche de cuisiner les ingr‚dients utiles.

Certains ingr‚dients ont d'autres usages importants. Les graines se cuisinent, mais si vous les cuisinez toutes, vos fermiers n'auront plus rien … planter. L'alcool aussi, mais vos nains n'auront alors plus rien (de bon) … boire.

Dans l'‚cran Cuisine, vous pouvez interdire chaque type d'ingr‚dient un par un. Pour prot‚ger tout l'alcool, il faut filtrer sur ® Boissons ¯ puis cliquer sur chaque type affich‚. Seuls les types en stock apparaissent : un nouvel alcool acquis plus tard devra ˆtre interdit … son tour.

"ban-cooking" interdit d'un coup des familles entiŠres (par exemple tous les alcools), mˆme ceux que vous n'avez pas encore : ils seront d‚j… interdits … leur arriv‚e. Il n'interdit jamais ce qui ne sert qu'… manger, comme la viande ou les noix non plantables. Lancez de pr‚f‚rence "ban-cooking all" dŠs le d‚but d'une forteresse ; vous pouvez l'ajouter au d‚marrage automatique dans gui/control-panel.

Pour autoriser de nouveau un type, cliquez sur l'ic“ne ® cuisiner ¯ dans l'‚cran Cuisine, ou autorisez une famille entiŠre avec l'option "--unban".


Utilisation
-----------

   ban-cooking <type|all> [<type> ...] [<options>]

Types possibles :

* "booze" (alcools)
* "brew" (plantes … brasser)
* "fruit" (fruits)
* "honey" (miel)
* "milk" (lait)
* "mill" (plantes … moudre)
* "oil" (huile)
* "seeds" (graines plantables et ce qui en donne)
* "tallow" (suif)
* "thread" (fil)

Dans le jeu de base, rien de ce qui se moud ou donne du fil ne se cuisine : ces types ne servent qu'avec des mods qui en ajoutent.


Exemples
--------

"ban-cooking oil tallow"
   Interdit de cuisiner toutes les huiles et tous les suifs.

"ban-cooking all"
   Interdit de cuisiner tout ce qui a un autre usage. Peut se lancer au d‚marrage via gui/control-panel.


Options
-------

"-u", "--unban"
   Autorise de nouveau les types indiqu‚s.

"-v", "--verbose"
   Affiche chaque interdiction.
@@ blueprint
court: Enregistre la carte dans un plan quickfort.
@@ bodyswap
court: Prend le contr“le de n'importe quelle cr‚ature visible.
@@ brainwash
court: Donne une personnalit‚ id‚ale … un nain.
@@ build-now
court: Termine instantan‚ment les constructions.
@@ buildingplan
court: Planifie des bƒtiments, avec ou sans mat‚riaux.
@@ burial
court: Cr‚e des tombes pour les cercueils sans zone.
burial
======

tiquettes : fort | productivity | buildings

Commande : "burial"

  Cr‚e des tombes pour les cercueils sans zone.

Cr‚e une tombe de 1x1 pour chaque cercueil construit qui n'est dans aucune zone.


Utilisation
-----------

   "burial [<options>]"


Exemples
--------

"burial"
   Cr‚e une tombe pour tous, pour chaque cercueil sans zone de la carte.

"burial -z"
   Cr‚e les tombes seulement au niveau actuel.

"burial -c"
   Tombes r‚serv‚es aux citoyens.

"burial -p"
   Tombes r‚serv‚es aux animaux de compagnie.

"burial -cp"
   Tombes sans inhumation automatique (citoyens et animaux) : les d‚funts sont attribu‚s … la main.


Options
-------

"-z", "--cur-zlevel"
   Seulement au niveau actuel.

"-c", "--citizens-only"
   Inhumation automatique des citoyens seulement.

"-p", "--pets-only"
   Inhumation automatique des animaux de compagnie seulement.
@@ burrow
court: Modifie rapidement les terriers et leurs occupants.
@@ caravan
court: Modifie les caravanes pr‚sentes sur la carte.
@@ catsplosion
court: Provoque des grossesses.
@@ changeitem
court: Change la matiŠre, la qualit‚ ou le type d'un objet.
@@ changelayer
court: Change la matiŠre d'une couche g‚ologique entiŠre.
@@ changevein
court: Change la matiŠre d'un filon.
@@ cleanconst
court: Nettoie les mat‚riaux de construction.
@@ cleaners
court: Commandes pour nettoyer les ‚claboussures.
@@ cleanowned
court: Confisque et jette les d‚chets poss‚d‚s par les nains.
cleanowned
==========

tiquettes : fort | productivity | items

Commande : "cleanowned"

  Confisque et jette les d‚chets poss‚d‚s par les nains.

Les nains renoncent … leurs objets ‚parpill‚s ou trŠs us‚s, qui sont ensuite marqu‚s … jeter. Vos nains abandonnent enfin leur nourriture pourrie et leurs pagnes en lambeaux pour aller en chercher des neufs !


Utilisation
-----------

   cleanowned [<types>] [dryrun]

Sans paramŠtre, "cleanowned" confisque et jette les objets pourris et la nourriture poss‚d‚e laiss‚e par terre. Avec "dryrun", il affiche seulement ce qu'il ferait, sans rien confisquer.

Vous pouvez ajouter d'autres types d'objets :

"scattered"
   Tous les objets ‚parpill‚s par terre.

"x"
   Les objets us‚s (x) et plus.

"X"
   Les objets trŠs us‚s (X) et plus.

"nodump"
   Les nains lƒchent les objets confisqu‚s, sans qu'ils soient marqu‚s … jeter.

Ou bien confisquez tous les objets poss‚d‚s avec "all".


Exemple
-------

"cleanowned scattered X"
   Confisque et jette la nourriture pourrie ou abandonn‚e, les d‚chets par terre et les objets trŠs us‚s (X) et plus.
@@ clear-smoke
court: Retire toute la fum‚e de la carte.
@@ clear-webs
court: Retire toutes les toiles de la carte.
@@ cls
court: Efface l'‚cran du terminal.
@@ colonies
court: GŠre les colonies de vermine et les ruches.
@@ combat-harden
court: RŠgle l'aguerrissement au combat d'une cr‚ature.
@@ combine
court: Regroupe les objets empilables.
combine
=======

tiquettes : fort | productivity | items | plants | stockpile

Commande : "combine"

  Regroupe les objets empilables.

® D‚fragmente ¯ vos objets sans cr‚er de piles d‚mesur‚es. Dans chaque stock, les objets semblables sont regroup‚s en piles moins nombreuses et plus grandes. Les objets hors des stocks, ou dans des stocks diff‚rents, ne sont pas regroup‚s.


Utilisation
-----------

   combine (all|here) [<options>]


Exemples
--------

"combine"
   Affiche l'aide.

"combine all --dry-run"
   Montre ce qui serait regroup‚, tous types et tous stocks.

"combine all"
   Regroupe les piles de tous types dans tous les stocks.

"combine all --types=meat,plant"
   Regroupe les piles de viande et de plantes dans tous les stocks.

"combine here"
   Regroupe les piles du stock choisi.


Commandes
---------

"all"
   Tous les stocks.

"here"
   Le stock choisi, celui de l'objet choisi, ou celui de la liste d'objets affich‚e.


Options
-------

"-d", "--dry-run"
   Montre ce qui serait regroup‚ sans rien faire.

"-t", "--types <types s‚par‚s par des virgules>"
   Types d'objets … regrouper. Par d‚faut "all". Types possibles :

   all :
      tous les types ci-dessous.

   ammo :
      munitions. 25 au maximum.

   drink :
      boissons en tonneaux ou en pots. 25 au maximum.

   fat :
      fromage, graisse, suif et autres. 5 au maximum.

   fish :
      poisson cru ou pr‚par‚, ainsi que tous les oeufs. 5 au maximum.

   food :
      repas pr‚par‚s. 20 au maximum.

   meat :
      viande. 5 au maximum.

   parts :
      morceaux de cadavres. 30 par matiŠre au maximum.

   plant :
      plantes et leurs produits. 5 au maximum.

   powders :
      teintures et autres poudres (sauf sable et plƒtre). 10 au maximum.

"-q", "--quiet"
   N'affiche pas le r‚sum‚ final.

"-v", "--verbose n"
   Affichage d‚taill‚ pour le d‚bogage, n de 1 … 4.


Remarques
---------

Un objet n'est pas regroup‚ si :

1. il n'est pas dans un stock ;
2. c'est du sable ou du plƒtre ;
3. il est pourri, interdit, marqu‚ … jeter ou … fondre, en feu, enferm‚, poss‚d‚ par un marchand, un ennemi ou un nain, ou pris dans une toile ;
4. c'est un morceau de cadavre non d‚coup‚.

Dans un contenant li‚ … un stock, une pile ne peut pas d‚passer le volume du contenant.

Un objet est regroup‚ avec des objets semblables s'il :

1. a la mˆme race et caste (s'il en a) et le mˆme type d'objet ;
2. a le mˆme type, la mˆme matiŠre et la mˆme qualit‚. Un chef-d'oeuvre n'est regroup‚ qu'avec ceux du mˆme artisan.
@@ confirm
court: Demande confirmation avant les actions destructrices.
@@ control-panel
court: Configure DFHack et gŠre ses outils actifs.
@@ createitem
court: Cr‚e n'importe quel objet.
@@ cursecheck
court: RepŠre les cr‚atures maudites.
@@ deathcause
court: Indique la cause de la mort d'une cr‚ature.
@@ deep-embark
court: Commence une forteresse en profondeur.
@@ deramp
court: Retire les rampes marqu‚es pour suppression.
@@ deteriorate
court: Fait pourrir cadavres, vˆtements ou nourriture.
@@ die
court: Quitte DF tout de suite, sans sauvegarder.
@@ dig
court: Commandes pour marquer les cases … creuser.
@@ dig-now
court: Termine instantan‚ment le creusement marqu‚.
@@ diplomacy
court: Voir ou modifier les relations diplomatiques.
@@ disable
court: D‚sactive un outil DFHack … effet durable.
@@ dwarfvet
court: Permet de soigner les animaux … l'h“pital.
@@ edgescroll
court: Fait d‚filer la carte quand la souris touche le bord.
@@ elevate-mental
court: Donne des attributs mentaux id‚aux … un nain.
@@ elevate-physical
court: Donne des attributs physiques id‚aux … un nain.
@@ embark-anyone
court: S'installer avec n'importe quelle civilisation.
@@ embark-skills
court: RŠgle les comp‚tences des nains … l'installation.
@@ emigration
court: Les nains stress‚s peuvent quitter la forteresse.
@@ empty-bin
court: Vide le contenu des contenants par terre.
@@ enable
court: Active un outil DFHack … effet durable.
@@ entomb
court: Met n'importe quel cadavre dans une tombe.
@@ export-world-map
court: Exporte la carte du monde pour des outils externes.
@@ export-worldgen
court: Exporte les paramŠtres de cr‚ation du monde.
@@ exportlegends
court: Exporte les l‚gendes d‚taill‚es.
@@ exterminate
court: Tue des cr‚atures.
@@ extinguish
court: teint les incendies.
@@ fastdwarf
court: Nains rapides qui finissent tout instantan‚ment.
@@ feature
court: GŠre la d‚couverte des ‚l‚ments de la carte.
@@ fillneeds
court: Satisfait temporairement les besoins d'une cr‚ature.
@@ filltraffic
court: Remplit une zone de circulation depuis le curseur.
@@ firestarter
court: Met le feu.
@@ fix/archery-practice
court: R‚pare carquois et munitions pour le tir … l'arc.
@@ fix/blood-del
court: Retire les liquides inutiles des caravanes.
@@ fix/civil-war
court: Met fin … une guerre civile.
@@ fix/codex-pages
court: Ajoute des pages aux ‚crits qui n'en ont pas.
@@ fix/corrupt-jobs
court: Retire les tƒches corrompues (id -1).
@@ fix/dead-units
court: Retire les morts de la liste pour les migrants.
@@ fix/drop-webs
court: Fait tomber les toiles flottantes.
@@ fix/dry-buckets
court: Rend utilisables les seaux d'eau abandonn‚s.
@@ fix/empty-wheelbarrows
court: Vide les brouettes bloqu‚es.
@@ fix/engravings
court: R‚pare les cases qu'on ne peut plus graver.
@@ fix/general-strike
court: Empˆche les nains de refuser de travailler.
@@ fix/loyaltycascade
court: Arrˆte les nains qui se battent entre eux.
@@ fix/noexert-exhaustion
court: Les cr‚atures NOEXERT ne se fatiguent plus.
@@ fix/occupancy
court: R‚pare les cases occup‚es par erreur.
@@ fix/ownership
court: R‚pare les liens de propri‚t‚.
@@ fix/population-cap
court: Fait respecter la limite de population.
@@ fix/protect-nicks
court: Empˆche l'effacement des surnoms.
@@ fix/retrieve-units
court: Fait entrer les cr‚atures bloqu‚es hors carte.
@@ fix/sleepers
court: R‚veille les dormeurs d'un camp bloqu‚s.
@@ fix/stable-temp
court: Corrige les baisses de FPS dues … la temp‚rature.
@@ fix/stuck-instruments
court: D‚bloque les instruments bugg‚s.
@@ fix/stuck-merchants
court: Renvoie les marchands bloqu‚s au bord de la carte.
@@ fix/stuck-squad
court: Permet de secourir une escouade perdue.
@@ fix/stuck-worship
court: D‚bloque les nains coinc‚s en priŠre.
@@ fix/stuck-written-materials
court: D‚bloque les ‚crits bugg‚s.
@@ fix/stuckdoors
court: Permet de fermer les portes rest‚es ouvertes.
@@ fix/symbol-unstick
court: D‚bloque les symboles de noblesse.
@@ fix/wildlife
court: Fait sortir la faune bloqu‚e pour de nouvelles vagues.
@@ flashstep
court: T‚l‚porte l'aventurier au curseur.
@@ flows
court: Compte les zones o— coulent des liquides.
@@ forbid
court: Interdit ou liste les objets interdits.
@@ force
court: D‚clenche des ‚v‚nements du jeu.
@@ forceequip
court: Place des objets dans l'inventaire d'une cr‚ature.
@@ fpause
court: Force la pause.
@@ full-heal
court: Soigne complŠtement la cr‚ature choisie.
@@ gaydar
court: Montre l'orientation amoureuse des cr‚atures.
@@ geld
court: Castre ou d‚castre des animaux.
@@ getplants
court: Marque des arbres … couper et des plantes … cueillir.
getplants
=========

tiquettes : fort | productivity | plants

Commande : "getplants"

  Marque des arbres … couper et des plantes … cueillir.

Indiquez par leur nom les arbres … couper et les arbustes … cueillir.


Utilisation
-----------

"getplants [-t|-s|-f] [<filtres>]"
   Liste les identifiants d'arbres et d'arbustes, ‚ventuellement filtr‚s.

"getplants <id> [<id> ...] [<options>]"
   Marque les arbres et arbustes de ces types … couper ou cueillir.


Exemples
--------

"getplants"
   Liste tous les identifiants.

"getplants -f -a"
   Cueille toutes les plantes de la carte qui donnent des graines … cultiver.

"getplants NETHER_CAP -n 10"
   Marque 10 chapeaux du n‚ant … couper.

"getplants --brewable -a"
   Marque tous les arbustes qu'on peut brasser en alcool.

"getplants --brewable"
   Liste les plantes … brasser.


Options
-------

"-t"
   Arbres seulement.

"-s"
   Arbustes seulement.

"-f"
   Seulement les arbustes qui donnent des graines … cultiver.

"-a"
   Toutes les plantes (en respectant "-t", "-s", "-f").

"-c"
   Retire les marquages au lieu de les poser.

"-x"
   Inverse la s‚lection : toutes les plantes sauf celles indiqu‚es.

"-v"
   Affiche le nombre de marquages par plante.

"-n <nombre>"
   Au plus ce nombre de plantes par espŠce.

"-d", "--dry-run"
   Indique combien de marquages seraient faits, sans rien changer.

"--brewable"
   Plantes qu'on peut brasser en alcool.

"--edible"
   Plantes dont une partie se mange crue.

"--oil"
   Plantes dont les graines, noix ou fruits donnent de l'huile.

"--cloth"
   Plantes qui donnent du fil.

"--dye"
   Plantes qui donnent de la teinture.

Les filtres se combinent : une plante qui r‚pond … l'un d'eux est retenue. Ils s'appliquent … toute la s‚lection : "getplants --brewable -x QUARRY_BUSH" marque toutes les plantes … brasser sauf les buissons de carriŠre.
@@ ghostly
court: Rend l'aventurier fant“me ou non.
@@ gui/adv-finder
court: Trouve et suit personnages et artefacts.
@@ gui/aquifer
court: Voir, ajouter, retirer ou modifier des aquifŠres.
@@ gui/autobutcher
court: Abat automatiquement le b‚tail en surplus.
@@ gui/autochop
court: Coupe des arbres quand le stock de b–ches baisse.
@@ gui/autodump
court: T‚l‚porte ou d‚truit des objets.
@@ gui/autofarm
court: RŠgle les seuils de cultures d'autofarm.
@@ gui/autofish
court: GŠre la pˆche selon le stock de poisson.
@@ gui/autotraining
court: Fenˆtre de r‚glage d'autotraining.
@@ gui/biomes
court: Affiche et examine les biomes de la carte.
@@ gui/blueprint
court: Enregistre la carte dans un plan quickfort.
@@ gui/civ-alert
court: Met vite les civils … l'abri.
@@ gui/confirm
court: Choisit les confirmations actives.
@@ gui/control-panel
court: Configure DFHack et gŠre ses outils actifs.
@@ gui/cp437-table
court: Clavier virtuel pour ‚crire … la souris.
@@ gui/create-item
court: Fait apparaŒtre des objets.
@@ gui/design
court: Marquage avec des formes (cercles, lignes...).
@@ gui/embark-anywhere
court: S'installer n'importe o—.
@@ gui/export-world-map
court: Exporte la carte du monde pour des outils externes.
@@ gui/family-affairs
court: GŠre les couples et provoque des grossesses.
@@ gui/gm-editor
court: Examine et modifie les donn‚es du jeu.
@@ gui/gm-unit
court: Examine et modifie une cr‚ature.
@@ gui/journal
court: Journal de la forteresse, ‚diteur de texte.
@@ gui/keybinds
court: GŠre visuellement les raccourcis DFHack.
@@ gui/launcher
court: Lanceur de commandes DFHack avec aide int‚gr‚e.
@@ gui/liquids
court: Peint des liquides sur la carte.
@@ gui/mass-remove
court: S‚lectionne en masse ce qu'il faut retirer.
@@ gui/masspit
court: D‚signe des cr‚atures … jeter dans une fosse.
@@ gui/mod-manager
court: GŠre les mods actifs.
@@ gui/notes
court: Panneau de notes li‚es … la carte.
@@ gui/notify
court: Affiche les notifications importantes.
@@ gui/overlay
court: D‚place les widgets DFHack … l'‚cran.
@@ gui/pathable
court: Montre les cases accessibles depuis le curseur.
@@ gui/petitions
court: Liste les accords de guildes et de temples.
@@ gui/prerelease-warning
court: Pr‚vient si DFHack est une version d'essai.
@@ gui/quantum
court: Cr‚e facilement des stocks quantiques.
@@ gui/quickcmd
court: Lance vite des commandes enregistr‚es.
@@ gui/quickfort
court: Applique des plans … la forteresse.
@@ gui/rename
court: Modifie les noms dans la langue du jeu.
@@ gui/reveal
court: R‚vŠle des cases de la carte.
@@ gui/sandbox
court: Cr‚e des cr‚atures, des arbres ou des objets.
@@ gui/seedwatch
court: GŠre graines et cuisine selon le stock de graines.
@@ gui/settings-manager
court: Importe et exporte les r‚glages de DF.
@@ gui/siegemanager
court: GŠre les engins de siŠge d'un coup d'oeil.
@@ gui/sitemap
court: Liste les gens, lieux et artefacts et y va.
@@ gui/spectate
court: Mode spectateur automatique.
@@ gui/suspendmanager
court: Suspend et reprend les tƒches intelligemment.
@@ gui/teleport
court: T‚l‚porte des cr‚atures n'importe o—.
@@ gui/tiletypes
court: ModŠle la carte case par case.
@@ gui/unit-info-viewer
court: Infos d‚taill‚es sur une cr‚ature.
@@ gui/unit-syndromes
court: D‚tails des syndromes.
@@ help
court: Affiche l'aide d'une commande ou d'un module.
@@ hermit
court: Tente le d‚fi de l'ermite, seul dans la forteresse.
@@ hfs-pit
court: Creuse un puits droit vers les enfers.
@@ hide
court: Cache la fenˆtre du terminal DFHack.
@@ hide-interface
court: Cache l'interface.
@@ hide-tutorials
court: Cache les didacticiels des nouvelles forteresses.
@@ hotkeys
court: Affiche les raccourcis DFHack de l'‚cran actuel.
@@ husbandry
court: Traite et tond les animaux automatiquement.
@@ idle-crafting
court: Les nains fabriquent seuls quand ils en ont besoin.
@@ immortal-cravings
court: Les immortels peuvent manger et boire.
@@ infinite-sky
court: Ajoute automatiquement des niveaux de ciel.
@@ install-info
court: Exporte des infos DFHack pour signaler un bug.
@@ instruments
court: Recettes et ordres de fabrication d'instruments.
@@ item
court: Actions en masse sur des groupes d'objets.
@@ justice
court: Modifie le systŠme judiciaire.
@@ keybinding
court: Cr‚e des raccourcis pour des commandes DFHack.
@@ kill-lua
court: Arrˆte proprement les scripts Lua en cours.
@@ labormanager
court: GŠre les m‚tiers des nains par les ‚quipes.
@@ lair
court: vite la dispersion des objets d'un site repris.
@@ launch
court: Projette vos ennemis d'un suplex volant.
@@ lever
court: Examine et actionne les leviers.
@@ light-aquifers-only
court: Transforme tous les aquifŠres en aquifŠres l‚gers.
@@ liquids
court: Place du magma, de l'eau ou de l'obsidienne.
@@ list-agreements
court: Liste les accords de guildes et de temples.
@@ list-waves
court: Montre les vagues de migrants et leur histoire.
@@ load
court: Charge et enregistre un module.
@@ locate-ore
court: Cherche les minerais sur la carte.
locate-ore
==========

tiquettes : fort | armok | productivity | map

Commande : "locate-ore"

  Cherche les minerais sur la carte.

Trouve une case d'un minerai donn‚ et la marque … creuser. Pour creuser **toutes** les cases de ce minerai, placez le curseur clavier dessus et lancez digtype.

Par d‚faut, seuls les filons d‚j… d‚couverts par vos nains sont cherch‚s.

Chercher un m‚tal peut trouver un minerai qui en contient plusieurs : chercher l'argent peut trouver de la t‚tra‚drite, qui contient argent et cuivre.


Utilisation
-----------

"locate-ore [list] [<options>]"
   Liste les minerais pr‚sents sur la carte.

"locate-ore <type> [<options>]"
   Trouve une case du minerai, centre la vue dessus et la marque … creuser.


Options
-------

"-a", "--all"
   Cherche aussi dans les filons non d‚couverts.


Exemples
--------

"locate-ore"
   Liste les minerais d‚couverts.

   locate-ore hematite
   locate-ore iron
   locate-ore silver --all
@@ logistics
court: Trie et achemine les objets des stocks surveill‚s.
@@ ls
court: Liste les commandes DFHack disponibles.
@@ machine-toggle
court: Modifie plaques de pression et engrenages construits.
@@ make-legendary
court: Rend l‚gendaires les comp‚tences du nain choisi.
@@ make-monarch
court: Couronne la cr‚ature choisie.
@@ makeown
court: Fait de la cr‚ature choisie un citoyen.
@@ markdown
court: Exporte le texte affich‚ en fichier Markdown.
@@ migrants-now
court: D‚clenche une vague de migrants.
@@ misery
court: Rend les citoyens plus malheureux.
@@ multicmd
court: Lance plusieurs commandes DFHack.
@@ necronomicon
court: Trouve les livres des secrets de la vie et de la mort.
@@ nestboxes
court: ProtŠge les oeufs f‚cond‚s dans les nichoirs.
nestboxes
=========

tiquettes : fort | auto | animals

  ProtŠge les oeufs f‚cond‚s dans les nichoirs.

Interdit automatiquement les oeufs f‚cond‚s qui couvent dans un nichoir, pour que les nains ne viennent pas les ramasser pour les manger. Les oeufs ‚closent normalement, mˆme interdits.

Pour choisir quels oeufs prot‚ger, placez les nichoirs … prot‚ger dans un terrier et lancez "nestboxes burrow <nom_du_terrier>". "nestboxes all" revient … la protection de tous les oeufs f‚cond‚s.


Utilisation
-----------

   enable nestboxes
   nestboxes burrow <nom_du_terrier>
   nestbox all
@@ notes
court: GŠre les notes li‚es … la carte.
@@ on-new-fortress
court: Lance des commandes au d‚but d'une forteresse.
@@ once-per-save
court: Lance des commandes une seule fois par monde.
@@ open-legends
court: Ouvre les l‚gendes depuis la forteresse ou l'aventure.
@@ orders
court: GŠre les ordres de travail.
orders
======

tiquettes : fort | productivity | workorders

Commande : "orders"

  GŠre les ordres de travail.


Utilisation
-----------

"orders list"
   Liste les ordres d‚j… export‚s, bibliothŠque d'ordres comprise.

"orders export <nom>"
   Enregistre tous les ordres de travail actuels dans un fichier.

"orders import <nom>"
   Importe les ordres indiqu‚s. Ils s'ajoutent aux ordres existants, qui ne sont pas effac‚s.

"orders clear"
   Supprime tous les ordres de travail de la forteresse.

"orders recheck [this]"
   Repasse en ® V‚rification ¯ (au lieu de ® Actif ¯) tous les ordres dont les conditions peuvent ˆtre rev‚rifi‚es. Avec "this", seul l'ordre dont la page des conditions est ouverte est concern‚. Le gestionnaire r‚‚value alors les conditions. Utile quand les objets n‚cessaires ont disparu depuis le lancement de l'ordre et que les annulations de tƒches s'enchaŒnent.

"orders sort"
   Trie les ordres par fr‚quence pour que les ordres r‚p‚t‚s ne bloquent pas les ordres uniques : d'abord les ordres uniques, puis annuels, saisonniers, mensuels et enfin quotidiens.

Pour garder les ordres toujours tri‚s, ajoutez cette commande au fichier "dfhack-config/init/onMapLoad.init" :

   repeat -name orders-sort -time 1 -timeUnits days -command [ orders sort ]

Les ordres export‚s sont enregistr‚s dans le dossier "dfhack-config/orders", o— vous pouvez les consulter, les modifier ou les supprimer.


Exemples
--------

"orders export mesordres"
   Exporte les ordres actuels dans "dfhack-config/orders/mesordres.json".

"orders import library/basic"
   Importe de la bibliothŠque les ordres qui gardent la forteresse pourvue en produits de base.


Panneaux (overlays)
-------------------

Le module orders ajoute plusieurs panneaux. Activez-les dans l'onglet ® Overlays ¯ de gui/control-panel, d‚placez ceux qui sont visibles avec gui/overlay.


orders.importexport
~~~~~~~~~~~~~~~~~~~

Ajoute un panneau … l'‚cran des ordres de travail, avec des raccourcis pour exporter, importer, trier, effacer et rev‚rifier les conditions. Les raccourcis se cliquent aussi comme des boutons. L'effacement demande confirmation.


orders.recheck
~~~~~~~~~~~~~~

Dans l'‚cran des conditions d'un ordre, un petit panneau permet de rev‚rifier les conditions de cet ordre seulement. Utile quand les conditions ‚taient vraies au lancement mais ne le sont plus, et que l'ordre s'annule sans cesse.


orders.skillrestrictions et orders.laborrestrictions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Pour les ateliers *sans* maŒtre d'atelier, un curseur limite les ouvriers selon leur niveau de comp‚tence.

Faute de place, certains niveaux sont regroup‚s avec le rang sup‚rieur :

* ® Comp‚tent ¯ comprend ® Correct ¯
* ® Habile ¯ comprend ® Qualifi‚ ¯
* ® Expert ¯ comprend ® Adepte ¯
* ® Accompli ¯ comprend ® Professionnel ¯
* ® MaŒtre ¯ comprend ® Excellent ¯
* ® Grand maŒtre ¯ comprend ® Haut maŒtre ¯

Pour les ateliers qui traitent plusieurs m‚tiers, une liste permet de choisir les m‚tiers accept‚s : l'atelier ne prend alors que les ordres g‚n‚raux correspondants (la liste d‚pend de l'atelier).

Par exemple, toutes les forges re‡oivent par d‚faut les ordres d'armes, d'armures et de ferronnerie. Avec ces restrictions, une forge peut se consacrer aux armes, une autre aux armures ou … la ferronnerie, chacune avec son maŒtre l‚gendaire.

De mˆme, les ateliers d'artisan peuvent se sp‚cialiser dans la pierre, le bois ou l'os.

Une tƒche attribu‚e … la main … l'atelier est toujours faite : ces restrictions ne valent que pour les ordres g‚n‚raux de l'‚cran des ordres de travail.

Ces r‚glages existaient avant la version 50 et existent toujours dans le jeu : DFHack leur donne simplement une interface.


orders.*rightclick
~~~~~~~~~~~~~~~~~~

Am‚liorations invisibles : chap ou clic droit annule une saisie sans quitter l'‚cran.


La bibliothŠque d'ordres
------------------------

DFHack fournit des ordres prˆts … importer :


library/basic
~~~~~~~~~~~~~

Les besoins de base de la forteresse :

* repas et produits alimentaires (et sous-produits comme l'huile)
* alcool, hydromel
* fil, tissu, teinture
* pots, bacs, cruches, seaux, chopes
* sacs en cuir, tissu, soie et laine
* objets d'artisanat, totems et shleggings … partir des restes inutilisables
* m‚canismes, cages
* attelles, b‚quilles
* lessive, savon
* cendre, potasse
* lits, brouettes, wagonnets
* papier, rouleaux

Importez-la dŠs que vous avez assez de nains, juste aprŠs la premiŠre vague de migrants par exemple.

Ces ordres ne comprennent ni traite, ni tonte, ni fromage, faute de conditions adapt‚es dans le jeu. Activez "automilk", "autoshear" et autocheese dans gui/control-panel pour ces tƒches.

Les cruches sont en bois : tant que vous ne faites pas d'autres ® outils ¯ en bois, un stock de produits finis limit‚ aux outils en bois servira de stock … cruches.

Note d'Armok : ® Des shleggings ? Oui, des shleggings. ¯


library/furnace
~~~~~~~~~~~~~~~

Objets qui demandent de la chaleur, s‚par‚s de "library/basic" pour vous laisser installer d'abord des fourneaux … magma si vous voulez ‚conomiser. Comprend :

* charbon de bois (et fonte de houille et de lignite)
* perlasse
* sable
* verre vert, incolore et cristal
* traitement de l'adamantine
* fonte d'objets

Il manque les ordres de plƒtre tant que le bug DF 11803 n'est pas corrig‚.


library/military
~~~~~~~~~~~~~~~~

Fonte en grande quantit‚ des minerais militaires, armes et armures :

* sacs … dos, outres, carquois et armures en cuir
* capes en soie
* carreaux en os et en bois
* fonte du platine, de l'argent, de l'acier, du bronze, du bronze au bismuth et du cuivre (et de ce qu'il faut pour eux)
* carreaux en bronze, bronze au bismuth et cuivre
* armes et armures en acier, argent, fer, bronze au bismuth, bronze et cuivre, en utilisant les meilleurs mat‚riaux disponibles
* boucliers en bois (sans m‚tal disponible)

Avec un stock qui accepte les armes et armures de moins que chef-d'oeuvre et automelt activ‚ (comme l'‚tage industriel de Dreamfort), ces ordres am‚liorent peu … peu l'‚quipement jusqu'au chef-d'oeuvre. Pr‚voyez beaucoup de combustible (ou des forges … magma) avant d'activer "automelt" !

· n'importer que si vous devez ‚quiper une arm‚e.


library/smelting
~~~~~~~~~~~~~~~~

Fonte de tous les minerais, y compris ceux de "library/military" mais avec des limites plus basses. Tous les minerais sont couverts mˆme sans "library/military" ; si les deux sont import‚es, "library/military" passe en priorit‚.


library/rockstock
~~~~~~~~~~~~~~~~~

Garde un petit stock de tous les meubles en pierre, pour meubler … la demande guildes, bibliothŠques, temples et autres piŠces avec buildingplan : vos ma‡ons assurent le stock.


library/glassstock
~~~~~~~~~~~~~~~~~~

Comme "library/rockstock", mais en verre. Avec une verrerie en marche, c'est plus durable car le sable ne s'‚puise jamais. Importez les deux pour un m‚lange de meubles en pierre et en verre.

Quelques objets impossibles en pierre ne sont produits que par "library/glassstock" :

* tubes et vis pour des pompes … vis r‚sistantes au magma
* fenˆtres
* terrariums (au lieu des cages en bois)
@@ overlay
court: GŠre les widgets affich‚s … l'‚cran.
@@ pet-uncapper
court: Modifie la limite d'animaux de compagnie.
@@ plant
court: Fait pousser ou retire arbustes et arbres.
@@ plug
court: Liste les modules et indique s'ils sont actifs.
@@ points
court: RŠgle les points disponibles … l'installation.
@@ pop-control
court: Limite la taille des vagues de migrants.
@@ position
court: Indique la position du curseur et de la souris.
@@ pref-adjust
court: Voir ou r‚gler les pr‚f‚rences d'un nain.
@@ preserve-rooms
court: Garde les chambres des absents et des nobles.
@@ preserve-tombs
court: Garde les tombes attribu‚es aprŠs la mort.
@@ prioritize
court: Augmente la priorit‚ des tƒches importantes.
@@ probe
court: Affiche les propri‚t‚s internes de la case choisie.
@@ prospector
court: Analyse les ressources naturelles.
@@ putontable
court: Pose un objet sur une table.
@@ questport
court: T‚l‚porte au curseur du journal de quˆtes.
@@ quickfort
court: Applique des plans … la forteresse.
@@ quicksave
court: Sauvegarde automatique imm‚diate.
@@ quickstart-guide
court: Guide de d‚marrage rapide de DFHack.
@@ region-pops
court: Modifie les populations animales r‚gionales.
@@ regrass
court: Fait repousser l'herbe et la mousse des cavernes.
@@ rejuvenate
court: Remet … z‚ro l'ƒge d'une cr‚ature.
@@ reload
court: Recharge un module.
@@ remove-stress
court: R‚duit le stress des nains.
@@ remove-wear
court: Retire l'usure des objets de la forteresse.
@@ repeat
court: Relance une commande DFHack … intervalles r‚guliers.
@@ resize-armor
court: Ajuste la taille des armures et vˆtements.
@@ resurrect-adv
court: RamŠne … la vie un aventurier mort.
@@ reveal
court: R‚vŠle la carte.
@@ reveal-adv-map
court: R‚vŠle ou cache la carte du monde.
@@ reveal-hidden-sites
court: R‚vŠle tous les sites du monde.
@@ reveal-hidden-units
court: R‚vŠle les cr‚atures cach‚es.
@@ sc-script
court: Lance des commandes quand l'‚tat du jeu change.
@@ script
court: Ex‚cute un fichier de commandes DFHack.
@@ seedwatch
court: GŠre graines et cuisine selon le stock de graines.
@@ set-orientation
court: Modifie les penchants amoureux d'une cr‚ature.
@@ set-timeskip-duration
court: RŠgle la dur‚e de mise … jour du monde avant partie.
@@ setfps
court: RŠgle la limite de FPS de l'affichage.
@@ show
court: Affiche la fenˆtre du terminal DFHack.
@@ showmood
court: Montre les objets voulus par une humeur ‚trange.
@@ smooth-movement
court: Anime les d‚placements en douceur.
@@ sort
court: Recherche et tri dans les listes du jeu.
@@ source
court: Cr‚e une source infinie de magma ou d'eau.
@@ spectate
court: Mode spectateur automatique.
@@ startdwarf
court: Change le nombre de nains au d‚part.
@@ starvingdead
court: vite l'accumulation infinie de morts-vivants.
@@ stockflow
court: Lance des ordres selon la place libre des stocks.
@@ stockpiles
court: Importe, exporte ou modifie les r‚glages de stocks.
@@ stonesense
court: Visualiseur 3D isom‚trique.
@@ store-owned
court: Fait ranger leurs objets aux nains.
@@ strangemood
court: D‚clenche une humeur ‚trange.
@@ stripcaged
court: Retire les objets des prisonniers en cage.
stripcaged
==========

tiquettes : fort | productivity | items

Commande : "stripcaged"

  Retire les objets des prisonniers en cage.

vite de passer en revue chaque cage pour marquer les objets … jeter. Pratique pour r‚cup‚rer les graines rest‚es dans les cages aprŠs le dressage. Surtout, il sert … retirer armes et armures des prisonniers : aprŠs "stripcaged", vos nains portent les objets au d‚potoir, les cages sont propres et les prisonniers d‚pouill‚s.

Pour ne pas attendre vos nains, utilisez autodump.


Utilisation
-----------

   stripcaged list
   stripcaged items|weapons|armor|all [here|<id de cage> ...] [<options>]


Exemples
--------

"stripcaged list"
   Liste toutes les cages et leur contenu.

"stripcaged all"
   Jette tous les objets de toutes les cages, port‚s ou non.

"stripcaged items"
   Jette les objets pos‚s dans les cages, comme les graines du dressage.

"stripcaged weapons"
   Jette les armes port‚es par les cr‚atures en cage.

"stripcaged armor here --skip-forbidden"
   Jette les armures non interdites port‚es par la cr‚ature de la cage choisie.

"stripcaged all 25321 34228"
   Vide les cages indiqu‚es.

"stripcaged items here --include-pets --include-vermin"
   Jette les objets de la cage choisie, vermine apprivois‚e ou non comprise.


Options
-------

"--include-pets", "--include-vermin"
   Pour le jeu, la vermine vivante (apprivois‚e ou non) est un objet. Elle n'est pas jet‚e par d‚faut, car elle risque de s'enfuir ou d'ˆtre mang‚e par vos chats. Ces options la jettent quand mˆme.

"-f", "--skip-forbidden"
   Par d‚faut, les objets … jeter sont autoris‚s. Avec cette option, seuls les objets d‚j… autoris‚s sont trait‚s : vous pouvez par exemple autoriser … la main les objets pr‚cieux (comme l'acier) depuis le menu des stocks, puis lancer "stripcaged".
@@ superdwarf
court: Rend un nain surnaturellement rapide.
@@ suspend
court: Suspend les constructions.
@@ suspendmanager
court: Suspend et reprend les tƒches intelligemment.
@@ sync-windmills
court: Synchronise ou varie les moulins … vent.
@@ tags
court: Liste les cat‚gories d'outils ou leurs outils.
@@ tailor
court: Garde des vˆtements neufs pour vos nains.
tailor
======

tiquettes : fort | auto | workorders

Commande : "tailor"

  Garde des vˆtements neufs pour vos nains.

Une fois par jour, examine les vˆtements de la forteresse. S'il y a des vˆtements neufs, les nains en guenilles se les voient confisquer (comme avec cleanowned) et s'habillent de neuf.

S'il n'y a pas assez de vˆtements, des ordres de travail sont cr‚‚s avec les matiŠres disponibles : beaucoup de soie mais pas de tissu ? "tailor" ne commande que des vˆtements en soie.

Pour choisir entre tailor et autoclothing, voir la comparaison dans l'aide d'autoclothing.


Utilisation
-----------

   enable tailor
   tailor [status]
   tailor now
   tailor materials <matiŠre> [<matiŠre> ...]
   tailor confiscate [true|false]
   tailor dye [true|false]

Par d‚faut, l'ordre de pr‚f‚rence des matiŠres est :

   silk cloth yarn leather

(soie, tissu, laine, cuir). "tailor materials" limite les matiŠres et leur ordre. Par d‚faut, "tailor" confisque (retire la propri‚t‚ et marque … jeter) les vˆtements en lambeaux dŠs qu'il y a de quoi les remplacer ; "tailor confiscate" change ce comportement. Les nains portent ainsi moins longtemps des guenilles et en sont moins contrari‚s, mais les guenilles finissent au d‚potoir, interdites, ce qui peut gˆner.

"tailor" sait utiliser le tissu d'adamantine (mot-cl‚ "adamantine"), mais pas par d‚faut, car il est en g‚n‚ral trop pr‚cieux. Il ne gŠre pas les tissus des mods qui ont leurs propres r‚actions de fabrication.

Avec la gestion des teintures, "tailor" commande aussi la teinture des tissus n‚cessaires et la fabrication des teintures. Elle est d‚sactiv‚e par d‚faut.


Exemples
--------

"enable tailor"
   Remplace les vˆtements en lambeaux avec les r‚glages par d‚faut.

"tailor now"
   Lance tout de suite un examen et les commandes, activ‚ ou non.

"tailor materials silk cloth yarn"
   N'utilise que la soie, le tissu et la laine, dans cet ordre, et garde le cuir pour les armures.


Limites
-------

Les matiŠres de type tissu ajout‚es par des mods ne sont pas g‚r‚es : leurs r‚actions ne savent pas ajuster la taille pour les autres races. Le jeu ne le fait que pour ses r‚actions de base.

Les teintures faites au moulin ou … la meule ne sont pas command‚es : le jeu ne permet pas de commander ® moudre une plante ¯ d'une matiŠre pr‚cise.

Pour l'instant, n'importe quelle teinture disponible est utilis‚e, quelle que soit sa couleur. Le choix des couleurs viendra peut-ˆtre plus tard.
@@ tame
court: Apprivoise et dresse des animaux.
@@ teleport
court: T‚l‚porte une cr‚ature n'importe o—.
@@ tiletypes
court: Peint des types de cases sur la carte.
@@ timestream
court: Corrige la chute de FPS des vieilles forteresses.
@@ toggle-kbd-cursor
court: Active ou cache le curseur clavier.
@@ trackstop
court: Modifie butoirs et rouleaux aprŠs construction.
@@ traduction-switch
court: Passe la traduction du fran‡ais … l'anglais et inversement.
@@ troubleshoot-item
court: Examine les propri‚t‚s de l'objet choisi.
@@ tubefill
court: Remplit … nouveau l'adamantine extraite.
@@ twaterlvl
court: Affiche ou cache la profondeur des liquides.
@@ tweak
court: Ensemble de r‚glages et de correctifs.
@@ type
court: Indique comment une commande est faite.
@@ undump-buildings
court: Annule le jet des mat‚riaux de bƒtiments.
@@ unforbid
court: Autorise tous les objets.
unforbid
========

tiquettes : fort | productivity | items

Commande : "unforbid"

  Autorise tous les objets.

Autorise vite et simplement tous les objets. TrŠs utile aprŠs un siŠge pour nettoyer (ou pour jeter l'‚quipement des prisonniers en cage avec stripcaged).


Utilisation
-----------

   unforbid all [<options>]


Options
-------

"-u", "--include-unreachable"
   Autorise aussi les objets inaccessibles.

"-q", "--quiet"
   N'affiche que les erreurs.

"-X", "--include-worn"
   Inclut les objets us‚s (X) et en lambeaux (XX).
@@ ungeld
court: Annule la castration d'un animal.
@@ uniform-unstick
court: Fait revoir leur uniforme aux militaires.
@@ unload
court: D‚charge un module de la m‚moire.
@@ unretire-anyone
court: Jouer l'aventure avec n'importe quel personnage.
@@ warn-stranded
court: Signale les citoyens isol‚s des autres.
@@ weather
court: Change la m‚t‚o.
@@ work-now
court: R‚duit le temps d'attente des nains entre deux tƒches.
@@ workorder
court: Cr‚e des ordres de travail.
]==]
local function aide_charger()
    if AIDE_FR then return AIDE_FR end
    AIDE_FR={}
    local src=rawget(_G,'__PGM_AIDE_DONNEES') or AIDE_DONNEES
    if type(src)~='string' then return AIDE_FR end
    local nom,court,lignes=nil,nil,nil
    local function fin()
        if nom then AIDE_FR[nom]={court=court,long=table.concat(lignes,'\n'):gsub('%s+$','')} end
    end
    for l in (src..'\n'):gmatch('([^\n]*)\n') do
        l=l:gsub('\r$','')
        local n=l:match('^@@ (%S+)%s*$')
        if n then fin();nom,court,lignes=n,nil,{}
        elseif nom and not court and l:match('^court: ') then court=l:sub(8)
        elseif nom then lignes[#lignes+1]=l end
    end
    fin()
    return AIDE_FR
end
local function aide_couper(texte,largeur)
    largeur=largeur or 80
    local out={}
    for ligne in (texte..'\n'):gmatch('([^\n]*)\n') do
        if #ligne<=largeur then out[#out+1]=ligne
        else
            local indent=ligne:match('^(%s*)')
            local cur=''
            for mot in ligne:gmatch('%S+') do
                if cur=='' then cur=indent..mot
                elseif #cur+1+#mot>largeur then out[#out+1]=cur;cur=indent..mot
                else cur=cur..' '..mot end
            end
            if cur~='' then out[#out+1]=cur end
        end
    end
    return table.concat(out,'\n')
end
local ok_helpdb,helpdb=pcall(require,'helpdb')
if ok_helpdb and helpdb then
    if not helpdb.__pgm_aide_court then
        helpdb.__pgm_aide_court=helpdb.get_entry_short_help
        helpdb.__pgm_aide_long=helpdb.get_entry_long_help
    end
    local court0,long0=helpdb.__pgm_aide_court,helpdb.__pgm_aide_long
    helpdb.get_entry_short_help=function(entry)
        local a=actif() and aide_charger()[entry]
        if a and a.court then return a.court end
        return court0(entry)
    end
    helpdb.get_entry_long_help=function(entry,width)
        local a=actif() and aide_charger()[entry]
        if a and a.long and a.long~='' then return aide_couper(a.long,width) end
        return long0(entry,width)
    end
end

-- PGM v30 : drapeau FR/EN sur l'ecran titre, a cote du bouton DFHack. Clic = changer de langue.
local ok_ov,overlay=pcall(require,'plugins.overlay')
if ok_ov and overlay then
    local B,W,R=COLOR_BLUE,COLOR_WHITE,COLOR_RED
    local DRAPEAUX={
        fr={{B,B,W,W,R,R},{B,B,W,W,R,R},{B,B,W,W,R,R}},
        en={{B,B,R,R,B,B},{R,R,R,R,R,R},{B,B,R,R,B,B}},
    }
    DrapeauLangue=defclass(DrapeauLangue,overlay.OverlayWidget)
    DrapeauLangue.ATTRS{
        desc='Drapeau FR/EN : cliquer pour changer la langue de la traduction PGM.',
        default_pos={x=4,y=5},
        default_enabled=true,
        viewscreens={'title/Default'},
        frame={w=6,h=4},
    }
    function DrapeauLangue:onRenderBody(dc)
        local fr=actif()
        for y,ligne in ipairs(DRAPEAUX[fr and 'fr' or 'en']) do
            for x,c in ipairs(ligne) do dc:seek(x-1,y-1):pen({ch=' ',bg=c,fg=c}):char(' ') end
        end
        dc:seek(0,3):pen({fg=COLOR_WHITE,bg=COLOR_BLACK}):string(fr and '  FR  ' or '  EN  ')
    end
    function DrapeauLangue:onInput(keys)
        if keys._MOUSE_L and self:getMousePos() then
            local f=io.open(dfhack.getDFPath()..'/traducfr/langue_demande','wb')
            if f then f:write('bascule');f:close() end
            return true
        end
    end
    OVERLAY_WIDGETS={drapeau=DrapeauLangue}
end
