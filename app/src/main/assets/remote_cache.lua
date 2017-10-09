local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local crypto = require("crypto")
local VD = mbase.VD
local ER = mres.ER
local remote_cache = {}
local kTimeApi = "http://api.tv.moliv.cn/moli20/moli-tv/Time.aspx"
local kAssistApi = "http://api.tv.moliv.cn/moli20/moli-tv/RemoteCache.aspx"
local kDefaultExpireSecond = 1800
local function getTime()
  local timeString = mbase.fetchUrl(kTimeApi)
  return tonumber(timeString) or os.time()
end
local function buildSetUrl(key, expired)
  local t = getTime()
  local sign = mbase.getMD5(t .. "_" .. key .. "_molitv!@#$%")
  local request = kAssistApi .. "?m=set" .. "&k=" .. key
  request = request .. "&t=" .. t .. "&s=" .. sign .. "&e=" .. expired .. "&pver=" .. mbase.VERSION
  return request
end
local function buildGetUrl(key)
  local t = getTime()
  return kAssistApi .. "?m=get" .. "&k=" .. mbase.urlencode(key) .. "&pver=" .. mbase.VERSION
end
function remote_cache:getKVWithoutDecrypt(key, source)
  local request = buildGetUrl(key)
  return mbase.fetchUrl(request)
end
function remote_cache:getKV(key, source)
  local resp = self:getKVWithoutDecrypt(key, source)
  if resp ~= nil and string.len(resp) > 0 then
    local base64_decode = mbase.base64Decode(resp)
    if base64_decode == nil then
      return
    end
    local res_str, e = crypto.decrypt("aes-128-ecb", base64_decode, "uageniustofindit", nil)
    return res_str
  end
end
function remote_cache:setKVWithoutEncrypt(key, val, expired, source)
end
function remote_cache:setKV(key, val, expired, source)
end
return remote_cache
