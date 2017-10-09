local mbase = require("mbase")
local mres = require("mres")
local bit = require("bit")
local VD = mbase.VD
local UA = mbase.UA
local ER = mres.ER
local zjtvParser = mbase:new()
zjtvParser.domain = {"zjstv.com"}
local kSWFAPI = "http://yuntv.letv.com/bcloud.swf?"
local kGPCAPI = "http://api.letvcloud.com/gpc.php?cf=ios&sign=signxxxxx&ver=2.0&format=jsonp"
local kDeLib = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local kVideoDef = {
  "video_1",
  "video_2",
  "video_3",
  "video_4"
}
local function decode(source)
  local result = ""
  local d, b, a, e, h
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
local function getVideoUrl(letvObject, page_url, result)
  local call_back = "&callback=fn" .. os.time()
  local api = kGPCAPI .. call_back .. "&vu=" .. letvObject.vu .. "&uu=" .. letvObject.uu
  local header_extra = {Referer = page_url}
  local json_call_back = mbase.fetchUrl(api, nil, nil, nil, header_extra)
  if json_call_back == nil then
    return
  end
  local jsonParser = mbase.getJSONP(json_call_back)
  if jsonParser == nil then
    return
  end
  local data = jsonParser.data
  if data ~= nil then
    local video_list = data.video_list
    if video_list ~= nil then
      local video_temp = {}
      for i = 1, 4 do
        video_temp = video_list[kVideoDef[i]]
        if video_temp ~= nil then
          local vwidth = video_temp.vwidth
          local vheight = video_temp.vheight
          local main_source = video_temp.main_url
          local video_url = decode(main_source)
          if video_url == "" then
            return
          end
          if vheight > 1080 then
            result:add(VD._1080P, video_url)
          elseif vheight > 720 then
            result:add(VD.HD2, video_url)
          elseif vheight > 540 then
            result:add(VD.HD, video_url)
          else
            result:add(VD.SD, video_url)
          end
        end
      end
    end
  end
end
local function parserObject(html_source)
  local _, _, vlink = string.find(html_source, "<p[%s]class=\"vlink\">([%s%S]-)<%/p>")
  if vlink == nil then
    _, _, vlink = string.find(html_source, "<embed[%s](src=\"[^\"]+)")
  end
  if vlink == nil then
    return
  end
  local _, _, url_source = string.find(vlink, "src=\"([^\"]+)")
  local status = string.find(url_source, kSWFAPI)
  local uu, vu
  if status ~= nil then
    local query = string.sub(url_source, status + string.len(kSWFAPI))
    local u_info = mbase.split(query, "&")
    local video_info = {}
    for i = 1, #u_info do
      local key = ""
      local value = ""
      local temp = mbase.split(u_info[i], "=")
      if temp[1] == "uu" then
        uu = temp[2]
      elseif temp[1] == "vu" then
        vu = temp[2]
      end
    end
    if uu ~= nil and vu ~= nil then
      local letvObject = {}
      letvObject.uu = uu
      letvObject.vu = vu
      return letvObject
    end
  end
  return
end
function zjtvParser:parse(input)
  local result = mres:new()
  local letvYunObject = {uu = "", vu = ""}
  local page_url = input.url
  if page_url == nil then
    result:setCode(ER.kHtmlContentError, "can not get url")
    return result:toJSON()
  end
  local html_source = mbase.fetchUrl(page_url, UA.IPAD)
  if html_source == nil then
    result:setCode(ER.kHtmlContentError, "can not get html_source")
    return result:toJSON()
  end
  local letvObject = parserObject(html_source)
  if letvObject == nil then
    result:setCode(ER.kHtmlContentError, "can not get uu or vu")
    return result:toJSON()
  end
  getVideoUrl(letvObject, page_url, result)
  if result:isDataEmpty() then
    result:setCode(ER.kHtmlContentError, "result is empty")
  end
  return result:toJSON()
end
return zjtvParser
