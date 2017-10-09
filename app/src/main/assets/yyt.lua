local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local mres = require("mres")
local ER = mres.ER
local crypto = require("crypto")
local yyt = mbase:new()
yyt.domain = {
  "yinyuetai.com"
}
yyt._DES = [[
 
  yinyuetai parser
  http://www.yinyuetai.com/
  http://v.yinyuetai.com/video/2172020
 ]]
local kApiUrlFormat = "http://www.yinyuetai.com/api/info/get-video-urls?json=true&videoId=%s&t=%s&v=%s&sc=%s"
function yyt:parse(input)
  local page_url = input.url
  if page_url == nil then
    return
  end
  local result = mres:new()
  local s, e, vid = string.find(page_url, "/([0-9]+)$")
  if vid == nil then
    result:setCode(ER.kInvalidURLFormat)
    return result
  end
  local t = os.time()
  local v = "html5"
  local crypt_input = vid .. "-" .. t .. "-" .. v
  local cyrpt_key = "yytcdn2b"
  local sc = encrypt(crypt_input, cyrpt_key)
  local apiUrl = string.format(kApiUrlFormat, vid, t, v, sc)
  local api_src = self.fetchUrl(apiUrl)
  local json_src = cjson2.decode(api_src)
  if json_src.error then
    local msg = json_src.message or ""
    result:setCode(ER.kInvalidJsonContent, msg)
    return result
  end
  if json_src.hdVideoUrl ~= nil then
    result:add(self.VD.HD, tostring(json_src.hdVideoUrl))
  end
  if json_src.hcVideoUrl ~= nil then
    result:add(self.VD.SD, tostring(json_src.hcVideoUrl))
  end
  if json_src.heVideoUrl ~= nil then
    result:add(self.VD.HD2, tostring(json_src.heVideoUrl))
  end
  return result:toJSON()
end
function encrypt(input, key)
  local cipher = "des-ecb"
  local iv = ""
  local res, e = assert(crypto.encrypt(cipher, input, key, iv))
  if res ~= nil then
    return yyt.tohex(res)
  end
  return nil
end
return yyt
