local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local VD = mbase.VD
local UA = mbase.UA
local ER = mres.ER
local baiduSearchPaser = mbase:new()
baiduSearchPaser.domain = {
  "v.baidu.com"
}
function baiduSearchPaser:parse(input)
  local result = mres:new()
  local page_link_url = input.url
  local input_real = ""
  if page_link_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get linked url")
    return result:toJSON()
  end
  local video_source = mbase.fetchUrl(page_link_url)
  if video_source == nil then
    result:setCode(ER.kHtmLContentError, "can not get video_source")
    return result:toJSON()
  end
  local _, _, real_url = string.find(video_source, "<a[%s]href=\"([%S%s]-)\"")
  if real_url == nil then
    result:setCode(ER.kHtmlContentError, "can not find real url")
    return result:toJSON()
  end
  if input.vd == nil then
    input.vd = "1"
  end
  input_real = "{\"url\":\"" .. real_url .. "\",\"vd\":\"" .. input.vd .. "\"}"
  if can_parse(input_real) == false then
    result:setCode(ER.kCanNotFindVideoParser, "can not find th suitable parser")
    return result:toJSON()
  end
  return parse_video(input_real)
end
return baiduSearchPaser
