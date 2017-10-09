local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local mres = require("mres")
local ER = mres.ER
local UA = mbase.UA
local VD = mbase.VD
local parser = mbase:new()
parser.domain = {"wasu.cn"}
parser._DES = [[
 
  wasu parser
 ]]
local kPlayApi = "http://www.wasu.cn"
local kWapPlayApi = "http://www.wasu.cn/wap"
local function parseWeb(url, res)
  local src = mbase.fetchUrl(url, UA.ChromeDestop)
  if src == nil then
    res:setCode(1, ER.kNetworkIOFailed)
    return res:toJSON()
  end
  local s, e, playUrl, playKey, playId
  s, e, playUrl = string.find(src, "_playUrl[%s]*=[%s]*['\"]?([^\"']+)['\"]?")
  s, e, playKey = string.find(src, "_playKey[%s]*=[%s]*['\"]?([^\"']+)['\"]?")
  s, e, playId = string.find(src, "_playId[%s]*=[%s]*['\"]?([^\"']+)['\"]?")
  if playUrl ~= nil then
    if string.find(playUrl, "^http://") == nil and playKey ~= nil and playId ~= nil then
      local apiUrl = kPlayApi .. "/Api/getVideoUrl/id/" .. playId .. "/key/" .. playKey .. "/url/" .. playUrl .. "/type/txt"
      playUrl = mbase.fetchUrl(apiUrl)
    end
    local videoUrl = playUrl
    res:add(VD.SD, tostring(videoUrl))
    res:add(VD.HD, tostring(videoUrl))
    return res:toJSON()
  end
  res:setCode(ER.kHtmlContentError, "can not find _playUrl")
  return res:toJSON()
end
local function parseWAP(url, res)
  local src = mbase.fetchUrl(url, UA.ChromeDestop)
  if src == nil then
    res:setCode(1, ER.kNetworkIOFailed)
    return res:toJSON()
  end
  local s, e, playUrl, playKey, playId
  s, e, playUrl = string.find(src, "'url'[%s]*:[%s]*['\"]?([^\"']+)['\"]?")
  s, e, playKey = string.find(src, "'key'[%s]*:[%s]*['\"]?([^\"']+)['\"]?")
  s, e, playId = string.find(src, "'vid'[%s]*:[%s]*['\"]?([^\"']+)['\"]?")
  if playUrl ~= nil then
    if string.find(playUrl, "^http://") == nil and playKey ~= nil and playId ~= nil then
      local apiUrl = kWapPlayApi .. "/Api/getVideoUrl/id/" .. playId .. "/key/" .. playKey .. "/url/" .. playUrl .. "/type/txt"
      playUrl = mbase.fetchUrl(apiUrl)
    end
    local videoUrl = playUrl
    res:add(VD.SD, tostring(videoUrl))
    res:add(VD.HD, tostring(videoUrl))
    return res:toJSON()
  end
  res:setCode(ER.kHtmlContentError, "can not find _playUrl")
  return res:toJSON()
end
function parser:parse(input)
  local page_url = input.url
  if page_url == nil then
    return
  end
  local result = mres:new()
  if string.find(page_url, "/wap/") then
    return parseWAP(page_url, result)
  else
    return parseWeb(page_url, result)
  end
end
return parser
