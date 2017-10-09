local mres = require("mres")
local mbase = require("mbase")
local cjson = require("json")
local bit = require("bit")
local perr = require("perr")
local videoinfo = require("iqiyi_videoinfo")
local UA = mbase.UA
local ER = mres.ER
local VD = mbase.VD
local QiyiParser = mbase:new()
local QiyiSecurity = {
  __class__ = "QiyiSecurity",
  PLAY_SECRET_KEY_ONE = 1121111727,
  PLAY_SECRET_KEY_TWO = ",rI1:?CJczS3AwJ$",
  EXPORT_KEY = "317e617581c95c3e8a996f8bff69607b",
  ClientVersion = "5.3.1"
}
function QiyiSecurity:getSignedHeader(t1)
  t1 = t1 or math.ceil(os.time() / 1000)
  local t = bit._xor(t1, self.PLAY_SECRET_KEY_ONE)
  local sign = mbase.getMD5(t1 .. self.PLAY_SECRET_KEY_TWO .. self.EXPORT_KEY .. self.ClientVersion)
  return {t = t, sign = sign}
end
QiyiParser.QiyiSecurity = QiyiSecurity
local kIDFV = "D993EB05A519D7C9D3360B055A3B312A"
local kUUID = mbase.generateUUID()
local kOpenUDID = string.lower(mbase.generateHex(16))
function QiyiParser:parse(input)
  local res = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local html_source = mbase.fetchUrl(page_url, UA.ChromeDestop)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find html_source")
  end
  local info = videoinfo:new()
  info:parseDeskTopSource(html_source)
  if not mbase.isStringEmpty(info.vrsAlbumId) and not mbase.isStringEmpty(info.vrsTvId) then
    self:parseByVideoInfo(info, res)
  end
  if res:isDataEmpty() then
    perr.throwErr(ER.kInvalidJsonContent, "can not find ts url")
  end
  return res:toJSON()
end

--通过videoinfo解析地址
function QiyiParser:parseByVideoInfo(info, res)
  --api地址
  local apiUrl = self:buildApiRequest(info)
  --请求header
  local headers = QiyiSecurity:getSignedHeader()
  --请求结果
  local apiResult = mbase.fetchUrl(apiUrl, nil, nil, nil, headers)
  if mbase.isStringEmpty(apiResult) then
    perr.throwErr(ER.kJsonParseFailed, "api result empty " .. apiUrl)
  end
  local ok, jsonResult = pcall(cjson.decode, apiResult)
  if not ok then
    perr.throwErr(ER.kJsonParseFailed, "parse json err")
  end
  if jsonResult.tv ~= nil then
    local i_res = jsonResult.tv["0"]
    if i_res == nil then
      perr.throwErr(ER.kJsonParseFailed, "tv 0 nil")
    end
    ts_res = i_res.ts_res
    if #ts_res > 0 then
      for i = 1, #ts_res do
        local ts_item = ts_res[i]
        if ts_item ~= nil then
          local videoUrl = ts_item._tsurl
          local t = ts_item.t
          if not mbase.isStringEmpty(videoUrl) then
            if t == "TS1" then
              res:add(VD.SD, videoUrl)
            end
            if t == "TS2" then
              res:add(VD.HD, videoUrl)
            end
            if t == "TS3" then
              res:add(VD.HD2, videoUrl)
            end
            if t == "TS5" then
              res:add(VD._1080P, videoUrl)
            end
          end
        end
      end
    end
  end
end
--创建请求参数
function QiyiParser:buildApiRequest(info)
  local cts = math.ceil(os.time() / 1000)
  math.randomseed(os.time())
  local its = cts - math.random(100) - 4000
  local many_id = info.vrsAlbumId .. "_" .. info.vrsTvId .. "_"
  local sb = mbase.StringBuilder:new("http://iface2.iqiyi.com/php/xyz/entry/nebula.php")
  sb:append("?key=" .. self.QiyiSecurity.EXPORT_KEY)
  sb:append("&version=5.3.1&os=4.4.4&ua=MI+PAD&network=1&resolution=2048*1536")
  sb:append("&openudid="):append(kOpenUDID)
  sb:append("&ppid=")
  sb:append("&uniqid="):append(kUUID)
  sb:append("&device_id=null&cpu=2218500")
  sb:append("&idfv="):append(kIDFV)
  sb:append("&platform=GPad")
  sb:append("&block="):append(info.epiNum)
  sb:append("&w=1&compat=1&other=1&v5=1&ad_str=1")
  sb:append("&many_id="):append(many_id)
  sb:append("&user_res=0&ad=2&js=1&vs=0&vt=0&xbm=0&x=0&y=6&z=0")
  sb:append("&cts="):append(cts)
  sb:append("&lts=0&wts=128%2C4%2C8%2C16&wtsh=128%2C4%2C8%2C16")
  sb:append("its=").append(its)
  sb:append("&v_m=2.3_006")
  return tostring(sb)
end
return QiyiParser
