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
    return os.getenv('TRADUCFR_EN') ~= '1'
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
