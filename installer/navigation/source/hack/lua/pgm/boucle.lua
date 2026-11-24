-- PGM : une seule boucle de mise à jour pour les petites tâches périodiques du mod.
-- Au lieu que chaque script garde son propre minuteur, il s'inscrit ici avec sa période.
-- Usage : local boucle = require('pgm.boucle'); boucle.inscrire('nom', 15, function() ... end)
local M = {}
M.taches = M.taches or {}
local PAS = 5                      -- la boucle tourne toutes les 5 images
local generation = (M.generation or 0)

local function tourner(gen)
    if gen ~= M.generation then return end
    M.image = (M.image or 0) + PAS
    for nom, t in pairs(M.taches) do
        if M.image - t.dernier >= t.periode then
            t.dernier = M.image
            local ok, err = pcall(t.fn)
            if not ok then
                t.erreurs = (t.erreurs or 0) + 1
                if t.erreurs <= 3 then dfhack.printerr('pgm.boucle [' .. nom .. '] : ' .. tostring(err)) end
                if t.erreurs >= 20 then M.taches[nom] = nil end      -- une tâche cassée ne coûte plus rien
            end
        end
    end
    if next(M.taches) then dfhack.timeout(PAS, 'frames', function() tourner(gen) end)
    else M.actif = false end
end

function M.inscrire(nom, periode, fn)
    M.taches[nom] = { periode = math.max(PAS, periode), fn = fn, dernier = M.image or 0 }
    if not M.actif then
        M.actif = true
        M.generation = (M.generation or 0) + 1
        tourner(M.generation)
    end
end
function M.retirer(nom) M.taches[nom] = nil end
function M.etat()
    local t = {}
    for nom, x in pairs(M.taches) do t[#t + 1] = ('%s (toutes les %d images)'):format(nom, x.periode) end
    table.sort(t); return t
end
return M
