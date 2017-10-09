local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local mres = require("mres")
local ku6 = mbase:new()
ku6.domain = {"ku6.com"}
function ku6:parse(input)
  local page_url = input.url
  if page_url == nil then
    return
  end
  local vid, st, ed
  local match = string.find(page_url, "/index_")
  if match ~= nil then
    local src = self.fetchUrl(page_url)
    st, ed, vid = string.find(src, "vid[%s]*:[%s]*['\"]?([^'\"]+)['\"]?")
  else
    s, e, vid = string.find(page_url, "/([^/]+)%.html")
  end
  if vid ~= nil then
    local videoUrl = string.format("http://v.ku6.com/fetchwebm/%s.m3u8", vid)
    videoUrl = string.gsub(videoUrl, "%.%.%.", "..")
    local result = mres:new()
    result:setCode(0)
    result:add(self.VD.SD, videoUrl)
    return result:toJSON()
  end
end
return ku6
