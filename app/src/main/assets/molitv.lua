local mres = require("mres")
local mbase = require("mbase")
local cjson = require("json")
local perr = require("perr")
local URL = require("socket.url")
local VD = mbase.VD
local ER = mres.ER
local molitvParser = mbase:new()
molitvParser.domain = {"molitv.cn"}
function molitvParser:parse(input)
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local urldata = URL.parse(page_url)
  if 0 < string.find(string.lower(urldata.path), "qrcode.aspx") then
    local query = mbase.getUrlQuery(urldata.query)
    local url = query.page
    if not mbase.isStringEmpty(url) then
      if can_parse == nil then
        require("main")
      end
      input.url = url
      local input_str = cjson.encode(input)
      if can_parse(input_str) then
        return parse_video(input_str)
      end
    end
  end
  perr.throwErr(ER.kHtmlContentError, "only support qrcode now")
end
return molitvParser
