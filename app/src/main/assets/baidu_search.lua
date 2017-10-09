local mbase = require("mbase")
local mres = require("SearchRes")
local cjson = require("cjson")
local iconv = require("iconv")
local SpecialSearch = require("baiduSpecialSearch")
local ER = mres.ER
local UA = mbase.UA
local contentFilter = require("baidu_kw_black")
local baiduSearch = {}
function baiduSearch.getRealUrl(url)
  local link_src = mbase.fetchUrl("http://v.baidu.com" .. url)
  if link_src == nil then
    return
  end
  local _, _, real_url = string.find(link_src, "<a%shref=\"([%s%S]-)\"%s")
  return real_url
end
local getVideoId
function getVideoId(src, videoId_t)
  local starts1, ends1 = string.find(src, "sp%-cont%-split")
  if starts1 == nil then
    local _, _, videoId = string.find(src, "id=\"tv_([%d]*)_info")
    if videoId ~= nil then
      table.insert(videoId_t, videoId)
    else
      return
    end
  else
    src = string.sub(src, ends1, string.len(src))
    local _, _, videoId = string.find(src, "id=\"tv_([%d]*)_info")
    if videoId ~= nil then
      table.insert(videoId_t, videoId)
    else
      return
    end
    getVideoId(src, videoId_t)
  end
end
local block_json = contentFilter.block_json()
function baiduSearch.getSpecialResult(input1)
  local result = mres:new()
  local status, input = pcall(cjson.decode, input1)
  if status == false then
    result:setCode(ER.kHtmlContentError, "can not parse input")
    return result:toJSON()
  end
  local searchItem = input.kw
  if searchItem == nil then
    result:setCode(ER.kHtmlContentError, "can not find searchItem")
    return result:toJSON()
  end
  if contentFilter.forbidden_keywords(searchItem, block_json) then
    result:setCode(ER.kHtmlContentError, "kw forbidden")
    return result:toJSON()
  end
  local kSearchFormat = "http://v.baidu.com/v?word=%s&ct=301989888&rn=20&pn=0&db=0&s=0&fbl=800&ie=utf-8&pagelets[]=main&pagelets[]=widget_log&force_mode=1"
  local search_url = string.format(kSearchFormat, mbase.urlencode(searchItem))
  local src = mbase.fetchUrl(search_url, mbase.UA.ChromeDestop)
  if src == nil then
    result:setCode(ER.kHtmlContent, "can not get src")
    return result:toJSON()
  end
  local extra_header = {
    ["X-Requested-With"] = "XMLHttpRequest"
  }
  local videoId_t = {}
  local content = mbase.fetchUrl(search_url, nil, nil, nil, extra_header)
  local status_con, con = pcall(cjson.decode, content)
  if status_con ~= true then
    result:setCode(ER.kHtmlContentError, "can not get con")
    return result:toJSON()
  end
  if con.pagelets ~= nil then
    for k, v in pairs(con.pagelets) do
      if string.find(v.id, "[%S%s]*qk_5[%S%s]*") then
        getVideoId(v.html, videoId_t)
      end
    end
  end
  for i = 1, #videoId_t do
    local linked_url = string.format("http://v.baidu.com/htvplaysingles/?id=%s&e=1", videoId_t[i])
    local linked_content = mbase.fetchUrl(linked_url, UA.ChromeDestop)
    if linked_content == nil then
      result:setCode(ER.kHtmlContentError, "can not get linked_content")
      return result:toJSON()
    end
    local status, content_t = pcall(cjson.decode, linked_content)
    if status ~= true then
      result:setCode(ER.kHtmlContent, "can not get content_t")
      return result:toJSON()
    end
    local max_size = #content_t.videos
    local cur_video = content_t.videos[max_size]
    if cur_video == nil then
      result:setCode(ER.kHtmlContentError, "can not get cur_video")
      return result:toJSON()
    end
    local cur_video_url = "http://v.baidu.com" .. cur_video.url
    local link_src = mbase.fetchUrl(cur_video_url)
    if link_src == nil then
      result:setCode(ER.kHtmlContentError, "can not get link_src")
      return result:toJSON()
    end
    local _, _, real_url = string.find(link_src, "<a%shref=\"([%s%S]-)\"%s")
    if real_url == nil then
      result:setCode(ER.kHtmlContentError, "can not get real_url")
      return result:toJSON()
    end
    local title = cur_video.title
    if title == nil then
      result:setCode(ER.kHtmlContentError, "can not get title")
      return result:toJSON()
    end
    local big_special = {}
    big_special.title = title
    big_special.url = real_url
    big_special.pic = img_url
    result:add("sc", big_special)
  end
  if result:isDataEmpty() then
    result:setCode(ER.kHtmlContentError, "result is empty")
    return result:toJson()
  end
  return ""
end
local getNormalAreaContent
function getNormalAreaContent(api_src, normal_content)
  local starts_position = string.find(api_src, "{")
  local ends_position = string.find(api_src, "}")
  if starts_position ~= nil and ends_position ~= nil then
    local content = string.sub(api_src, starts_position, ends_position)
    table.insert(normal_content, content)
    api_src = string.sub(api_src, ends_position + 1, string.len(api_src))
    getNormalAreaContent(api_src, normal_content)
  else
    return
  end
end
function baiduSearch.getSearchResult(input1)
  local result = mres:new()
  local status, input = pcall(cjson.decode, input1)
  if status == false then
    result:setCode(ER.kHtmlContentError, "can not parse input")
    return result:toJSON()
  end
  local searchItem = input.kw
  if searchItem == nil then
    result:setCode(ER.kHtmlContentError, "can not get searchItem")
    return result:toJSON()
  end
  if contentFilter.forbidden_keywords(searchItem, block_json) then
    result:setCode(ER.kHtmlContentError, "kw forbidden")
    return result:toJSON()
  end
  local pageNumber = input.pn
  if pageNumber == nil then
    pageNumber = 0
  end
  local specialNum = 0
  if pageNumber <= 5 then
    local searchTarget = SpecialSearch:new(searchItem)
    local episodes = searchTarget:fetchResult()
    if episodes ~= nil and #episodes > 0 then
      for i, v in ipairs(episodes) do
        local infos = v[1].episodes[1].infos
        local episode = v[1].episodes[1].episode
        if infos ~= nil and episode ~= nil and #episode > 0 then
          for ii, ep in ipairs(episode) do
            local cell = {}
            cell.episode = ep.episode
            cell.url = "http://v.baidu.com" .. ep.url
            if ep.single_title ~= nil then
              cell.title = infos.title .. ep.episode .. "-" .. ep.single_title
            else
              cell.title = infos.title .. ep.episode
            end
            cell.pic = ep.thumbnail
            cell.srcShortUrl = ep.site_url
            specialNum = specialNum + 1
            result:add("sr", cell)
            if contentFilter.forbidden_site(cell) == false and contentFilter.forbidden_keywords(cell.title, block_json) == false then
              specialNum = specialNum + 1
              result:add("sr", cell)
            end
          end
        end
      end
    end
  end
  local normal = {}
  local kApiFormat = "http://v.baidu.com/v?word=%s&ct=905969664&ie=utf-8&pn=%s&%s#"
  searchItem = mbase.urlencode(searchItem)
  local time = os.time()
  local pn = pageNumber
  local api_url = string.format(kApiFormat, searchItem, pn, time)
  local api_src = mbase.fetchUrl(api_url, mbase.UA.ChromeDestop)
  if api_src == nil then
    result:setCode(ER.kHtmlContentError, "can not get api_src")
    return result:toJSON()
  end
  local api_json = mbase.getJSONP(api_src)
  local totalNumber = api_json.dispNum
  if totalNumber == nil then
    result:setCode(ER.kHtmlContentError, "can not get total number")
    return result:toJSON()
  end
  if totalNumber == "0" then
    result:add("total", totalNumber)
    return result:toJSON()
  end
  local normal_content = api_json.data
  if normal_content == nil then
    result:setCode(ER.kHtmlContentError, "data is null")
    return result:toJSON()
  end
  for k, v in pairs(normal_content) do
    local normal_cell = {}
    if v.ti ~= nil then
      local title = v.ti
      if title == nil then
        title = searchItem
      end
      local url = v.url
      local pic = v.pic
      local duration = v.duration
      local duration_hour = v.duration_hour
      local srcShortUrlExt = v.srcShortUrlExt
      local srcShortUrl = v.srcShortUrl
      if title ~= nil and pic ~= nil then
        local real_url = ""
        if url ~= nil then
          if string.find(url, "http:") == nil then
            real_url = "http://v.baidu.com" .. url
          else
            real_url = url
          end
        end
        if real_url ~= nil and pic ~= nil and totalNumber ~= nil and title ~= nil then
          normal_cell.url = real_url
          normal_cell.pic = pic
          normal_cell.duration = duration
          normal_cell.duration_hour = duration_hour
          normal_cell.srcShortUrl = srcShortUrl
          normal_cell.srcShortUrlExt = srcShortUrlExt
          normal_cell.title = title
          result:add("sr", normal_cell)
          if contentFilter.forbidden_site(normal_cell) == false and contentFilter.forbidden_keywords(normal_cell.title, block_json) == false then
            result:add("sr", normal_cell)
          end
        end
      end
    end
  end
  totalNumber = totalNumber + specialNum
  result:add("total", totalNumber)
  if result:isDataEmpty() then
    result:setCode(ER.kHtmlContentError, "result is empty")
    return result:toJSON()
  end
  return ""
end
local findRlinkContent = function(content, searchItem)
  local value_t = {}
  for _, v in pairs(content) do
    if v.key ~= nil and v.value ~= nil then
      local _, _, item = string.find(v.key, "[%S%s]*query::([%S%s]*)")
      if item ~= nil then
        for _, c in pairs(v.value) do
          table.insert(value_t, c)
        end
      end
    end
  end
  return value_t
end
function baiduSearch.getRlinksResult(input1)
  local result = mres:new()
  local status, input = pcall(cjson.decode, input1)
  if status == false then
    result:setCode(ER.kHtmlContentError, "can not parse input")
    return result:toJSON()
  end
  local searchItem = input.kw
  if searchItem == nil then
    result:setCode(ER.kHtmlContentError, "can not get searchItem")
    return result:toJSON()
  end
  local rlinks = {}
  local pn = 0
  local kSearchFormat = "http://v.baidu.com/rec/zhixin/zxrp?query=%s"
  local search_url = string.format(kSearchFormat, mbase.urlencode(searchItem))
  local html_source = mbase.fetchUrl(search_url, mbase.UA.ChromeDestop)
  if html_source == nil then
    result:setCode(ER.kHtmlContentError, "can not get html source")
    return result:toJSON()
  end
  local stat, cont = pcall(cjson.decode, html_source)
  if stat == false then
    result:setCode(ER.kHtmlContentError, "html_source parse to json failed")
    return result:toJSON()
  end
  local value_t = {}
  for i = 1, 3 do
    value_t = findRlinkContent(cont, searchItem)
    if next(value_t) ~= nil then
      break
    end
  end
  if #value_t ~= 0 then
    for i = 1, table.getn(value_t) do
      local temp = {}
      local title = value_t[i]
      temp.title = title
      result:add("kw", temp)
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kZeroContent, "result is empty")
  end
  return ""
end
return baiduSearch
