local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local iconv = require("iconv")
local jsonFinder = require("jsonFinder")
local kapiUrlFormat = "http://v.baidu.com/v?word=%s&ct=301989888&rn=20&pn=0&db=0&s=0&fbl=800&ie=utf-8&oq=&f=3&rsp=2"
local BaiduSpecialSearch = {
  __class__ = "BaiduSpecialSearch"
}
BaiduSpecialSearch_MT = {__index = BaiduSpecialSearch}
function BaiduSpecialSearch:new(kw)
  local t = {}
  setmetatable(t, BaiduSpecialSearch_MT)
  t.requestUrl = string.format(kapiUrlFormat, mbase.urlencode(kw))
  return t
end
function BaiduSpecialSearch:fetchResult()
  local result = {}
  local content = mbase.fetchUrl(self.requestUrl, nil, nil, nil, nil)
  while string.len(content) > 0 do
    local normal_content
    local starts, _ = string.find(content, "episodes:")
    local _, ends = string.find(content, "isPaysite:")
    if ends == nil then
      _, ends = string.find(content, "logStr:")
    end
    if starts ~= nil and ends ~= nil then
      normal_content = string.sub(content, starts, ends + 6)
      normal_content = string.gsub(normal_content, "episodes", "\"episodes\"")
      normal_content = string.gsub(normal_content, "\n", "")
      normal_content = string.gsub(normal_content, "\r", "")
      normal_content = string.gsub(normal_content, " ", "")
      local s, _, id = string.find(normal_content, "id[%s]?:[%s]?[\\'\"]([^\\'\"]+)")
      local _, _, title = string.find(normal_content, "title[%s]?:[%s]?[\\'\"]([^\\'\"]+)")
      local _, _, types = string.find(normal_content, "type[%s]?:[%s]?[\\'\"]([^\\'\"]+)")
      local _, _, lastEpisode = string.find(normal_content, "lastEpisode[%s]?:[%s]?[\\'\"]([^\\'\"]+)")
      local _, _, maxEpisode = string.find(normal_content, "maxEpisode[%s]?:[%s]?[\\'\"]([^\\'\"]+)")
      local _, _, isPaysite = string.find(normal_content, "isaysite[%s]?:[%s]?([^%s]+)")
      local info = {}
      if id ~= nil and title ~= nil then
        info.id = id
        info.title = title
        info.type = types
        info.lastEpisode = lastEpisode
        info.maxEpisode = maxEpisode
        info.isPaysite = isPaysite
      end
      normal_content = string.sub(normal_content, 1, s - 1)
      local ss, _ = string.find(string.reverse(normal_content), ",")
      normal_content = string.sub(normal_content, 1, #normal_content - ss)
      normal_content = "{" .. normal_content .. "}"
      local normal_json = mbase.getJSONP(normal_content)
      local normal_res = {}
      if normal_json ~= nil then
        table.insert(normal_res, normal_json)
        local isEmpty = normal_res[1].episodes[1]
        if isEmpty == nil then
          return nil
        end
        if info.id ~= nil and info.title ~= nil then
          normal_res[1].episodes[1].infos = info
        end
        table.insert(result, normal_res)
      end
    else
      break
    end
    content = string.sub(content, ends + 6, string.len(content))
  end
  return result
end
function BaiduSpecialSearch:findEpisodes(content)
  local s, e, v = jsonFinder.findContent(content, "episodes:", "}]")
  if v == nil then
    return nil, nil, nil
  end
  v = v .. "}]}]"
  local t, res = pcall(cjson2.decode, v)
  if t then
    local tmpContent = string.sub(content, e, -1)
    local ss, ee, vv = jsonFinder.findContent(tmpContent, "title[\"]?:", ",")
    vv = string.gsub(vv, "'", "")
    vv = string.gsub(vv, "\"", "")
    return s, e + ee, {title = vv, data = res}
  end
  return nil, nil, nil
end
return BaiduSpecialSearch
