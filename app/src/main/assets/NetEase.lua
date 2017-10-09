local cjson = require("cjson")
local mres = require("mres")
local mbase = require("mbase")
local UA = mbase.UA
local ER = mres.ER
local NetEaseParser = mbase:new()
local XMLLable = {
  flvUrl = {"<flvUrl>", "</flvUrl>"},
  hdUrl = {"<hdUrl>", "</hdUrl>"},
  shdUrl = {"<shdUrl>", "</shdUrl>"}
}
NetEaseParser.domain = {"163.com", "126.com"}
local findXMLSource = function(startLable, endLable, XMLSource)
  local _, starts = string.find(XMLSource, startLable)
  local ends, _ = string.find(XMLSource, endLable)
  local subXML = string.sub(XMLSource, starts + 1, ends - 1)
  local finalResult = string.sub(subXML, string.find(subXML, "<flv>") + 5, string.find(subXML, "</flv>") - 1)
  return finalResult
end
function NetEaseParser:parse(input)
  local result = mres:new()
  local SDUrl = ""
  local HDUrl = ""
  local HD2Url = ""
  local info = {}
  local XMLSource = ""
  local XMLUrl = ""
  local page_url = input.url
  if page_url == nil then
    return
  end
  function getVideoInfo(url, result)
    local videoinfo = {}
    local _, _, vid = string.find(url, "([^/.]*)%.html")
    if vid == nil then
      local _, _, vid_temp = string.find(url, "#([^/.]*)")
      vid = string.sub(vid_temp, 1, 9)
    end
    if vid == nil then
      result:setCode(ER.kHtmlContentError, "can not find vid")
      return result:toJSON()
    end
    local htmlSource = mbase.fetchUrl(url, UA.ChromeDestop)
    if htmlSource == nil then
      result:setCode(ER.kHtmlContentError, "HtmlSource is empty")
      return result:toJSON()
    end
    local _, _, appsrc = string.find(htmlSource, "appsrc[%s]*:[\\%s]*[']?([^']+)")
    local _, _, topicid = string.find(htmlSource, "[\"]?topicid[\"]?[%s]*:[%s]*[\"]?([^\"]+)")
    if topicid == nil then
      topicid = "0005"
    end
    if appsrc ~= nil then
      videoinfo.appsrc = appsrc
      return videoinfo
    elseif vid ~= nil then
      videoinfo.vid = vid
      videoinfo.topicid = topicid
      return videoinfo
    end
  end
  local s, info = pcall(getVideoInfo, page_url, result)
  if s ~= true then
    result:setCode(ER.kHtmlContentError, "can not find video info")
    return result:toJSON()
  end
  if info.appsrc ~= nil then
    result:add(self.VD.SD, info.appsrc)
  else
    local len = string.len(info.vid)
    XMLUrl = string.format("http://xml.ws.126.net/video/%s/%s/%s_%s.xml", string.sub(info.vid, len - 1, len - 1), string.sub(info.vid, len, len), info.topicid, info.vid)
    XMLSource = mbase.fetchUrl(XMLUrl, UA.ChromeDestop)
    if XMLSource == nil then
      result:setCode(ER.kHtmlContentError, "XMLSource is empty")
      return result:toJSON()
    end
    for k, v in pairs(XMLLable) do
      if k == "flvUrl" and string.find(XMLSource, "flvUrl") then
        local res, m = pcall(findXMLSource, v[1], v[2], XMLSource)
        if res ~= true then
          result:setCode(ER.kHtmlContentError, "XML parse filed")
          return result:toJSON()
        end
        result:add(self.VD.SD, m)
      end
      if k == "hdUrl" and string.find(XMLSource, "hdUrl") then
        local res, m = pcall(findXMLSource, v[1], v[2], XMLSource)
        if res ~= true then
          result:setCode(ER.kHtmlContentError, "XML parse filed")
          return result:toJSON()
        end
        result:add(self.VD.HD, m)
      end
      if k == "shdUrl" and string.find(XMLSource, "shdUrl") then
        local res, m = pcall(findXMLSource, v[1], v[2], XMLSource)
        if res ~= true then
          result:setCode(ER.kHtmlContentError, "XML parse filed")
          return result:toJSON()
        end
        result:add(self.VD.HD2, m)
      end
    end
  end
  if result:isDataEmpty() then
    result:setCode(ER.kInvalidJsonContent, "Result is null")
    return result:toJSON()
  end
  return result:toJSON()
end
return NetEaseParser
