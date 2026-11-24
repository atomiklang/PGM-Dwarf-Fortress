-- PGM Windows: typed DFHack access; no hard-coded C++ vector offsets.
--@ module = true
local translator=reqscript('traducfr-dfhack')
snapshots=snapshots or {}
current=current
started=started or false
local function wrap(text,width)
 local out,line={},''
 for word in text:gmatch('%S+') do
  if #line>0 and #line+1+#word>width then table.insert(out,line);line='' end
  line=line=='' and word or line..' '..word
 end
 if line~='' then table.insert(out,line)end
 return out
end
local function collect()
 if next(snapshots) then return end
 for index,box in ipairs(df.global.game.main_interface.hover_instruction)do
  local attr=df.main_hover_instruction.attrs[index]
  local caption=attr and attr.caption
  local english,source,width={},{},24
  for _,ptr in ipairs(box.text)do table.insert(english,ptr);table.insert(source,(ptr.value:gsub('%s+$','')));width=math.max(width,#ptr.value)end
  local joined=table.concat(source,' '):gsub('%s+',' ')
  local french=(caption and translator.dico[caption]) or translator.dico[joined]
  if french and french~=caption and french~=joined then
   if #english>0 then
    local translated={}
    for _,line in ipairs(wrap(french,math.min(width,80)))do local ptr=df.new('string');ptr.value=line;table.insert(translated,ptr)end
    snapshots[index]={vector=box.text,english=english,french=translated}
   end
  end
 end
end
function appliquer(fr)
 collect()
 if current==fr then return end
 for _,entry in pairs(snapshots)do
  local rows=fr and entry.french or entry.english
  entry.vector:resize(0)
  for _,ptr in ipairs(rows)do entry.vector:insert('#',ptr)end
 end
 current=fr
 _G.PGM_WINDOWS_FR=fr
end
function nombre()local n=0;for _ in pairs(snapshots)do n=n+1 end;return n end
local function follow()
 local file=io.open(dfhack.getDFPath()..'/pgm-hook/language.txt','rb')
 local mode=file and file:read(3) or 'off';if file then file:close()end
 appliquer(mode=='fr\n')
 dfhack.timeout(10,'frames',follow)
end
if not dfhack_flags.module and not started then
 started=true
 dfhack.timeout(1,'frames',follow)
end
