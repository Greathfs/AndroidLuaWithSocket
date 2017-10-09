local mbase = require("mbase")
local mres = require("mres")
local perr = require("perr")
local ER = mres.ER
local VD = mbase.VD
local UA = mbase.UA
local letvYun = require("letv_yunbase")
local yuntvParser = letvYun:new()
yuntvParser.domain = {
  "yuntv.letv.com"
}
function yuntvParser:parserObject(page_url)
  local _, _, uu = string.find(page_url, "uu[%s]*=[%s]*([%w]+)")
  local _, _, vu = string.find(page_url, "vu[%s]*=[%s]*([%w]+)")
  if uu ~= nil and vu ~= nil then
    local letvYunObject = {}
    letvYunObject.uu = uu
    letvYunObject.vu = vu
    return letvYunObject
  else
    perr.throwErr(ER.kInvalidJsonContent, "can not find uu or vu")
  end
end
function yuntvParser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  local letvYunObj = yuntvParser:parserObject(page_url)
  if letvYunObj == nil then
    perr.throwErr(ER.kJsonParseFailed, "can not find uu or uv for letvyun")
  end
  letvYun:getVideoUrl(letvYunObj, page_url, result)
  if result:isDataEmpty() then
    perr.throwErr(ER.kJavaException, "result is empty")
  end
  return result:toJSON()
end
return yuntvParser
