-- /f <query>: fuzzy-search the cached file lists, open the pick with xdg-open.

local HOME = noctalia.getenv("HOME")
local DIR = HOME .. "/.cache/noctalia-file-search"
local REFRESH = noctalia.pluginDir() .. "/refresh.sh"
local REFRESH_EVERY = 10 * 60  -- seconds
local LIMIT = 50

local lastRefresh = 0

local function refreshIfStale()
  local now = os.time()
  if now - lastRefresh >= REFRESH_EVERY then
    lastRefresh = now
    noctalia.runAsync({ REFRESH })
  end
end

refreshIfStale()

-- Query is passed as $1, never spliced into the shell string.
local SEARCH = 'cat "$0"/*.list 2>/dev/null | fzf --filter "$1" | head -n ' .. LIMIT

local function shortPath(path)
  if path:sub(1, #HOME + 1) == HOME .. "/" then
    return "~" .. path:sub(#HOME + 1)
  end
  return path
end

function onQuery(text)
  refreshIfStale()
  if text == "" then
    launcher.setResults(text, { { id = "hint", title = "Type to search files", glyph = "file-search" } })
    return
  end
  noctalia.runAsync({ "sh", "-c", SEARCH, DIR, text }, function(res)
    local results = {}
    local n = 0
    for path in res.stdout:gmatch("[^\n]+") do
      local folder, name = path:match("^(.*)/([^/]+)$")
      n += 1
      table.insert(results, {
        id = path,
        title = name or path,
        subtitle = shortPath(folder or ""),
        glyph = "file",
        score = LIMIT - n,
      })
    end
    if n == 0 then
      results = { { id = "none", title = "No matching files", glyph = "file-off" } }
    end
    launcher.setResults(text, results)
  end)
end

function onActivate(id)
  if id == "hint" or id == "none" then return end
  noctalia.runAsync({ "xdg-open", id })
end
