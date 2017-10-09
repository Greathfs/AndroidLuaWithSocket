local mres = require("mres")
local mbase = require("mbase")
local cjson = require("json")
local UA = mbase.UA
local ER = mres.ER
local VD = mbase.VD
local perr = require("perr")
local videoinfo = require("iqiyi_videoinfo")
local qiyiandroid = require("iqiyi_android")
local VrsQiyiParser = mbase:new()
local QiyiParseRetry = 3
VrsQiyiParser.domain = {"iqiyi.com"}
local function addDataToResult(res, vd, dataUrl)
  if vd == "1" then
    res:add(VD.SD, dataUrl)
  end
  if vd == "2" then
    res:add(VD.HD, dataUrl)
  end
  if vd == "4" then
    res:add(VD.HD2, dataUrl)
  end
  if vd == "5" then
    res:add(VD._1080P, dataUrl)
  end
end
local getVrsM3u8
--取m3u8视频地址
function getVrsM3u8(vrsTvId, vrsVideoId, res, first, retry)
  local kM3u8ApiFormat = "http://cache.m.iqiyi.com/tmts/%s/%s/?t=%s&sc=%s&src=76f90cbd92f94a2e925d83e8ccd22cb7&uid=%s"
  local t = tostring(os.time())
  local args = {}
  args[1] = vrsTvId
  args[2] = vrsVideoId
  args[3] = t
  args[4] = mbase.getMD5(t .. "d5fb4bd9d50c4be6948c97edd7254b0e" .. vrsTvId)
  args[5] = "20140213141851016xMqipWjr10182"
  local api_url = string.format(kM3u8ApiFormat, args[1], args[2], args[3], args[4], args[5])
  local api_result = mbase.fetchUrl(api_url, UA.ChromeDestop)
  if api_result == nil then
    perr.throwErr(ER.kHtmlContentError, "api_url parse failed")
  end
  local flag, api_data = pcall(cjson.decode, api_result)
  if flag ~= true then
    perr.throwErr(ER.kJsonParseFailed, "api_result parse failed")
  end
  local data = api_data.data
  if data ~= nil then
    local vd = mbase.trim(data.vd)
    local m3u = data.m3u
    local m3utx = data.m3utx .. "?src=76f90cbd92f94a2e925d83e8ccd22cb7"
    if vd == "1" or vd == "2" or vd == "4" or vd == "5" then
      local index = string.find(m3u, "?")
      if index ~= nil then
        local video_url = string.sub(m3u, 0, index) .. "?src=76f90cbd92f94a2e925d83e8ccd22cb7"
        addDataToResult(res, vd, video_url)
      else
        addDataToResult(res, vd, m3utx)
      end
    end
    if first == true then
      local array = data.vidl
      if array ~= nil then
        for i = 1, 5 do
          local item_t = array[i]
          if item_t ~= nil then
            local vd_temp = mbase.trim(item_t.vd)
            local vid_temp = item_t.vid
            if vd_temp == vd then
            else
              getVrsM3u8(vrsTvId, vid_temp, res, false, retry)
            end
          end
        end
      end
    end
  else
    local msg
    local code = api_data.code
    if code == "A00001" then
      msg = "\229\143\130\230\149\176\233\148\153\232\175\175" .. api_url
      if retry < QiyiParseRetry then
        local next_retry = retry + 1
        getVrsM3u8(vrsTvId, vrsVideoId, res, first, next_retry)
        return
      end
    end
  end
  if res:isDataEmpty() then
    perr.throwErr(ER.kInvalidJsonContent, "Result is null")
  end
end
--爱奇艺解析开始
function VrsQiyiParser:parse(input)
  local res = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  --取到地址后请求地址，拿到html资源
  local html_source = mbase.fetchUrl(page_url, UA.ChromeDestop)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find html_source")
  end
  local info = videoinfo:new()
  --解析html并返回info
  info:parseDeskTopSource(html_source)

  if info.defaultVideoId ~= nil and info.vrsTvId ~= nil then
    local ok = pcall(function()
      getVrsM3u8(info.vrsTvId, info.defaultVideoId, res, true, 0)
    end)
    if not ok or res:isDataEmpty() then
      qiyiandroid:parseByVideoInfo(info, res)
    end
  else
    perr.throwErr(ER.kHtmlContentError, "QiyiVideoInfo error")
  end
  return res:toJSON()
end
VrsQiyiParser.getVrsM3u8 = getVrsM3u8
return VrsQiyiParser
