local mres = require("mres")
local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local ER = mres.ER
local VD = mbase.VD
local perr = require("perr")
local hunantvParser = mbase:new()
local kDefaultJsonHost = "pcvcr.cdn.imgo.tv"
hunantvParser.domain = {
  "hunantv.com"
}
local PatternMatch = function(key, page_src)
  local item_result = ""
  local Pattern = string.format("['\"]?%s[\"']?[%%s]?:[%%s]?[\"']?([^\"',]+)[\"']?", key)
  _, _, item_result = string.find(page_src, Pattern)
  return item_result
end
local function parseVideoJson(apiUrl, result)
  local script_src = mbase.fetchUrl(apiUrl)
  local e, json_res = pcall(cjson.decode, script_src)
  if e == false then
    perr.throwErr(ER.kInvalidJsonContent, apiUrl)
  end
  local err_code = tonumber(json_res.err_code)
  if err_code ~= 200 then
    perr.throwErr(ER.kInvalidJsonContent, apiUrl)
  end
  if json_res.data == nil then
    perr.throwErr(ER.kInvalidJsonContent, apiUrl)
  end
  if json_res.data.videoSources ~= nil and #json_res.data.videoSources > 0 then
    for i, v in pairs(json_res.data.videoSources) do
      if not mbase.isStringEmpty(v.definition) and not mbase.isStringEmpty(v.url) then
        local def = tonumber(v.definition)
        local cdnRes = mbase.fetchUrl(v.url)
        local s, vJSON = pcall(cjson.decode, cdnRes)
        if s == true and string.upper(vJSON.status) == "OK" then
          local videoUrl = vJSON.info
          if not mbase.isStringEmpty(videoUrl) then
            if def == 1 then
              result:add(VD.SD, videoUrl)
            elseif def == 2 then
              result:add(VD.HD, videoUrl)
            elseif def == 3 then
              result:add(VD.HD2, videoUrl)
            end
          end
        end
      end
    end
  end
  return result:toJSON()
end
local function parserVideoInfo(videoInfo)
  local item_result = ""
  local video_info_temp = {}
  video_info_temp.vid = PatternMatch("vid", videoInfo)
  video_info_temp.limit_rate = PatternMatch("limit_rate", videoInfo)
  video_info_temp.file = PatternMatch("file", videoInfo)
  video_info_temp.code = PatternMatch("code", videoInfo)
  video_info_temp.cid = PatternMatch("cid", videoInfo)
  return video_info_temp
end
function hunantvParser:parse(input)
  local result = mres:new()
  local videoInfo_t = {}
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local page_src = mbase.fetchUrl(page_url)
  if page_src == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find page_src")
  end
  local _, starts = string.find(page_src, "window.VIDEOINFO = {")
  local ends, _ = string.find(page_src, "}", starts)
  local videoInfo = string.sub(page_src, starts, ends)
  if videoInfo == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find VIDEOINFO")
  end
  videoInfo_t = parserVideoInfo(videoInfo)
  if videoInfo_t == nil or videoInfo_t.vid == nil then
    perr.throwErr(ER.kHtmlContentError, "video info content error")
  end
  local video_api = "http://pad.api.hunantv.com/video/getById?appVersion=4.1&device=iPad&osType=ios&osVersion=8.1.3&ticket=&videoId=" .. videoInfo_t.vid
  local st, msg = pcall(parseVideoJson, video_api, result)
  if st ~= true then
    perr.throwErr(ER.kM3u8ContentZero, msg)
  end
  if result:isDataEmpty() then
    perr.throwErr(ER.kInvalidJsonContent, "Result is null")
  end
  return result:toJSON()
end
return hunantvParser
