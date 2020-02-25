function getPlayerSourceType()
  return {
    AOM: "AOM",
    TOS: "TOS",
    SINTEL: "SINTEL",
    SINGLE_SPEED: "SINGLE_SPEED"
  }
end function

function getPlayerContentNodeSourceType()
  return {
    SINTEL: "SINTEL",
    PLAYLIST: "PLAYLIST"
  }
end function

function getPlayerConfig(sourceType)
  playerConfig = {
    playback: {
      autoplay: true,
      muted: true
    },
    adaptation: {
      preload: false
    }
  }

  PlayerSourceType = getPlayerSourceType()
  sourceConfig = CreateObject("roAssociativeArray")

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

  playerConfig.Append({
    source: sourceConfig
  })
  return playerConfig
end function


function getPlayerContentNodeConfig(sourceType)
  config = CreateObject("roSGNode", "ContentNode")

  PlayerSourceType = getPlayerContentNodeSourceType()
  if sourceType = PlayerSourceType.SINTEL
    config.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
    config.streamFormat = "hls"
    config.title = "Sintel"
  else if sourceType = PlayerSourceType.PLAYLIST
    firstVideo = CreateObject("roSGNode", "ContentNode")
    firstVideo.url = "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
    firstVideo.streamFormat = "hls"
    firstVideo.title = "Art Of Motion"
    config.Append(firstVideo)

    secondVideo = CreateObject("roSGNode", "ContentNode")
    secondVideo.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
    secondVideo.streamFormat = "hls"
    secondVideo.title = "Sintel"
    config.Append(secondVideo)
  end if
  return config
end function
