function getPlayerSourceType()
  return {
    AOM: "AOM",
    TOS: "TOS",
    SINTEL: "SINTEL",
    SINGLE_SPEED: "SINGLE_SPEED",
    CORRUPT_BEGINNING: "CORRUPT_BEGINNING"
  }
end function

function getPlayerSourceTypeForContentNode()
  return {
    AOM: "AOM",
    SINTEL: "SINTEL",
    PLAYLIST: "PLAYLIST"
  }
end function

function getBaseUrl()
  ' return "http://192.168.0.150:8080/content" ' for testing with proxy
  return "https://bitmovin-a.akamaihd.net/content"
end function

function getSourceConfig(sourceType)
  PlayerSourceType = getPlayerSourceType()
  content = CreateObject("roAssociativeArray")

  if sourceType = PlayerSourceType.AOM
    content = {
      hls: getBaseUrl() + "/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8",
      title: "Art of Motion"
    }
  else if sourceType = PlayerSourceType.TOS
    content = {
      dash: "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd",
      title: "Tears of Steel",
      drm: {
        widevine: {
          LA_URL: "https://proxy.uat.widevine.com/proxy?video_id=HDCP_V1&provider=widevine_test"
        }
      }
    }
  else if sourceType = PlayerSourceType.SINTEL
    content = {
      hls: getBaseUrl() + "/sintel/hls/playlist.m3u8",
      title: "Sintel"
    }
  else if sourceType = PlayerSourceType.SINGLE_SPEED
    content = {
       dash: getBaseUrl() + "/analytics-teststreams/redbull-parkour/singlespeed.mpd",
      title: "Art of Motion - SingleSpeed"
    }
  else if sourceType = PlayerSourceType.CORRUPT_BEGINNING
    content = {
      dash: getBaseUrl() + "/analytics-teststreams/redbull-parkour/corrupted_first_segment.mpd",
      title: "redbull-parkour"
    }
  end if

  return content
end function

function getPlayerSourceAsContentNode(sourceType)
  PlayerSourceType = getPlayerSourceTypeForContentNode()
  content = CreateObject("roSGNode", "ContentNode")

  if sourceType = PlayerSourceType.AOM
    content.url = getBaseUrl() + "/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
    content.title = "Art of motion"
    content.streamformat = "hls"
  else if sourceType = PlayerSourceType.SINTEL
    content.url = getBaseUrl() + "/sintel/hls/playlist.m3u8"
    content.streamFormat = "hls"
    content.title = "Sintel"
  else if sourceType = PlayerSourceType.PLAYLIST
    firstVideo = CreateObject("roSGNode", "ContentNode")
    firstVideo.url = getBaseUrl() + "/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
    firstVideo.streamFormat = "hls"
    firstVideo.title = "Art of Motion"

    secondVideo = CreateObject("roSGNode", "ContentNode")
    secondVideo.url = getBaseUrl() + "/sintel/hls/playlist.m3u8"
    secondVideo.streamFormat = "hls"
    secondVideo.title = "Sintel"

    content.AppendChild(firstVideo)
    content.AppendChild(secondVideo)
  end if

  return content
end function
