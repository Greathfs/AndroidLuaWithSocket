local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local bit = require("bit")
local perr = require("perr")
local ER = mres.ER
local VD = mbase.VD
local UA = mbase.UA
local LetvYunBase = {
  __class__ = "LetvYunBase",
  kSWFAPI = "http://yuntv.letv.com/bcloud.swf?"
}
function LetvYunBase:new()
  local t = {}
  setmetatable(t, {__index = LetvYunBase})
  return t
end
LetvYunBase.domain = {
  "yuntv.letv.com"
}
local kGPCAPI = "http://api.letvcloud.com/gpc.php?cf=ios&sign=signxxxxx&ver=2.0&format=jsonp"
local kDeLib = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local kVideoDef = {}
kVideoDef[1] = "video_1"
kVideoDef[2] = "video_2"
kVideoDef[3] = "video_3"
kVideoDef[4] = "video_4"
local function getVDByWidth(width, height)
  if height >= 1080 then
    return VD._1080P
  elseif height >= 720 then
    return VD._720P
  elseif height >= 540 then
    return VD.HD
  else
    return VD.SD
  end
end
local function decode(source)
  local d, b, a, e, h
  local result = ""
  if source == nil then
    return source
  end
  local len = string.len(source)
  local i = 1
  while len >= i do
    d = string.find(kDeLib, string.sub(source, i, i)) - 1
    a = string.find(kDeLib, string.sub(source, i + 1, i + 1)) - 1
    e = string.find(kDeLib, string.sub(source, i + 2, i + 2)) - 1
    h = string.find(kDeLib, string.sub(source, i + 3, i + 3)) - 1
    b = bit.bor(bit.lshift(d, 18), bit.lshift(a, 12), bit.lshift(e, 6), h)
    d = bit.band(bit.rshift(b, 16), 255)
    a = bit.band(bit.rshift(b, 8), 255)
    b = bit.band(b, 255)
    if e == 64 then
      result = result .. string.char(d)
    elseif h == 64 then
      result = result .. string.char(d, a)
    else
      result = result .. string.char(d, a, b)
    end
    i = i + 4
  end
  return result
end
function LetvYunBase:getVideoUrl(letvObj, page_url, result)
  local callback = "&callback=fn" .. os.time()
  if letvObj == nil or letvObj.vu == nil or letvObj.uu == nil then
    perr.throwErr(ER.kJsonParseFailed, "can not find uu or uv")
  end
  local api = kGPCAPI .. callback .. "&vu=" .. letvObj.vu .. "&uu=" .. letvObj.uu
  local headers = {Referer = page_url}
  local jsonCallback = mbase.fetchUrl(api, UA.IPAD, nil, nil, headers)
  if jsonCallback == nil then
    perr.throwErr(ER.kInvalidJsonContent, "can not get jsonCallback")
  end
  local jsonCallback_P = mbase.getJSONP(jsonCallback)
  if jsonCallback_P ~= nil then
    if jsonCallback_P.data ~= nil then
      if jsonCallback_P.data.video_list ~= nil then
        for i, v in ipairs(kVideoDef) do
          if jsonCallback_P.data.video_list[v] ~= nil then
            local vwidth = jsonCallback_P.data.video_list[v].vwidth
            local vheight = jsonCallback_P.data.video_list[v].vheight
            local source = jsonCallback_P.data.video_list[v].main_url
            local videoUrl = decode(source)
            if videoUrl ~= nil and vwidth ~= nil and vheight ~= nil then
              local vd = getVDByWidth(vwidth, vheight)
              result:add(vd, videoUrl)
            end
          end
        end
      else
        perr.throwErr(ER.kInvalidJsonContent, "can not find video_list in data")
      end
    else
      perr.throwErr(ER.kInvalidJsonContent, "can not find data in jsonCallback_P")
    end
  else
    perr.throwErr(ER.kInvalidJsonContent, "jsonCallback_P content is nil")
  end
  if result:isDataEmpty() then
    perr.throwErr(ER.kJavaException, "getVideoUrl is empty")
  end
  return result
end
function LetvYunBase:parse(input)
  local result = mres:new()
  local page_url = input.url
  if mbase.isStringEmpty(page_url) then
    perr.throwErr(ER.kInvalidURLFormat, "can not get page_url")
  end
  local htmlSource = mbase.fetchUrl(page_url, UA.IPAD)
  local letvYunObj
  if not mbase.isStringEmpty(htmlSource) then
    letvYunObj = self:parserObject(htmlSource)
  else
    perr.throwErr(ER.kHtmlContentError, "htmlsource is empty")
  end
  if letvYunObj == nil or letvYunObj.uu == nil or letvYunObj.vu == nil then
    perr.throwErr(ER.kJsonParseFailed, "can not find uu or uv for letvyun")
  end
  self:getVideoUrl(letvYunObj, page_url, result)
  if result:isDataEmpty() then
    perr.throwErr(ER.kJavaException, "result is empty")
  end
  return result:toJSON()
end
return LetvYunBase
