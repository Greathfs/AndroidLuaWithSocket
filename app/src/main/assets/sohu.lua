local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local VD = mbase.VD
local ER = mres.ER
local parser17173 = require("17173")
local sohuParser = mbase:new()
sohuParser.domain = {"sohu.com"}
local parseVideoInfo
function parseVideoInfo(video_info, result)
  local kDefaultPageSize = 20
  local kUrlApiFormat = "http://api.tv.sohu.com/v4/album/videos/%s.json?page=%d&pagesize=%d&api_key=7ad23396564b27116418d3c03a77db45&plat=21&sver=1.0.0&partner=816&poid=18&playurls=1&c=%s"
  local api_url = string.format(kUrlApiFormat, video_info.playlistid, video_info.startPage, kDefaultPageSize, video_info.cid)
  local api_source = mbase.fetchUrl(api_url)
  if api_source == nil then
    result:setCode(ER.kHtmlContentError, "can not get api_source")
    return
  end
  local flag, api_json = pcall(cjson.decode, api_source)
  if flag ~= true then
    result:setCode(ER.kJsonParseFailed, "api_source parse to json failed")
    return
  end
  local state = api_json.status
  if state ~= 200 then
    result:setCode(ER.kInvalidJsonContent, api_url)
    return
  end
  local data_t = api_json.data
  if data_t ~= nil then
    if video_info.count == 0 then
      video_info.count = data_t.count
    end
    local videos = data_t.videos
    local findVideo = false
    if videos ~= nil then
      video_info.maxPage = video_info.maxPage + #videos
      for i = 1, #videos do
        local map = videos[i]
        if map == nil then
        else
          local vid = tostring(map.vid)
          if vid ~= video_info.vid then
          else
            findVideo = true
            local url_super = map.url_super
            if url_super ~= nil and url_super ~= "" then
              result:add(VD.HD2, url_super)
            end
            local url_nor = map.url_nor
            if url_nor ~= nil and url_nor ~= "" then
              result:add(VD.SD, url_nor)
            end
            local url_high = map.url_high
            if url_high ~= nil and url_high ~= "" then
              result:add(VD.HD, url_high)
            end
            local url_ori = map.url_original
            if url_ori ~= nil and url_ori ~= "" then
              result:add(VD._1080P, url_ori)
            end
          end
        end
      end
    else
      result:setCode(ER.kJsonParseFailed, "can not find video with max page size " .. video_info.startPage)
      return
    end
    if findVideo == false then
      local nextPage = video_info.startPage + 1
      video_info.startPage = nextPage
      parseVideoInfo(video_info, result)
    end
  end
end
function sohuParser:parse(input)
  local result = mres:new()
  local video_info = {}
  video_info.count = 0
  video_info.startPage = 1
  video_info.maxPage = 0
  local page_url = input.url
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get page_url")
    return result:toJSON()
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
    result:setCode(ER.kHtmlContentError, "can not get page_url source")
    return result:toJSON()
  end
  local _, _, vid = string.find(html_source, "vid[%s]*=[%s]*['\"]?([%d]+)['\"]?")
  local _, _, playlistid = string.find(html_source, "playlistId[%s]*=[%s]*['\"]?([%d]+)['\"]?")
  local _, _, cid = string.find(html_source, "cid[%s]*=[%s]*['\"]?([%d]+)['\"]?")
  if vid ~= nil and playlistid ~= nil and cid ~= nil then
    video_info.vid = vid
    video_info.playlistid = playlistid
    video_info.cid = cid
    parseVideoInfo(video_info, result)
  else
    result:setCode(ER.kHtmlContentError, "get video_info error")
    return result:toJSON()
  end
  if result:isDataEmpty() then
    result:setCode(ER.kHtmlContentError, "result is empty")
  end
  return result:toJSON()
end
return sohuParser
