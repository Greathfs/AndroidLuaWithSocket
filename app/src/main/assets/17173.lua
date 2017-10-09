local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local cjson2 = cjson.new()
local ER = mres.ER
local Game17173Parser = mbase:new()
Game17173Parser.domain = {
  "17173.tv.sohu.com"
}
function Game17173Parser:parse(input)
  local page_url = input.url
  local result = mres:new()
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get page_url")
    return result:toJSON()
  end
  local src = self.fetchUrl(page_url)
  if src == nil then
    result:setCode(1, ER.kNetworkIOFailed)
    return result:toJSON()
  end
  local _, _, vid = string.find(src, "videoId[%s]*:[%s]*['\"]?([%d]+)['\"]?")
  if vid == nil then
    result:setCode(ER.kHtmlContentError, "can ntot get vid")
    return result:toJSON()
  end
  local apiUrl = "http://v.17173.com/api/video/vInfo/id/" .. vid
  local api_src = self.fetchUrl(apiUrl)
  if api_src == nil then
    result:setCode(ER.kHtmlContentError, "HTML not exist")
    return result:toJSON()
  end
  local json_src = cjson.decode(api_src)
  local s, m = pcall(cjson.decode, api_src)
  if s ~= true then
    result:setCode(ER.kInvalidJsonContent, tostring(m))
    return result:toJSON()
  end
  if json_src.success ~= 1 then
    result:setCode(ER.kInvalidJsonContent, "Success != 1")
    return result:toJSON()
  end
  local spiltInfo_t = json_src.data.splitInfo
  for k, v in pairs(spiltInfo_t) do
    if spiltInfo_t[k].def == 1 then
      result:add(self.VD.SD, tostring(string.format("http://v.17173.com/api/%s-%d.m3u8", vid, 1)))
    end
    if spiltInfo_t[k].def == 2 then
      result:add(self.VD.HD, tostring(string.format("http://v.17173.com/api/%s-%d.m3u8", vid, 2)))
    end
    if spiltInfo_t[k].def == 4 then
      result:add(self.VD.HD2, tostring(string.format("http://v.17173.com/api/%s-%d.m3u8", vid, 4)))
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
    return result:toJSON()
  end
  return result:toJSON()
end
return Game17173Parser
