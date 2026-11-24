-- PGM independent experimental controls. Mouse only; native pause stays native.
--@ module = true
local gui=require('gui')
local overlay=require('plugins.overlay')
local model=require('pgm-fluidity.controller')
local rates={.5,1,1.5,2}
local labels={'x0.5','x1','x1.5','x2'}
local function cap(v)
    df.global.enabler.fps=v
    df.global.enabler.fps_per_gfps=v/math.max(1,df.global.enabler.gfps)
end
local function start()
    if controller and controller.active then return end
    assert(dfhack.isMapLoaded() and dfhack.world.isFortressMode(),'Open a fortress first')
    controller=model.new{get_cap=function()return df.global.enabler.fps end,set_cap=cap}
    native_fps_prior=df.global.gps.display_frames
    df.global.gps.display_frames=0
end
local function stop()
    if popup then popup:dismiss();popup=nil end
    if native_fps_prior~=nil then
        if df.global.gps.display_frames==0 then df.global.gps.display_frames=native_fps_prior end
        native_fps_prior=nil
    end
    if controller then
        local ok,msg=controller:stop()
        if not ok then dfhack.printerr(msg) end
        controller=nil
    end
end
Popup=defclass(Popup,gui.ZScreen)
Popup.ATTRS{focus_path='pgm-fluidity',force_pause=false,pass_pause=true,
 pass_mouse_clicks=true,pass_movement_keys=true,initial_pause=false,anchor_x=0}
function Popup:init() self.last_hover=dfhack.getTickCount();self.prior_top=df.global.gps.top_in_use end
function Popup:onRenderBody(dc)
    if not controller then return end
    local w=dfhack.screen.getWindowSize()
    self.width=30
    self.left=math.max(0,math.min(w-self.width,self.anchor_x-math.floor(self.width/2)))
    -- Native top layer is composited after the graphical minimap. The parent
    -- redraw resets its lifetime on the next frame; no persistent UI buffer patch.
    df.global.gps.top_in_use=true
    dc:seek(self.left,2):pen{fg=COLOR_BROWN,bg=COLOR_BLACK}:string('+'..string.rep('-',self.width-2)..'+')
    dc:seek(self.left,3):string('|'..string.rep(' ',self.width-2)..'|')
    dc:seek(self.left,4):string('+'..string.rep('-',self.width-2)..'+')
    for i,v in ipairs(rates) do
        dc:seek(self.left+2+(i-1)*7,3):pen{fg=v==controller.multiplier and COLOR_YELLOW or COLOR_WHITE,bg=v==controller.multiplier and COLOR_BROWN or COLOR_BLACK}:string(('%-5s'):format(labels[i]))
    end
end
function Popup:onIdle()
    Popup.super.onIdle(self)
    local x,y=self:getMousePos()
    if x and self.left and x>=self.left and x<self.left+(self.width or 30) and y>=0 and y<=4 then
        self.last_hover=dfhack.getTickCount()
    elseif dfhack.getTickCount()-self.last_hover>300 then self:dismiss() end
end
function Popup:isMouseOver()
    local x,y=self:getMousePos()
    return x and self.left and x>=self.left and x<self.left+(self.width or 30) and y>=2 and y<=4 or false
end
function Popup:onInput(keys)
    local x,y=self:getMousePos()
    if keys._MOUSE_L and self.left and x and y==3 and x>=self.left+2 and x<self.left+28 then
        local offset=x-self.left-2
        if offset%7>=5 then return true end
        local ok,msg=controller:select(rates[math.floor(offset/7)+1])
        if not ok then dfhack.printerr(msg) end
        self:dismiss();return true
    end
    -- No new bindings: native pause and all other game controls pass through.
    return Popup.super.onInput(self,keys)
end
function Popup:onDismiss()
    popup=nil
    if self.prior_top~=nil then df.global.gps.top_in_use=self.prior_top end
    dfhack.screen.invalidate()
end
Speed=defclass(Speed,overlay.OverlayWidget)
Speed.ATTRS{
 desc='PGM mouse-only speeds: hover native play. No speed label drawn on play.',
 default_pos={x=-30,y=1},default_enabled=false,viewscreens='dwarfmode/Default',
 frame={w=2,h=2},overlay_onupdate_max_freq_seconds=0,
}
function Speed:init() self.pending=false end
function Speed:overlay_onupdate()
    if not controller or popup or self.pending then return end
    local x,y=self:getMousePos()
    if x and x>=0 and x<2 and y>=0 and y<2 then
        self.pending=true
        local anchor=self.frame_body.x1+1
        dfhack.timeout(1,'frames',function()
            self.pending=false
            if not controller or popup or not dfhack.gui.matchFocusString('dwarfmode/Default') then return end
            popup=Popup{anchor_x=anchor};popup:show()
        end)
    end
end
function Speed:onRenderBody() self.render_count=(self.render_count or 0)+1 end
-- No drawing and no click capture on native play: its icon/action stay native.
Fps=defclass(Fps,overlay.OverlayWidget)
Fps.ATTRS{
 desc='PGM FPS at the lower right of the minimap, below altitude.',
 default_pos={x=-2,y=19},default_enabled=false,viewscreens='dwarfmode/Default',
 frame={w=16,h=1},overlay_onupdate_max_freq_seconds=1,
}
function Fps:init() self.has_anchor=false end
function Fps:overlay_onupdate()
    local w,h=dfhack.screen.getWindowSize()
    self.has_anchor=false
    -- Locate the rendered altitude label instead of hardcoding minimap height.
    for y=3,math.min(34,h-2) do
        local row=''
        for x=math.max(0,w-35),w-1 do
            local pen=dfhack.screen.readTile(x,y)
            local ch=pen and pen.ch or 32
            row=row..string.char(ch>=32 and ch<127 and ch or 32)
        end
        if row:find('Altitude',1,true) or row:find('Elevation',1,true) then
            self.frame.t=math.min(h-2,y+2);self.has_anchor=true;break
        end
    end
end
function Fps:onRenderBody(dc)
    if not controller or not self.has_anchor then return end
    local e=df.global.enabler
    local text=('FPS: %d (%d)'):format(e.calculated_fps,e.calculated_gfps)
    dc:seek(math.max(0,16-#text),0):pen{fg=COLOR_GREY,bg=COLOR_BLACK}:string(text)
end
OVERLAY_WIDGETS={speed=Speed,fps=Fps}
dfhack.onStateChange.pgm_fluidity=function(code)
    if code==SC_MAP_UNLOADED then stop() end
end
if dfhack_flags.module then return end
local action=(...) or 'status'
if action=='on' then
    start();dfhack.run_command('overlay','enable','pgm-fluidity.speed','pgm-fluidity.fps')
elseif action=='off' then
    stop();dfhack.run_command('overlay','disable','pgm-fluidity.speed','pgm-fluidity.fps')
elseif action=='status' then
    print(controller and ('PGM speed: x%g, base cap %d'):format(controller.multiplier,controller.base) or 'PGM speed: off')
else qerror('Usage: pgm-fluidity on|off|status') end
