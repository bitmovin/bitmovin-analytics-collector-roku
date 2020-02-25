function getPlayerSourceType()
  return {
      AOM: "AOM",
      TOS: "TOS",
      SINTEL: "SINTEL",
      CONTENT_NODE: "CONTENT_NODE",
      SINGLE_SPEED: "SINGLE_SPEED"
  }
end function

function getPlayerConfig(sourceType)
  config = {
    playback: {
      autoplay: true,
      muted: true
    },
    adaptation: {
      preload: false
    }
  }
  sourceConfig = {}

  PlayerSourceType = getPlayerSourceType()
  if sourceType = PlayerSourceType.AOM
    sourceConfig = {
      hls: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8",
      title: "Art of Motion"
    }
  else if sourceType = PlayerSourceType.TOS
    sourceConfig = {
      dash: "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd",
      title: "Tears of Steel",
      drm: {
        widevine: {
          LA_URL: "https://proxy.uat.widevine.com/proxy?video_id=HDCP_V1&provider=widevine_test"
        }
      }
    }
  else if sourceType = PlayerSourceType.SINTEL
    sourceConfig = {
      hls: "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
      title: "Sintel"
    }
  else if sourceType = PlayerSourceType.SINGLE_SPEED
    sourceConfig = {
      dash: "https://bitmovin-a.akamaihd.net/content/analytics-teststreams/battlefield-60fps/mpds/battlefield-singlespeed.mpd",
      title: "Battlefield SingleSpeed"
    }
  end if

  config.Append({
    source: sourceConfig
  })
  return config
end function


function getPlayerContentNodeConfig()
  config = CreateObject("roSGNode", "ContentNode")
  config.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
  config.streamFormat = "hls"
  config.title = "Sintel"
  return config
end function
