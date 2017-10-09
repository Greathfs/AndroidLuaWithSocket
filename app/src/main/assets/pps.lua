local mres = require("mres")
local mbase = require("mbase")
local md5 = require("md5")
local cjson = require("cjson")
local vrsqiyi = require("vrsqiyi")
local VD = mbase.VD
local UA = mbase.UA
local ER = mres.ER
local ppsParser = mbase:new()
local QiyiParseRetry = 3
local kPreVD = {"0", "1"}
ppsParser.domain = {"pps.tv"}
local tableHasKey = function(url_list, key_value)
  local flag = false
  for k, v in pairs(url_list) do
    if v == key_value then
      flag = true
    end
  end
  return flag
end
--解析pps资源
local function parsePPS(url_key, result)
  local url_list = {}
  for i = 1, 2 do
    local play_url = "http://dp.ppstv.com/get_play_url_cdn.php?sid=" .. url_key .. "&flash_type=1&type=" .. kPreVD[i]
    local video_url = mbase.fetchUrl(play_url, UA.ChromeDestop)
    video_url = mbase.urlencodeComponent(video_url)
    local flag = tableHasKey(url_list, video_url)
    if string.find(video_url, "http") ~= nil and flag == false then
      if i == "0" then
        result:add(VD.SD, video_url)
      end
      if i == "1" then
        result:ad(VD.HD, video_url)
      end
      url_list[video_url] = play_url
    end
  end
end
--解析
function ppsParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get page_url")
    return result:toJSON()
  end
  --请求 html 资源 用的是Chorom桌面版
  local html_source = mbase.fetchUrl(page_url, UA.ChromeDestop)
  if html_source == nil then
    result:setCode(ER.kHtmlContentError, "can not find html_source")
    return result:toJSON()
  end

  local isqyIndex = string.find(html_source, "['\"]*isqy['\"]*[%s]*:[%s]*['\"]*1['\"]*")
  local _, _, newqy = string.find(html_source, "_PAGE_CONF%[\"iqiyi_id\"%][%s]*=([%s%S]-);")
  local sign = true
  if isqyIndex ~= nil then
    local html_len = string.len(html_source)
  -- 爱奇艺的资源
    local iqiyi_source = string.sub(html_source, isqyIndex, html_len)
  --Tv id
    local _, _, tv_id = string.find(iqiyi_source, "['\"]*tv_id['\"]*[%s]*:[%s]*['\"]*([%d]+)")
  --视频 id
    local _, _, videoId = string.find(iqiyi_source, "['\"]*vid['\"]*[%s]*:[%s]*['\"]*([^\"']+)[\"']")
  -- 拿到id后获取m3u8的视频地址
    if tv_id ~= nil and videoId ~= nil then
      vrsqiyi.getVrsM3u8(tv_id, videoId, result, true, 0)
    else
      --返回错误信息
      result:setCode(ER.kHtmlContentError, "can not find tv_id or videoId")
      return result:toJSON()
    end

  elseif newqy ~= nil then
    local content = mbase.trim(newqy)
  --执行 json.decode
    local flag, content_t = pcall(cjson.decode, mbase.trim(content))
    if flag ~= true then
      result:setCode(ER.kJsonParseFailed, "newqy can not parse to json")
      return result:toJSON()
    end
    local tvid = content_t.tvId
    local vds = content_t.vid
    if tvid == "" or vds == "" then
      result:setCode(ER.kHtmlContentError, "tvid or vds is empty")
      return result:toJSON()
    end
    for k, v in pairs(vds) do
      local videoId = vds[k]
      vrsqiyi.getVrsM3u8(tvid, videoId, result, true, 0)
    end
  else
  --第三种情况 都为空
    local urlkey = string.find(html_source, "['\"]url_key['\"][%s]*:[%s]*['\"]([%w]*)['\"]")
    local _, _, video_id = string.find(html_source, "['\"]video_id['\"][%s]*:[%s]*['\"]([%d]*)['\"]")
    if video_id ~= nil then
      if urlkey == nil then
        urlkey = ""
      end
      parsePPS(urlkey, result)
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, page_url)
    return result:toJSON()
  end
  return result:toJSON()
end
return ppsParser
