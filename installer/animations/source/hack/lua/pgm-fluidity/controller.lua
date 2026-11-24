-- PGM original prototype. No DFHack globals: a small injectable simulation-cap service.
local M = {}
local allowed = {[0.5]=true,[1]=true,[1.5]=true,[2]=true}
function M.new(api)
    local base = api.get_cap()
    assert(type(base)=='number' and base>=1 and base<100000, 'Invalid simulation FPS cap')
    local self = {base=base, multiplier=1, last=base, active=true}
    function self:select(value)
        assert(self.active, 'Controller stopped')
        assert(allowed[value], 'Unsupported speed')
        if api.get_cap()~=self.last then
            return false, 'Simulation cap changed elsewhere; stop and restart the prototype.'
        end
        local cap=math.max(1,math.floor(self.base*value+0.5))
        api.set_cap(cap)
        self.last=cap; self.multiplier=value
        -- Pause belongs to the native game. Selecting a speed never unpauses it.
        return true
    end
    function self:stop()
        if not self.active then return true end
        self.active=false
        if api.get_cap()~=self.last then return false, 'External cap preserved.' end
        api.set_cap(self.base)
        return true
    end
    return self
end
return M
