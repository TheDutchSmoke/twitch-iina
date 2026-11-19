-- live.lua (twitch-iina): automatisch terug naar live voor Twitch via Streamlink in IINA of mpv.
-- iina-twitch laadt dit via mpv's IPC-socket; in mpv kan het ook met --script=<dit bestand>.
-- Alleen actief bij de stream van Streamlink (stdin). Werkt alleen met de cache aan: dan staat de
-- achterstand in mpv's eigen buffer en springt mpv daarbinnen vooruit. Zonder force-seekable doet mpv
-- bij stdin alleen sprongen binnen die buffer (bij fMP4 stopt de stream als ffmpeg in de pipe terugzoekt).
-- https://github.com/TheDutchSmoke/twitch-iina

local mp = require "mp"

local MAX_BEHIND = 6 -- meer dan zoveel seconden achter live: terugspringen
local LAND = 3       -- zoveel seconden vóór het nieuwste stuk landen; Twitch levert blokken van 2 s,
                     -- met 1,5 s liep de buffer leeg en sprong hij steeds opnieuw
local GRACE = 5      -- de eerste seconden na het openen niets doen

local started_at = mp.get_time()
local jumps = 0

-- Einde van het doorzoekbare deel van de buffer (bij fMP4 ligt dat iets vóór demuxer-cache-time).
local function seekable_end()
  local state = mp.get_property_native("demuxer-cache-state")
  local ranges = type(state) == "table" and state["seekable-ranges"]
  if type(ranges) ~= "table" or #ranges == 0 then return nil end
  return ranges[#ranges]["end"]
end

local function check()
  if mp.get_time() - started_at < GRACE then return end
  if mp.get_property("path") ~= "-" then return end -- alleen de stream van Streamlink (stdin)
  if mp.get_property_native("pause") or mp.get_property_native("seeking") then return end

  local pos = mp.get_property_native("time-pos")
  local edge = mp.get_property_native("demuxer-cache-time")
  local last = seekable_end()
  if type(pos) ~= "number" or type(edge) ~= "number" or type(last) ~= "number" then return end

  if edge - pos > MAX_BEHIND then
    local target = math.min(edge - LAND, last - 0.1)
    if target <= pos + 1 then return end
    jumps = jumps + 1
    mp.set_property_native("user-data/twitch-live/jumps", jumps)
    mp.commandv("seek", tostring(target), "absolute")
    mp.osd_message("Terug naar live", 1.5)
  end
end

mp.register_event("file-loaded", function()
  started_at = mp.get_time()
end)

mp.set_property_native("user-data/twitch-live/jumps", 0)
mp.add_periodic_timer(1, check)
