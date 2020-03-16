function getPlayerSourceType()
  return {
    AOM: "AOM",
    SINTEL: "SINTEL",
    SINGLE_SPEED: "SINGLE_SPEED"
  }
end function

function getBaseUrl()
  ' return "http://192.168.0.150:8080/content" ' for testing with proxy
  return "https://bitmovin-a.akamaihd.net/content"
end function

function getPlayerSource(sourceType)
  PlayerSourceType = getPlayerSourceType()
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