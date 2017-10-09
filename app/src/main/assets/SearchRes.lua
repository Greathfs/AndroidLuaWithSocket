local cjson = require("cjson")
local cjson2 = cjson.new()
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
function mres:add(videoArea, videoInfo)
  if type(self.data.sr) == "nil" and videoArea == "sr" then
    self.data.sr = {}
  elseif type(self.data.sc) == "nil" and videoArea == "sc" then
    self.data.sc = {}
  elseif type(self.data.kw) == "nil" and videoArea == "kw" then
    self.data.kw = {}
  elseif type(self.total) == "nil" and videoArea == "total" then
    self.data.total = 0
  end
  if videoArea == "sr" then
    table.insert(self.data.sr, videoInfo)
  elseif videoArea == "sc" then
    table.insert(self.data.sc, videoInfo)
  elseif videoArea == "kw" then
    table.insert(self.data.kw, videoInfo)
  elseif videoArea == "total" then
    self.data.total = tonumber(videoInfo)
  end
  return self
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
  if self.data then
    if self.data.sr ~= nil then
      if next(self.data.sr) ~= nil then
        return false
      end
    elseif self.data.sc ~= nil then
      if next(self.data.sc) ~= nil then
        return false
      end
    elseif self.data.kw ~= nil and next(self.data.kw) ~= nil then
      return false
    end
  else
    return true
  end
end
function mres:toJSON()
  if self.data ~= nil then
    return cjson2.encode(self.data)
  end
  error("can not find data for mres")
end
return mres
