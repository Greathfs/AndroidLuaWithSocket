local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local cjson2 = cjson.new()
local VD = mbase.VD
local perr = require("perr")
local ER = perr.ER
local remoteCache = require("remote_cache")
local letvParser = require("letv")
local cloudParser = mbase:new()
cloudParser.domain = {
  "cloud.letv.com"
}
function cloudParser:getVInfoKey(url)
  local md5Str = mbase.getMD5(url)
  return "LetvCloudParser_" .. md5Str .. "_vinfo"
end
function cloudParser:getVideoInfo(url)
  local k = self:getVInfoKey(url)
  local res = remoteCache:getKV(k)
  if mbase.isStringEmpty(res) then
    perr.throwErr(ER.kHtmlContentError, "can not find video info")
  end
  local vinfo = cjson2.decode(res)
  if vinfo == nil then
    perr.throwErr(ER.kHtmlContentError, "can not find video info")
  end
  return vinfo
end
function cloudParser:parseMp4(vinfo, result)
  perr.throwErr(ER.kJavaException, "parseMp4 not implement in lua")
end
function cloudParser:parse(input)
  local hds = {
    ["350"] = VD.SD,
    ["1000"] = VD.HD,
    ["1300"] = VD.HD2,
    ["720p"] = VD._720P,
    ["1080p"] = VD._1080P
  }
  local result = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local vinfo = self:getVideoInfo(page_url)
  if vinfo.v_code == nil and string.find("[flv]?[mp4]?", vinfo.extname) ~= nil then
    self:parseMp4(vinfo, result)
  elseif tonumber(vinfo.playstatus) == 0 then
    local m3u8Url = mbase.base64Decode(vinfo.m3u8_url)
    if not mbase.isStringEmpty(m3u8Url) then
      result:add(VD.HD2, m3u8Url)
    end
  elseif tonumber(vinfo.playstatus) == 1 then
    local _, st = string.find(vinfo.v_code, "<!%[CDATA%[")
    local et = string.find(vinfo.v_code, "%]%]>")
    if st ~= nil and et ~= nil then
      local jsonStr = string.sub(vinfo.v_code, st + 1, et - 1)
      local jsonData = cjson2.decode(jsonStr)
      if jsonData.dispatch ~= nil then
        for k, v in pairs(hds) do
          if jsonData.dispatch[k] ~= nil then
            local url = jsonData.dispatch[k][1]
            if not mbase.isStringEmpty(url) then
              local videoUrl = letvParser.parseLetvUrl(url .. "&ctv=pc&m3v=1&termid=1&format=1&hwtype=un&ostype=Linux&tag=letv&sign=letv&expect=3&tn=0.6908448720350862&pay=0&rateid=1300")
              if not mbase.isStringEmpty(videoUrl) then
                result:add(v, videoUrl)
              end
            end
          end
        end
      end
    end
  end
  if result:isDataEmpty() then
    perr.throwErr(ER.kHtmlContentError, "result is empty")
  end
  return result:toJSON()
end
return cloudParser
