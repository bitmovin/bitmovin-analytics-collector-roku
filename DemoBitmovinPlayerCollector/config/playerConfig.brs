function getPlayerConfig()
  return {
    playback: {
      autoplay: true,
      muted: true
    },
    adaptation: {
      preload: false
    },
    source: {
      dash: "https://bitmovin-a.akamaihd.net/content/analytics-teststreams/battlefield-60fps/mpds/battlefield-singlespeed.mpd",
      title: "Battlefield SingleSpeed"
    }
    ' source: {
    '   dash: "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd",
    '   title: "Tears of Steel",
    '   drm: {
    '     widevine: {
    '       LA_URL: "https://proxy.uat.widevine.com/proxy?video_id=HDCP_V1&provider=widevine_test"
    '     }
    '   }
    ' }
    ' source: {
    '   hls: "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
    '   title: "Sintel"
    ' }
  }
end function

function getExamplePlayerConfigWithContentNodeAndPlaylist()
  content = CreateObject("roSGNode", "ContentNode")

  firstVideo = CreateObject("roSGNode", "ContentNode")
  firstVideo.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
  firstVideo.streamFormat = "hls"
  firstVideo.title = "FirstVideo"

  secondVideo = CreateObject("roSGNode", "ContentNode")
  secondVideo.url = "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd"
  secondVideo.streamFormat = "dash"
  secondVideo.title = "SecondVideo"

  content.appendChild(firstVideo)
  content.appendChild(secondVideo)

  return content
end function
