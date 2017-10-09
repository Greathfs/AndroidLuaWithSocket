local mres = require("mres")
local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local perr = require("perr")
local VD = mbase.VD
local ER = mres.ER
local tudouParser = mbase:new()
local youku = require("youku")
tudouParser.domain = {"tudou.com"}
function tudouParser:getVideoInfo(vode)
  local apiUrl = "http://v.youku.com/player/getPlayList/VideoIDS/" .. vode .. "/timezone/+08/version/5/source/video"
  local apiResult = mbase.fetchUrl(apiUrl)
  local ok, jsonResult = pcall(cjson2.decode, apiResult)
  if not ok then
    perr.throwErr(ER.kJsonParseFailed, "parse json err")
  end
  if jsonResult.data == nil or #jsonResult.data == 0 then
    perr.throwErr(ER.kJsonParseFailed, "do not has data node")
  end
  local d = jsonResult.data[1]
  local info = {}
  info.videoId = d.videoid
  info.videoId2 = d.vidEncoded
  info.vds = {}
  if d.trial ~= nil then
    info.IsVip = true
  end
  if d.stream_ids then
    if d.stream_ids.flv ~= nil then
      info.vds.SD = ""
    end
    if d.stream_ids.mp4 ~= nil then
      info.vds.HD = ""
    end
    if d.stream_ids.hd2 ~= nil then
      info.vds.HD2 = ""
    end
    if d.stream_ids.hd3 ~= nil then
      info.vds._1080P = ""
      info.IsVip = true
    end
  end
  info.did = mbase.generateUUID()
  info.guid = mbase.generateUUID()
  if info.did == nil or info.guid == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get did OR guid")
  end
  return info
end
function tudouParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find html_source")
  end
  local _, _, vcode = string.find(html_source, "vcode%s*:%s*['\"]?([^'\"]+)")
  if mbase.isStringEmpty(vcode) then
    perr.throwErr(ER.kHtmlContentError, "can not find video info")
  end
  local videoInfo = self:getVideoInfo(vcode)
  youku.parserVideoByInfo("http://youku.com/", videoInfo, result)
  return result:toJSON()
end
return tudouParser
