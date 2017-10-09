local mres = require("mres")
local mbase = require("mbase")
local cjson = require("cjson")
local ER = mres.ER
local cntvParser = mbase:new()
cntvParser.domain = {"cntv.cn"}
function cntvParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get url")
    return result:toJSON()
  end
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    result:setCode(1, ER.kNetworkIOFailed)
    return result:toJSON()
  end
  local _, _, video_centerid = string.find(html_source, "['\"]videoCenterId['\"][%s]*[:,=][%s]*['\"]([^'\"]+)['\"]")
  if video_centerid == nil then
    result:setCode(ER.kHtmlContentError, "can not find video center id")
    return result:toJSON()
  end
  if video_centerid ~= nil and string.len(video_centerid) > 0 then
    local script_url = "http://vdn.apps.cntv.cn/api/getIpadVideoInfo.do?pid=" .. video_centerid .. "&tai=ipad&from=html5"
    local script_src = mbase.fetchUrl(script_url)
    if script_src == nil then
      result:setCode(ER.kHtmlContentError, "can not find script")
      return result:toJSON()
    end
    local _, _, video_url = string.find(script_src, "['\\\"]hls_url['\\\"][%s]*:[%s]*['\\\"]([^'\\\"]+)['\\\"]")
    if video_url == nil then
      result:setCode(ER.kHtmlContentError, "can not find video url")
      return result:toJSON()
    end
    result:add(self.VD.SD, video_url)
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
  end
  return result:toJSON()
end
return cntvParser
