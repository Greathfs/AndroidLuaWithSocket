local mbase = require("mbase")
local mres = require("mres")
local cjson = require("cjson")
local VD = mbase.VD
local ER = mres.ER
local perr = require("perr")
local letvParser = mbase:new()
letvParser.domain = {"letv.com"}
local function getTime()
  local src = mbase.fetchUrl("http://api.letv.com/time")
  local flag, src_t = pcall(cjson.decode, src)
  local stime = src_t.stime
  return stime
end
local function parseLetvUrl(url)
  local json_string = mbase.fetchUrl(url)
  local video_url = ""
  local flag, json_t = pcall(cjson.decode, json_string)
  if flag ~= true then
    perr.throwErr(ER.kJsonParseFailed, "json_string parse failed")
  end
  local vlist = {}
  local array = json_t.nodelist
  if array ~= nil and #array > 0 then
    for i, node in ipairs(array) do
      local video_url = node.location
      if not mbase.isStringEmpty(video_url) then
        table.insert(vlist, video_url)
      end
    end
  else
    video_url = json_t.location
    if not mbase.isStringEmpty(video_url) then
      table.insert(vlist, videoUrl)
    end
  end
  if #vlist == 0 then
    perr.throwErr(ER.kInvalidJsonContent, url)
  end
  math.randomseed(os.time())
  math.random()
  video_url = vlist[math.random(1, #vlist)]
  return video_url
end
local function parseLetvJson(video_info, result)
  local time = getTime(result)
  if time == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get time")
  end
  local arrayOfObject = {}
  arrayOfObject[1] = video_info.mmsId
  arrayOfObject[2] = "0"
  arrayOfObject[3] = "ios"
  arrayOfObject[4] = "010410013"
  arrayOfObject[5] = "2.0"
  arrayOfObject[6] = tostring(time)
  local md5_string = video_info.mmsId .. "," .. time .. "," .. "bh65OzqYYYmHRQ"
  arrayOfObject[7] = mbase.getMD5(md5_string)
  if arrayOfObject[7] == nil then
    perr.throwErr(ER.kHtmlContentError, "cannot find VideoFileKey")
  end
  arrayOfObject[8] = video_info.vid
  local json_url = string.format("http://dynamic.meizi.app.m.letv.com/android/dynamic.php?mmsid=%s&playid=%s&tss=%s&pcode=%s&version=%s&tm=%s&key=%s&vid=%s&ctl=videofile&mod=minfo&act=index", arrayOfObject[1], arrayOfObject[2], arrayOfObject[3], arrayOfObject[4], arrayOfObject[5], arrayOfObject[6], arrayOfObject[7], arrayOfObject[8])
  local json_source = mbase.fetchUrl(json_url)
  if json_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get json_source")
  end
  local flag, json_source_t = pcall(cjson.decode, json_source)
  if flag ~= true then
    perr.throwErr(ER.kJsonParseFailed, "json_source_ parse failed")
  end
  if json_source_t.body ~= nil then
    if json_source_t.body.videofile ~= nil then
      local infos = json_source_t.body.videofile.infos
      if infos ~= nil then
        if infos.mp4_1300 ~= nil then
          local node1300 = infos.mp4_1300
          if node1300 ~= nil then
            local url = node1300.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD.HD2, video_url)
              end
            end
          end
        end
        if infos.mp4_1000 ~= nil then
          local node1000 = infos.mp4_1000
          if node1000 ~= nil then
            local url = node1000.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD.HD, video_url)
              end
            end
          end
        end
        if infos.mp4_350 ~= nil then
          local node350 = infos.mp4_350
          if node350 ~= nil then
            local url = node350.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD.SD, video_url)
              end
            end
          end
        end
        if infos.mp4_720p ~= nil then
          local node720 = infos.mp4_720
          if node720 ~= nil then
            local url = node720.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD._720P, video_url)
              end
            end
          end
        end
        if infos.mp4_1080p ~= nil then
          local node1080 = infos.mp4_1080p
          if node1080 ~= nil then
            local url = node1080.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD._1080P, video_url)
              end
            end
          end
        elseif infos.mp4_1080p6m_db ~= nil then
          local node1080 = infos.mp4_1080p6m_db
          if node1080 ~= nil then
            local url = node1080.mainUrl
            if url ~= nil then
              local video_url = parseLetvUrl(url)
              if video_url ~= nil then
                result:add(VD._1080P, video_url)
              end
            end
          end
        end
      else
        perr.throwErr(ER.kHtmlContentError, "can not find infos")
      end
    else
      perr.throwErr(ER.kHtmlContentError, "can not find videofile in body")
    end
  else
    perr.throwErr(ER.kHtmlContentError, "can not find body in json_source")
  end
end
local function getVideoInfo(video_info, result, page_url)
  local html_source = mbase.fetchUrl(page_url)
  if html_source == nil then
    perr.throwErr(ER.kHtmlContentError, "can not get html_source")
  end
  local starts, ends, vid
  starts, ends, vid = string.find(page_url, "ptv/vplay/(%d+).html")
  if vid == nil then
    starts, ends, vid = string.find(html_source, "vid[\"'][:=][\"'](%d+)")
  end
  if vid ~= nil then
    video_info.vid = vid
  else
    perr.throwErr(ER.kHtmlContentError, "can not find vid")
  end
  local _, _, mmsId = string.find(html_source, "mmsid['\"]?[%s]*:[%s]*['\"]?([%d]+)")
  if mmsId ~= nil then
    video_info.mmsId = mmsId
  else
    perr.throwErr(ER.kHtmlContentError, "can not find mmsid")
  end
end
function letvParser:parse(input)
  local result = mres:new()
  local video_info = {
    vid = "",
    mmsId = "",
    pid = "",
    isVip = false
  }
  local hds = {
    ["350"] = "SD",
    ["1000"] = "HD",
    ["1300"] = "HD2",
    ["720p"] = "720P",
    ["1080p"] = "1080P"
  }
  local page_url = input.url
  if page_url == nil or string.len(page_url) == 0 then
    perr.throwErr(ER.kHtmlContentError, "can not get page_url")
  end
  getVideoInfo(video_info, result, page_url)
  if video_info.vid == "" or video_info.mmsId == "" then
    perr.throwErr(ER.kHtmlContentError, "can not get vid or mmsid")
  end
  local time = os.time()
  local videoId = video_info.vid .. "itv12345678!@#$%^&*"
  local md5_string = string.format("timestamp=%d&vrsVideoInfoId=%s", time, videoId)
  local sign = mbase.getMD5(md5_string)
  if mbase.isStringEmpty(sign) then
    perr.throwErr(ER.kHtmlContentError, "can not get sign")
  end
  for k, v in pairs(hds) do
    local stream = k
    local paramters = {}
    paramters[1] = video_info.vid
    paramters[2] = tostring(time)
    paramters[3] = sign
    paramters[4] = stream
    local json_url = string.format("http://api.itv.letv.com/iptv/api/v2/video/getPlayUrl.json?vrsVideoInfoId=%s&timestamp=%s&sig=%s&stream=%s&username=&loginTime=&expectDispatcherUrl=false&expectTS=true&channelCode=&pricePackageType=9&broadcastId=&terminalBrand=letv&terminalSeries=AMLOGIC8726MX_C1S_UI_2&broadcastId=0&client=android", paramters[1], paramters[2], paramters[3], paramters[4])
    local json_result = mbase.fetchUrl(json_url)
    if json_result == nil then
      perr.throwErr(ER.kHtmlContentError, "can not get json_result")
    end
    local flag, json_t = pcall(cjson.decode, json_result)
    if flag ~= true then
      perr.throwErr(ER.kJsonParseFailed, "cannot get json_t")
    end
    if json_t.resultStatus ~= 1 then
    else
      local video_url = json_t.data.playUrl
      if video_url ~= nil then
        video_url = parseLetvUrl(video_url .. "&ctv=pc&m3v=1&termid=1&format=1&hwtype=un&ostype=Linux&tag=letv&sign=letv&expect=3&tn=0.6908448720350862&pay=0&rateid=1300")
        if video_url ~= "" then
          if k == "350" then
            result:add(self.VD.SD, video_url)
          elseif k == "1000" then
            result:add(self.VD.HD, video_url)
          elseif k == "1300" then
            result:add(self.VD.HD2, video_url)
          elseif k == "720P" then
            result:add(self.VD._720P, video_url)
          elseif k == "1080P" then
            result:add(self.VD._1080P, video_url)
          end
        else
          perr.throwErr(ER.kHtmlCntentError, "can not get video_url")
        end
      end
    end
  end
  if result:isDataEmpty() then
    parseLetvJson(video_info, result)
  end
  if result:isDataEmpty() then
    perr.throwErr(ER.kHtmlContentError, "result is empty")
  end
  return result:toJSON()
end
letvParser.parseLetvUrl = parseLetvUrl
return letvParser
