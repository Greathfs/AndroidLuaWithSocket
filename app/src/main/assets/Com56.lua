local mres = require("mres")
local mbase = require("mbase")
local cjson = require("cjson")
local cjson2 = cjson.new()
local ER = mres.ER
local Com56Parser = mbase:new()
Com56Parser.domain = {"56.com"}
function Com56Parser:parse(input)
  local result = mres:new()
  local page_url = input.url
  if page_url == nil then
    return
  end
  local _, _, vid = string.find(page_url, "v_([^\\\\.]+)")
  if vid == nil then
    _, _, vid = string.find(page_url, "vid%-([^\\\\.]+)")
  end
  if vid == nil then
    result:setCode(ER.kHtmlContentError, "can not find vid")
    return result:toJSON()
  end
  local getTime = os.time()
  local jsonUrl = string.format("http://vxml.56.com/h5json/%s/?t=%s&src=m&callback=jsonp_dfInfo", vid, getTime)
  local jsonCallback = self.fetchUrl(jsonUrl)
  if jsonCallback == nil then
    result:setCode(1, ER.kNetworkIOFailed)
    return result:toJSON()
  end
  local json_src = self.getJSONP(jsonCallback)
  if json_src == nil then
    result:setCode(1, ER.kInvalidJsonContent)
    return result:toJSON()
  end
  local size = #json_src.df
  for i = 1, size do
    local temp_url = json_src.df[i].url
    if json_src.df[i].type == "qvga" then
      result:add(self.VD.SD, tostring(temp_url))
    end
    if json_src.df[i].type == "vga" then
      result:add(self.VD.HD, tostring(temp_url))
    end
    if json_src.df[i].type == "wvga" then
      result:add(self.VD.HD2, tostring(temp_url))
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
    return result:toJSON()
  end
  return result:toJSON()
end
return Com56Parser
