local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local md5 = require("md5")
local cjson2 = cjson.new()
local ER = mres.ER
local VD = mbase.VD
local kRetryCount = 5
local m1905Parser = mbase:new()
m1905Parser.domain = {"m1905.com", "1905.com"}
local table = {
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
local function generareUUID()
  local res_UUID = ""
  math.randomseed(os.time())
  math.random()
  for i = 1, 32 do
    if i == 9 then
      res_UUID = res_UUID .. "-" .. table[math.random(1, 16)]
    elseif i == 13 then
      res_UUID = res_UUID .. "-" .. table[math.random(1, 16)]
    elseif i == 17 then
      res_UUID = res_UUID .. "-" .. table[math.random(1, 16)]
    elseif i == 21 then
      res_UUID = res_UUID .. "-" .. table[math.random(1, 16)]
    else
      res_UUID = res_UUID .. table[math.random(1, 16)]
    end
  end
  return res_UUID
end
local buildHeader = function()
  local header = {}
  header.pid = "1"
  header.did = "000000000000000"
  header.ver = "100/32/2014062701"
  header.key = "e4bf92b3372896b8f0d1dc1e9ede99b8"
  return header
end
local function parseAppJson(page_url, vid, result)
  local result_UUID = generareUUID()
  local apiUrl = string.format("http://mapps.m1905.cn/Vod/vodDetail?id=%s&v=%s", vid, result_UUID)
  local headers = buildHeader()
  local jsonResult = mbase.fetchUrl(apiUrl, nil, nil, nil, headers)
  local s, jsonResult_t = pcall(cjson.decode, jsonResult)
  if s == false then
    result:setCode(ER.kInvalidJsonContent, "jsonResult decode Failed")
    return
  end
  for k, v in pairs(jsonResult_t.data) do
    if k == "playurl" then
      result:add(VD.SD, v)
    end
    if k == "sdUrl" then
      result:add(VD.HD2, v)
    end
    if k == "hdUrl" then
      result:add(VD.HD, v)
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
    return
  end
  return result:toJSON()
end
local paseJsonWithRetry
function paseJsonWithRetry(page_url, vid, result, retry)
  local s, m = pcall(parseAppJson, page_url, vid, result)
  if s == false then
    retry = retry + 1
    if retry < kRetryCount then
      paseJsonWithRetry(page_url, vid, result, retry)
    end
  end
end
function m1905Parser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil then
    return
  end
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    result:setCode(ER.kHtmlContentError, "Html_Source is empty")
    return result:toJSON()
  end
  local s, e, vid = string.find(html_source, "['\"]*vid['\"]*[%s]*:[%s]*['\"]?([0-9]+)['\"]?")
  if vid ~= nil then
    paseJsonWithRetry(page_url, vid, result, 0)
  else
    result:setCode(ER.kHtmlContentError, "can not find vid")
    return result:toJSON()
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
  end
  return result:toJSON()
end
return m1905Parser
