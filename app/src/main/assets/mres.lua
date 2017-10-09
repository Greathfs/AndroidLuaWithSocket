local cjson = require("json")
local errc = {
  kSuccess = 0,
  kAsyncRequestFailed = 1,
  kAsyncRequestObjectCastError = 2,
  kNetworkIOFailed = 4,
  kInvalidURLFormat = 5,
  kJavaException = 6,
  kUnsupportedParser = 7,
  kHtmlContentError = 8,
  kJsonParseFailed = 9,
  kInvalidJsonContent = 10,
  kM3u8ContentZero = 11,
  kMaxParserThread = 12,
  kZeroContent = 13,
  kCanNotFindVideoParser = 14,
  kUnknownError = 65535
}
local mres = {}
mres.__index = mres
mres.ER = errc
function mres:new(param)
  local o = {}
  setmetatable(o, self)
  o.data = {}
  o.data.code = errc.kSuccess
  o.data.msg = "ok"
  if param ~= nil then
    if param.code ~= nil then
      o.data.code = param.code
    end
    if param.msg ~= nil then
      o.data.msg = param.msg
    end
  end
  return o
end
function mres:add(v, u)
  if self.data.list == nil then
    self.data.list = {}
  end
  local flag = true
  local test_repeat = self.data.list
  for i = 1, #test_repeat do
    if test_repeat[i].vd == v and test_repeat[i].url ~= nil then
      flag = false
      break
    end
  end
  if flag ~= false then
    table.insert(self.data.list, {vd = v, url = u})
  end
  return self.list
end
function mres:setCode(code, msg)
  if type(code) == "number" then
    self.data.code = code
  end
  if msg ~= nil then
    self.data.msg = tostring(msg)
  end
  return self.data
end
function mres:isDataEmpty()
  if self.data and self.data.list and table.getn(self.data.list) > 0 then
    return false
  else
    return true
  end
end
function mres:toJSON()
  if self.data ~= nil then
    return cjson.encode(self.data)
  end
  error("can not find data for mres")
end
return mres
