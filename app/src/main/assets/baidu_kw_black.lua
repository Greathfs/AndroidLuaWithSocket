local iconv = require("iconv")
local mbase = require("mbase")
local mres = require("SearchRes")
local cjson = require("cjson")
local ER = mres.ER
local UA = mbase.UA
local function block_json()
  local api_src = mbase.fetchUrl("http://api.tv.moliv.cn/moli20/config/blocked_keys.json", mbase.UA.ChromeDestop)
  if api_src ~= nil then
    local json = mbase.getJSONP(api_src)
    if json ~= nil then
      return json
    end
  end
end
local forbidden_keywords = function(kw, block_json)
  kw = string.gsub(kw, "^%s*(.-)%s*$", "%1")
  if block_json ~= nil then
    local keywords = block_json.keywords
    if keywords ~= nil then
      for i, v in ipairs(keywords) do
        local forbiddens = v.forbidden
        if forbiddens ~= nil then
          for n, v in ipairs(forbiddens) do
            if string.len(kw) == 1 then
              return false
            end
            if kw == v then
              return true
            end
            local s, e = string.find(string.lower(kw), string.lower(v))
            if s ~= nil then
              return true
            end
          end
        end
      end
    end
  end
  return false
end
local denyTB = {"iqiyi"}
local function forbidden_site(cell)
  if cell == nil then
    return true
  end
  local sourceUrl = cell.srcShortUrl
  for _, val in pairs(denyTB) do
    local param1, param2 = string.find(sourceUrl, val)
    if param1 ~= nil then
      return true
    end
  end
  return false
end
return {
  block_json = block_json,
  forbidden_keywords = forbidden_keywords,
  forbidden_site = forbidden_site
}
