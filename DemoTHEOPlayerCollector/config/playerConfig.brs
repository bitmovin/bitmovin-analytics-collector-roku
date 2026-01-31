function getPlayerSourceType()
  return {
    AOM: "AOM",
    LIVE_SAMPLE: "LIVE_SAMPLE",
    TOS: "TOS",
    SINTEL: "SINTEL",
    SINGLE_SPEED: "SINGLE_SPEED",
    CORRUPT_BEGINNING: "CORRUPT_BEGINNING"
  }
end function

function getBaseUrl()
  return "https://bitmovin-a.akamaihd.net/content"
end function

function getPlayerSource(sourceType)
  PlayerSourceType = getPlayerSourceType()
  content = CreateObject("roAssociativeArray")

  if sourceType = PlayerSourceType.AOM
    content = {
      src: getBaseUrl() + "/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
      type: "application/x-mpegURL"
      description: "Art of Motion"
    }
  else if sourceType = PlayerSourceType.LIVE_SAMPLE
    content = {
      src: "https://livesim.dashif.org/livesim/testpic_2s/Manifest.mpd"
      type: "application/dash+xml"
      description: "Live Sample"
    }
  else if sourceType = PlayerSourceType.TOS
    content = {
      src: "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd"
      type: "application/dash+xml"
      description: "Tears of Steel"
      contentProtection: {
        integration: "widevine"
        licenseUrl: "https://proxy.uat.widevine.com/proxy?video_id=HDCP_V1&provider=widevine_test"
      }
    }
  else if sourceType = PlayerSourceType.SINTEL
    content = {
      src: getBaseUrl() + "/sintel/hls/playlist.m3u8"
      type: "application/x-mpegURL"
      description: "Sintel"
    }
  else if sourceType = PlayerSourceType.SINGLE_SPEED
    content = {
       src: getBaseUrl() + "/analytics-teststreams/redbull-parkour/singlespeed.mpd"
      type: "application/dash+xml"
      description: "Art of Motion - SingleSpeed"
    }
  else if sourceType = PlayerSourceType.CORRUPT_BEGINNING
    content = {
      src: getBaseUrl() + "/analytics-teststreams/redbull-parkour/corrupted_first_segment.mpd"
      type: "application/dash+xml"
      description: "redbull-parkour"
    }
  end if

  return content
end function
