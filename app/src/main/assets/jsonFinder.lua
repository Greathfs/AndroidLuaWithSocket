local mbase = require("mbase")
local cjson = require("cjson")
local iconv = require("iconv")
local bit = require("bit")
local JSONFinder = {
  __class__ = "JSONFinder",
  __desc__ = "help to find json string in js file"
}
JSONFinder_MT = {__index = JSONFinder}
function JSONFinder:new()
  local t = {}
  setmetatable(t, BaiduSpecialSearch_MT)
  return t
end
function JSONFinder.format(ct)
  local content = string.gsub(ct, "\r\n", "")
  content = string.gsub(content, "\n", "")
  content = string.gsub(content, "\\\"", "")
  content = string.gsub(content, "\\/", "/")
  return content
end
function JSONFinder.unicode_to_utf8(convertStr)
  if type(convertStr) ~= "string" then
    return convertStr
  end
  local resultStr = ""
  local i = 1
  while true do
    local num1 = string.byte(convertStr, i)
    local unicode
    if num1 ~= nil and string.sub(convertStr, i, i + 1) == "\\u" then
      unicode = tonumber("0x" .. string.sub(convertStr, i + 2, i + 5))
      i = i + 6
    elseif num1 ~= nil then
      unicode = num1
      i = i + 1
    else
      break
    end
    if unicode <= 127 then
      resultStr = resultStr .. string.char(bit.band(unicode, 127))
    elseif unicode >= 128 and unicode <= 2047 then
      resultStr = resultStr .. string.char(bit.bor(192, bit.band(bit.rshift(unicode, 6), 31)))
      resultStr = resultStr .. string.char(bit.bor(128, bit.band(unicode, 63)))
    elseif unicode >= 2048 and unicode <= 65535 then
      resultStr = resultStr .. string.char(bit.bor(224, bit.band(bit.rshift(unicode, 12), 15)))
      resultStr = resultStr .. string.char(bit.bor(128, bit.band(bit.rshift(unicode, 6), 63)))
      resultStr = resultStr .. string.char(bit.bor(128, bit.band(unicode, 63)))
    end
  end
  resultStr = resultStr .. "\000"
  return resultStr
end
function JSONFinder.findContent(content, st, ed)
  local _, s = string.find(content, st)
  if s ~= nil then
    local tmp = string.sub(content, s + 1)
    local e, _ = string.find(tmp, ed)
    if e ~= nil then
      return s + 1, s + e - 1, string.sub(tmp, 1, e - 1)
    end
  end
end
return JSONFinder
