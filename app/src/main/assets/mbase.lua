local ltn12 = require("ltn12")
local http = require("http")
local cjson = require("json")
local b64 = require("base64")
local mbase = {}
mbase.__index = mbase
local domain_p = "https?://([^/]+)/"
local UUID_table = {
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F"
}
mbase.VERSION = 201707260
mbase.VD = {
  None = 0,
  SD = 1,
  HD = 2,
  HD2 = 3,
  BluRay = 4,
  _720P = 5,
  _1080P = 6,
  _4K = 7
}
local UA = {
  IPAD = "Mozilla/5.0 (iPad; CPU OS 7_1_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D201 Safari/9537.53",
  ChromeDestop = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36",
  MiBOX = "Dalvik/1.6.0 (Linux; U; Android 4.2.2; MiBOX2 Build/CADEV)"
}
mbase.UA = UA
function mbase.getDomain(url)
  local s, e, domain = string.find(url, domain_p)
  if domain ~= nil then
    return domain
  end
  return url
end
function mbase.fetchUrl(url, userAgent, sessioncookie, postData, extra_headers, proxy)
  local t = {}
  local headers = {}
  local lUseragent = UA.MiBOX
  local url = url
  headers.Cookie = sessioncookie
  if userAgent ~= nil then
    lUseragent = userAgent
  end
  if extra_headers ~= nil then
    for k, v in pairs(extra_headers) do
      headers[k] = v
    end
  end
  local r, c, h
  if postData == nil then
    local requestData = {
      url = url,
      sink = ltn12.sink.table(t),
      headers = headers,
      method = "GET",
      timeout = 5,
      useragent = lUseragent
    }
    if proxy ~= nil then
      requestData.proxy = proxy
    end
    r, c, h = http.request(requestData)
  else
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["Content-Length"] = string.len(postData)
    local requestData = {
      url = url,
      source = ltn12.source.string(postData),
      sink = ltn12.sink.table(t),
      method = "POST",
      headers = headers,
      timeout = 5,
      useragent = lUseragent
    }
    if proxy ~= nil then
      requestData.proxy = proxy
    end
    r, c, h = http.request(requestData, postData)
  end
  r = table.concat(t, "")
  local cookie, location
  if h then
    t = {}
    for k, v in pairs(h) do
      if k == "set-cookie" then
        v = string.gsub(v, "(expires=.-; )", "")
        v = v .. ", "
        for cookie in string.gmatch(v, "(.-), ") do
          cookie = string.match(cookie, "(.-);")
          table.insert(t, cookie)
        end
      end
      if k == "location" then
        location = v
      end
    end
    cookie = table.concat(t, "; ")
  else
    cookie = nil
  end
  return r, c, cookie, location
end
function mbase:new()
  local o = {}
  setmetatable(o, self)
  return o
end
function mbase.tohex(s)
  return (s:gsub(".", function(c)
    return string.format("%02x", string.byte(c))
  end))
end
function mbase.urlencodeComponent(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w ~ ! @ # $ & * ( ) _ + : ? - = ; ' , . / ])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end
function mbase.urlencode(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w ])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end
function mbase.urldecode(str)
  str = string.gsub(str, "+", " ")
  str = string.gsub(str, "%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
  str = string.gsub(str, "\r\n", "\n")
  return str
end
function mbase.getJSONP(s)
  local s_idx = s:find("{")
  local r_idx = s:reverse():find("}")
  if s_idx and r_idx then
    local e_idx = #s - r_idx + 1
    local ss = string.sub(s, s_idx, e_idx)
    local s, m = pcall(cjson.decode, ss)
    if s == true then
      return m
    end
  end
end
function mbase.getMD5(md5_string)
  local digest = crypto.digest
  local d = digest.new("md5")
  local md5_value = d:final(md5_string)
  d:reset(d)
  if md5_value ~= nil then
    return md5_value
  else
    return
  end
end
function mbase.split(str, sep)
  local sep, fields = sep or "\t", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(str, pattern, function(c)
    fields[#fields + 1] = c
  end)
  return fields
end
function mbase.trim(s)
  if mbase.isStringEmpty(s) then
    return s
  end
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
function mbase.generateUUID()
  local res_UUID = ""
  math.randomseed(os.time())
  math.random()
  for i = 1, 32 do
    res_UUID = res_UUID .. UUID_table[math.random(1, 16)]
  end
  return res_UUID
end
function mbase.base64Decode(str)
  return b64.from_base64(str)
end
function mbase.isStringEmpty(str)
  return str == nil or string.len(str) == 0
end
function mbase.generateHex(count)
  local res = ""
  math.randomseed(os.time())
  math.random()
  for i = 1, count do
    res = res .. UUID_table[math.random(1, 16)]
  end
  return res
end
function mbase.getUrlQuery(data)
  local _, _, query = string.find(data, "%?([%s%S]+)")
  if not mbase.isStringEmpty(query) then
    data = query
  end
  params = mbase.split(data, "&")
  local res = {}
  for i = 1, #params do
    local key = ""
    local val = ""
    local temp = mbase.split(params[i], "=")
    key = temp[1]
    val = temp[2]
    res[key] = mbase.urldecode(val)
  end
  return res
end
function mbase:genRandomMac()
  local kHexString = {
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
  }
  local format = "64:09:80:%s%s:%s%s:%s%s"
  local random = math.randomseed(os.time())
  return string.format(format, kHexString[math.random(#kHexString)], kHexString[math.random(#kHexString)], kHexString[math.random(#kHexString)], kHexString[math.random(#kHexString)], kHexString[math.random(#kHexString)], kHexString[math.random(#kHexString)])
end
local StringBuilder = {
  __class__ = "StringBuilder"
}
StringBuilder_MT = {
  __index = StringBuilder,
  __tostring = function(t)
    return table.concat(t.buff_t)
  end
}
function StringBuilder:new(str)
  local t = {}
  setmetatable(t, StringBuilder_MT)
  t.buff_t = {}
  t:append(str)
  return t
end
function StringBuilder:append(str)
  if str ~= nil then
    if type(str) ~= "string" then
      str = tostring(str)
    end
    table.insert(self.buff_t, str)
  end
  return self
end
mbase.StringBuilder = StringBuilder
return mbase
