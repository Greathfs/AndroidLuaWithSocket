
local cjson = require("json")
local mbase = require("mbase")
local perr = require("perr")
local ku6 = require("ku6")
local yyt = require("yyt")
local wasu = require("wasu")
local mtime = require("mtime")
local game17173 = require("17173")
local Com56 = require("Com56")
local m1905 = require("m1905")
local NetEase = require("NetEase")
local hunantv = require("hunantv")
local cntv = require("cntv")
local qq = require("qq")
local youku = require("youku")
local sohu = require("sohu_new")
local letv = require("letv")
local pps = require("pps")
local zjtv = require("zjtv")
local baiduSearch = require("baidu")
local tudou = require("tudou")
local molitv = require("molitv")
local letvCloud = require("letv_cloud")
gParseList = {
  ku6,
  yyt,
  wasu,
  mtime,
  game17173,
  Com56,
  m1905,
  NetEase,
  hunantv,
  cntv,
  qq,
  youku,
  sohu,
  letvCloud,
  letv,
  pps,
  zjtv,
  baiduSearch,
  tudou,
  molitv
}
local function findParser(url)
  local domain = mbase.getDomain(url)
  for i, v in ipairs(gParseList) do
    if v.domain ~= nil then
      for n, value in pairs(v.domain) do
        local s = string.find(domain, v.domain[n])
        if s ~= nil then
          return v
        end
      end
    end
  end
end
local cur_parse

function can_parse(input)
  local jinput = cjson.decode(input)
--[[
  local url = jinput.url
  if url == nil then
    return false
  end
  local parser = findParser(url)
  return parser ~= nil
--]]

  return jinput
end

function unsafeParseVideo(input)
  local jinput = cjson.decode(input)
  local url = jinput.url
  local parser = findParser(url)
  if parser == nil then
    return "{\"code\":\"1\", \"msg\": \"can not find parse\"}"
  end
  if parser.parse ~= nil and type(parser.parse) == "function" then
    return parser:parse(jinput)
  end
  return ""
end
local function paserErrHandler(err)
  if type(err) == "table" and err.__class__ == perr.__class__ then
    return perr.parseError(err)
  else
    return "{\"code\":\"65535\", \"msg\":\"unkown\"}"
  end
end
function parse_video(input)
  local ok, result = xpcall(function()
    return unsafeParseVideo(input)
  end, paserErrHandler)
  if ok then
    if result ~= nil and string.len(result) > 0 then
      return result
    else
      return "{\"code\":\"65535\", \"msg\":\"unkown\"}"
    end
  else
    return result
  end
end
return {can_parse = can_parse, parse_video = parse_video}

