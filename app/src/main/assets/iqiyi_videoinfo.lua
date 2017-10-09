local perr = require("perr")
local mbase = require("mbase")
local ER = perr.ER
local QiyiVideoInfo = {
  __class__ = "QiyiVideoInfo",
  vrsAlbumId = "",
  vrsTvId = "",
  epiNum = "",
  cid = 0,
  defaultVideoId = ""
}
QiyiVideoInfo_MT = {__index = QiyiVideoInfo}
function QiyiVideoInfo:new()
  local t = {}
  setmetatable(t, QiyiVideoInfo_MT)
  return t
end
function QiyiVideoInfo:parseDeskTopSource(htmlSource)
  local target_source = ""
  local starts_str = "Q.PageInfo.playPageInfo"
  local end_str = "</script>"
  local _, starts = string.find(htmlSource, starts_str)
  local total_len = string.len(htmlSource)
  if starts ~= nil then
    target_source = string.sub(htmlSource, starts + 1, total_len)
    local _, ends = string.find(target_source, end_str)
    if ends ~= nil then
      target_source = string.sub(target_source, 0, ends)
    end
  else
    target_source = htmlSource
  end
  local _, _, albumid, tvid, cid, videoid
  _, _, albumid = string.find(target_source, "albumId\"?:%s*\"?([0-9]+)")
  _, _, tvid = string.find(target_source, "tvId\"?:%s*\"?([0-9]+)")
  _, _, cid = string.find(target_source, "cid\"?:%s*\"?([0-9]+)")
  _, _, videoid = string.find(target_source, "videoId\"?:([^,]+)")
  if videoid ~= nil then
    videoid = string.gsub(videoid, "\"", "")
  end
  if cid == nil then
    _, _, cid = string.find(target_source, "categoryId\"?:%s*\"?([0-9]+)")
  end
  if albumid == nil then
    _, _, albumid = string.find(htmlSource, "data%-player%-albumid=\"([0-9]+)\"")
  end
  if tvid == nil then
    _, _, tvid = string.find(htmlSource, "data%-player%-tvid=\"([0-9]+)\"")
  end
  if cid == nil then
    _, _, cid = string.find(htmlSource, "data%-player%-cid=\"([0-9]+)\"")
  end
  if videoid == nil then
    _, _, videoid = string.find(htmlSource, "data%-player%-videoid=\"?([^\"]+)")
  end
  if albumid ~= nil then
    self.vrsTvId = tvid
    self.vrsAlbumId = albumid
    self.cid = tonumber(mbase.trim(cid))
    _, _, self.epiNum = string.find(htmlSource, "episodeNumber\"%s*content=\"([0-9]+)\"")
    self.defaultVideoId = videoid
  else
    perr.throwErr(ER.kHtmlContentError, "albumid is null")
  end
end
return QiyiVideoInfo
