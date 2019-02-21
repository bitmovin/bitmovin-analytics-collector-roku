function getDemoConfig()
  return {
    playback: {
      autoplay: true,
      muted: true
    },
    adaptation: {
      preload: false
    },
    source: {
      dash: "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd",
      title: "Test video",
      drm: {
        widevine: {
          LA_URL:  "https://proxy.uat.widevine.com/proxy?video_id=HDCP_V1&provider=widevine_test"
        }
      }
    }
  }
end function
