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
  kExpiredContent = 15,
  kUnknownError = 65535
}
local ParserException = {
  __class__ = "ParserException",
  code = errc.kSuccess,
  msg = ""
}
ParserException.ER = errc
ParserException_MT = {__index = ParserException}
function ParserException:new()
  local t = {}
  setmetatable(t, ParserException_MT)
  return t
end
function ParserException:throw(code, msg)
  self.code = code
  self.msg = msg
  error(self)
end
function ParserException.parseError(err)
  if type(err) == "table" then
    local success, res = pcall(cjson2.encode, err)
    if success then
      return res
    end
  end
end
function ParserException.throwErr(code, msg)
  local err = ParserException:new()
  err:throw(code, msg)
end
return ParserException
