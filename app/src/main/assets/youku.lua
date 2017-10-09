local mres = require("mres")
local mbase = require("mbase")
local cjson = require("cjson")
local VD = mbase.VD
local ER = mres.ER
require("math")
local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson2 = cjson.new()
local table = require("table")
local base64 = require("mime")
local bit = require("bit")
local util = require("util")
local crypto = require("crypto")
local perr = require("perr")
local YoukuParser = mbase:new()
YoukuParser.domain = {"youku.com"}
local urlencode = function(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w ])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end
local function getEncryptVideoUrl(video_info, video_type, extra_info)
  local time = os.time()
  local ykss = ""
  local ep = ""
  local key = ""
  local ck = ""
  if next(extra_info) ~= nil and next(video_info.sid_data) ~= nil then
    key = "9e3633aadde6bfec"
    ck = extra_info.ck
    if ck ~= nil then
      local ck_table = mbase.split(ck, "=")
      if #ck_table == 2 and video_info.IsVip ~= nil then
        ykss = ck_table[2]
      end
    end
    if key ~= nil then
      local text = video_info.sid_data.sid .. "_" .. video_info.videoId2 .. "_" .. video_info.sid_data.token
      local cipher = "AES-128-ECB"
      local iv
      local res = assert(crypto.encrypt(cipher, text, key, iv))
      ep = urlencode(mime.b64(res))
    end
  end
  if ep == nil then
    return
  else
    local url = string.format("http://pl.youku.com/playlist/m3u8?ts=%s&keyframe=1&ykss=%s&vid=%s&type=%s&ctype=20&sid=%s&token=%s&ev=1&oip=%s&did=%s&ep=%s", time, ykss, video_info.videoId2, video_type, video_info.sid_data.sid, video_info.sid_data.token, video_info.sid_data.oip, video_info.did, ep)
    return url
  end
end
local function getExtraInfo(page_url, result)
  local query = urlencode(page_url)
  if query == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get query")
  end
  local api_url = "http://api.molitv.cn/moli20/moli-tv/TvVideoExtra.aspx?en=1&url=" .. query
  local decryptText = mbase.fetchUrl(api_url)
  if decryptText == nil then
    perr.throwErr(ER.kHtmlContentError, "api_url error")
  end
  local flag, base64_decode = pcall(mime.unb64, decryptText)
  if flag ~= true then
    perr.throwErr(ER.kHtmlContentError, "get base64_decode filed")
  end
  local key = {
    232,
    191,
    153,
    229,
    176,
    177,
    230,
    152,
    175,
    229,
    175,
    134,
    231,
    160,
    129,
    228,
    189,
    160,
    231,
    159,
    165,
    233,
    129,
    147,
    228,
    185,
    136,
    229,
    147,
    136,
    63,
    63
  }
  local iv = {
    230,
    136,
    145,
    231,
    159,
    165,
    233,
    129,
    147,
    228,
    186,
    134,
    229,
    147,
    136,
    33
  }
  local res_str, e = crypto.decrypt("aes-256-cbc", base64_decode, string.char(unpack(key)), string.char(unpack(iv)))
  if res_str ~= nil then
    local f, res = pcall(cjson2.decode, res_str)
    if f ~= true then
      perr.throwErr(ER.kJsonParseFailed, "res_str parse failed")
    end
    if e == nil then
      return res
    end
  else
    perr.throwErr(ER.kInvalidURLFormat, "base64_decode decrypt failed")
  end
end
local function parseEncryptUrl(video_info, extra_info, result)
  local data = {}
  local url = string.format("http://tv.api.3g.youku.com/common/v3/hasadv/play?id=%s&format=1,5,6,7,8&point=1&language=guoyu&cl=0&password=&site=1&position=7&is_fullscreen=1&player_type=tvdevice&sessionid=D867135229A925C8&device_type=tv&device_brand=MI&ouid=7eaf57ea1c5fb1fb&aw=a&rst=m3u8&version=1.0&pid=e80933b38c5c019d&guid=%s&ver=2.2.0&network=ethernet&ctype=20&did=%s&hd3_limit=1&has_episode=1&serial=0", video_info.videoId2, video_info.did, video_info.did)
  local url_source = mbase.fetchUrl(url)
  if url_source == nil then
    perr.throwErr(ER.kHtmlContentError, "get url_source failed")
  end
  local flag, url_table = pcall(cjson.decode, url_source)
  if flag ~= true then
    perr.throwErr(ER.kHtmlContentError, "url parse failed")
  end
  if next(url_table.sid_data) ~= nil then
    data.token = url_table.sid_data.token
    data.oip = url_table.sid_data.oip
    data.sid = url_table.sid_data.sid
    video_info.sid_data = data
    if next(video_info) ~= nil and next(video_info.vds) ~= nil then
      for k, v in pairs(video_info.vds) do
        if k == "SD" then
          local video_url = getEncryptVideoUrl(video_info, "flv", extra_info)
          if video_url ~= nil then
            result:add(VD.SD, video_url)
          end
        elseif k == "HD" then
          local video_url = getEncryptVideoUrl(video_info, "mp4", extra_info)
          if video_url ~= nil then
            result:add(VD.HD, video_url)
          end
        elseif k == "HD2" then
          local video_url = getEncryptVideoUrl(video_info, "hd2", extra_info)
          if video_url ~= nil then
            result:add(VD.HD2, video_url)
          end
        elseif k == "_1080P" then
          local video_url = getEncryptVideoUrl(video_info, "hd3", extra_info)
          if video_url ~= nil then
            result:add(VD._1080P, video_url)
          end
        end
      end
    else
      perr.throwErr(ER.kHtmlContentError, "video_info or video_info['vds'] is error")
    end
  else
    perr.throwErr(ER.kHtmlContentError, "url_table['sid_data'] is empty")
  end
end
local function parserVideoByInfo(page_url, video_info, result)
  local video_url = ""
  local extra_info = {}
  if next(video_info) ~= nil and next(video_info.vds) ~= nil then
    extra_info = getExtraInfo(page_url)
    if next(extra_info) ~= nil then
      extra_info.src = page_url
      parseEncryptUrl(video_info, extra_info, result)
      if result:isDataEmpty() then
        perr.throwErr(ER.kHtmlContentError, "result is empty after parseEncryptUrl()")
      end
    else
      perr.throwErr(ER.kHtmlContentError, "get extra_info failed")
    end
  else
    perr.throwErr(ER.kHtmlContentError, "video_info or video_info['vds'] is error")
  end
end
local function getVideoInfo(page_url)
  local info = {}
  info.vds = {}
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find html_source")
  end
  local _, _, video_id = string.find(html_source, "videoId[%s]*=[%s]*['\"]?([%d]+)['\"]?")
  if video_id == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find video_id")
  end
  info.videoId = video_id
  local _, _, video_id2 = string.find(page_url, "/id_([%w]+)_?[%S]*.html")
  if video_id2 ~= nil then
    info.videoId2 = video_id2
  else
    perr.throwErr(ER.kHtmlContentError, "can not find video_id2")
  end
  local url = "http://v.youku.com/player/getPlayList/VideoIDS/" .. video_id .. "/timezone/+08/version/5/source/video"
  local url_source = mbase.fetchUrl(url)
  if mbase.isStringEmpty(url_source) then
    perr.throwErr(ER.kHtmlContentError, "url_source is empty")
  end
  local flag, url_json = pcall(cjson.decode, url_source)
  if flag ~= true then
    perr.throwErr(ER.kJsonParseFailed, "url parse failed")
  end
  if next(url_json.data) ~= nil then
    local data_source = url_json.data[1]
    if next(data_source.stream_ids) ~= nil then
      for k, v in pairs(data_source.stream_ids) do
        if k == "flv" then
          info.vds.SD = ""
        end
        if k == "mp4" then
          info.vds.HD = ""
        end
        if k == "hd2" then
          info.vds.HD2 = ""
        end
        if k == "hd3" then
          info.vds._1080P = ""
          info.IsVip = true
        end
      end
    else
      perr.throwErr(ER.kHtmlContentError, "stream_ids is empty")
    end
    local trial = data_source.trial
    if trial ~= nil then
      info.IsVip = true
    end
  else
    perr.throwErr(ER.kHtmlContentError, "can not find url_['data']")
  end
  return info
end
function YoukuParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local video_info = getVideoInfo(page_url)
  if next(video_info) == nil then
    perr.throwErr(ER.kHtmlContentError, "video_info is empty")
  end
  video_info.did = mbase.generateUUID()
  video_info.guid = mbase.generateUUID()
  if video_info.did == nil or video_info.guid == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get did OR guid")
  end
  parserVideoByInfo(page_url, video_info, result)
  if result:isDataEmpty() then
    perr.throwErr(ER.kInvalidJsonContent, "Result is null")
  end
  return result:toJSON()
end
YoukuParser.parserVideoByInfo = parserVideoByInfo
return YoukuParser
