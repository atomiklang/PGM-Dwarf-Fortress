-- Toggle the native FPS indicator for the current session.
local gps = df.global.gps
gps.display_frames = gps.display_frames == 0 and 1 or 0
