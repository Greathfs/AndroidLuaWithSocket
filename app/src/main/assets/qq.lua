local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local ER = mres.ER
local qqParser = mbase:new()
qqParser.domain = {"qq.com"}
local function getVideoInfo(page_url)
  local video_info = {}
  video_info.vid = ""
  video_info.vd = "shd"
  local _, _, vid_temp = string.find(page_url, "vid[%s]*=[%s]*['\"]?([^'\"%|]+)")
  local html_source = mbase.fetchUrl(page_url)
  local _, _, vid = string.find(html_source, "['\"]?vid['\"]?[%s]*:[%s]*['\"]?([^'\"%|]+)")
  video_info.vid = vid_temp or vid
  return video_info
end
local function getRealUrlPart(content)
  local cur, post, item
  local content_part = mbase.split(content, "\n")
  local content_size = #content_part
  for i = content_size, 1, -1 do
    cur = content_part[i]
    if string.find(cur, "EXT%-X%-STREAM%-INF") ~= nil then
      if string.find(post, "#") == nil then
        item = post
        break
      end
      i = i + 2
      post = content_part[i]
      if string.find(post, "#") == nil then
        item = post
      end
      while i ~= 0 do
        i = i + 1
        post = content_part[i]
        if string.find(post, "#") == nil then
          item = post
          break
        end
      end
      break
    else
      post = cur
    end
  end
  return item
end
function qqParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get page_url")
    return result:toJSON()
  end
  local flag = true
  local video_info = {}
  flag, video_info = pcall(getVideoInfo, page_url)
  if flag ~= true then
    result:setCode(ER.kHtmlContentError, video_info)
    return result:toJSON()
  end
  if video_info ~= nil and video_info.vid ~= nil then
    local json_url = "http://vv.video.qq.com/gethls?vid=" .. video_info.vid .. "&otype=xml&format=2"
    local script = mbase.fetchUrl(json_url)
    if script == nil then
      result:setCode(ER.kHtmlContentError, "Script is empty")
      return result:toJSON()
    end
    local _, _, m3u8_url = string.find(script, "<url>([^<]*)</url>")
    if m3u8_url == nil then
      result:setCode(ER.kHtmlContentError, "can not get m3u8_url")
      return result:toJSON()
    end
    local _, _, url_part1 = string.find(m3u8_url, "([%s%S]*%.mp4/)")
    if url_part1 == nil then
      result:setCode(ER.kHtmlContentError, "can not get url_part1")
      return result:toJSON()
    end
    local content = mbase.fetchUrl(m3u8_url)
    if content == nil then
      result:setCode(ER.kHtmlContentError, "can not get content")
      return result:toJSON()
    end
    local url_part2 = getRealUrlPart(content)
    if url_part2 == nil then
      result:setCode(ER.kHtmlContentError, "can not get url_part2")
      return result:toJSON()
    end
    local video_url = url_part1 .. url_part2
    result:add(self.VD.SD, video_url)
    if result:isDataEmpty() then
      result:setCode(ER.kInvalidJsonContent, "Result is null")
    end
  else
    result:setCode(ER.kHtmlContentError, "can not find videoId")
  end
  return result:toJSON()
end
return qqParser
