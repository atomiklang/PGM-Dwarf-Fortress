-- PGM: open world map zoom automatically on the embark map and the fortress world map.
-- Usage: pgm-worldmap-auto [on|off|status]
-- Esc / right-click close the world map like the native game; the zoom comes back with the map.
--@ module = true
local context = require('worldmap-zoom.context')

enabled = enabled ~= false and enabled or false
generation = generation or 0

local function zoom_open()
    local ok, m = pcall(reqscript, 'gui/worldmap-zoom')
    return ok and m.view ~= nil
end

local stable=0
-- v25 : inscrit dans la boucle PGM unique (pgm.boucle) au lieu d'un minuteur propre.
local function verifier()
    if not enabled then return end
    -- Zoom toujours disponible sur la carte du monde : on le rouvre dès que la carte normale revient
    -- (après l'annulation d'un panneau de site, après Échap sur le zoom, etc.).
    local ok, c = pcall(context.get)
    if ok and c and not zoom_open() then
        stable = stable + 1
        if stable >= 3 then
            stable = 0
            local good, err = pcall(dfhack.run_script, 'gui/worldmap-zoom')
            if not good then dfhack.printerr('pgm-worldmap-auto: ' .. tostring(err)) end
        end
    else
        stable = 0
    end
end

if dfhack_flags.module then return end

local cmd = ({...})[1] or 'on'
if cmd == 'on' then
    enabled = true
    require('pgm.boucle').inscrire('carte-du-monde', 5, verifier)
    print('pgm-worldmap-auto: on')
elseif cmd == 'off' then
    enabled = false
    require('pgm.boucle').retirer('carte-du-monde')
    print('pgm-worldmap-auto: off')
else
    print('pgm-worldmap-auto: ' .. (enabled and 'on' or 'off'))
end
