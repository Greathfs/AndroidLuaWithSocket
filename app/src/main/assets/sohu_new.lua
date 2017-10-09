local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local VD = mbase.VD
local ER = mres.ER
local perr = require("perr")
local parser17173 = require("17173")
local sohuParser = mbase:new()
local old_sohu = require("sohu")
sohuParser.domain = {"sohu.com"}
local parseVideoInfo
function parseVideoInfo(video_info, result)
  local kUrlApiFormat = "http://api.tv.sohu.com/v4/video/info/%s.json?callback=jsonp6&api_key=f351515304020cad28c92f70f002261c&plat=17&sver=4.0&partner=78&site=1"
  local api_url = string.format(kUrlApiFormat, video_info.vid)
  local api_source = mbase.fetchUrl(api_url)
  if api_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get api_source")
  end
  local api_json = mbase.getJSONP(api_source)
  if api_json == nil then
    perr.throwErr(ER.kJsonParseFailed, "api_source parse to json failed")
  end
  local state = api_json.status
  if tonumber(state) ~= 200 then
    perr.throwErr(ER.kInvalidJsonContent, api_url)
  end
  local data_t = api_json.data
  if data_t == nil or type(data_t) ~= "table" then
    perr.throwErr(ER.kJsonParseFailed, "data nil with" .. api_url)
  end
  local url_super = data_t.url_super
  if url_super ~= nil and url_super ~= "" then
    result:add(VD.HD2, url_super)
  end
  local url_nor = data_t.url_nor
  if url_nor ~= nil and url_nor ~= "" then
    result:add(VD.SD, url_nor)
  end
  local url_high = data_t.url_high
  if url_high ~= nil and url_high ~= "" then
    result:add(VD.HD, url_high)
  end
  local url_ori = data_t.url_original
  if url_ori ~= nil and url_ori ~= "" then
    result:add(VD._1080P, url_ori)
  end
end
function sohuParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local starts, ends = string.find(page_url, "17173.tv.sohu.com")
  if starts ~= nil and starts > 0 then
    result = parser17173:parse(input)
    if result ~= nil then
      return result
    end
  end
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url source")
  end
  local _, _, vid = string.find(html_source, "vid[%s]*=[%s]*['\"]?([%d]+)['\"]?")
  if vid == nil then
    _, _, vid = string.find(html_source, "vid[%s]*:[%s]*['\"]?([%d]+)")
  end
  if vid ~= nil then
    parseVideoInfo({vid = vid}, result)
  else
    perr.throwErr(ER.kHtmlContentError, "get video_info error")
  end
  if result:isDataEmpty() then
    return old_sohu:parse(input)
  end
  return result:toJSON()
end
return sohuParser
