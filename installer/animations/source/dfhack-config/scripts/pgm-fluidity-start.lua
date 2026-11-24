-- Local opt-in test installation only. No Workshop/public package integration.
--@ module = true
local json=require('json')
local settings_path=dfhack.getConfigPath()..'/pgm-fluidity-test.json'
local function settings()
 local ok,data=pcall(json.decode_file,settings_path)
 return ok and type(data)=='table' and data or {enabled=false}
end
local function remember(enabled)
 json.encode_file({enabled=enabled,experimental=true},settings_path)
end
local function restore_smooth()
 if not prior_smooth then return end
 if prior_smooth.enabled then
  dfhack.run_command('enable','smooth-movement')
  dfhack.run_command('smooth-movement','flip',prior_smooth.flip and 'on' or 'off')
  dfhack.run_command('smooth-movement','zlevel',prior_smooth.zlevel and 'on' or 'off')
 end
 prior_smooth=nil
end
function stop_test()
 dfhack.run_script('pgm-fluidity','off')
 if motion_started then dfhack.run_command('disable','pgm-motion');motion_started=false end
 restore_smooth();running=false
end
function start_test()
 if running or not dfhack.isMapLoaded() or not dfhack.world.isFortressMode() then return end
 local text,status=dfhack.run_command_silent('smooth-movement')
 if status~=0 then qerror('Cannot read smooth-movement settings; test not started.') end
 prior_smooth={enabled=text:find('smooth-movement: enabled',1,true)~=nil,
  flip=text:find('sprite flipping: on',1,true)~=nil,
  zlevel=text:find('lower z-level animation: on',1,true)~=nil}
 if dfhack.run_command('load','pgm-motion')~=0 then prior_smooth=nil;qerror('Cannot load experimental movement.') end
 if prior_smooth.enabled then dfhack.run_command('disable','smooth-movement') end
 if dfhack.run_command('enable','pgm-motion')~=0 then restore_smooth();qerror('Cannot enable experimental movement.') end
 motion_started=true
 local ok,err=pcall(dfhack.run_script,'pgm-fluidity','on')
 if not ok then stop_test();qerror(tostring(err)) end
 running=true
end
dfhack.onStateChange.pgm_fluidity_test=function(code)
 if code==SC_MAP_UNLOADED and running then stop_test() end
end
if dfhack_flags.module then return end
local action=(...) or 'auto'
if action=='off' then remember(false);stop_test();print('PGM movement test disabled; previous settings restored.')
elseif action=='on' then remember(true);start_test()
elseif action=='auto' then
 if settings().enabled then
  dfhack.timeout(60,'frames',function()
   if settings().enabled and dfhack.isMapLoaded() and dfhack.world.isFortressMode() then
    local ok,err=pcall(start_test);if not ok then dfhack.printerr(err) end
   end
  end)
 end
else qerror('Usage: pgm-fluidity-start on|off|auto') end
