' Player controls
function getPlayerControls()
  controlStates = {
    PLAY: "play",
    INSTANT_REPLAY: "replay",
    RESUME: "resume",
    PAUSE: "pause",
    PREBUFFER: "prebuffer",
    run: "run",
    stop: "stop"
  }
  return controlStates
end function

' SSAI States
function getSsaiStates()
  ssaiStates = {
    AD_BREAK_STARTED: "AD_BREAK_STARTED",
    ACTIVE: "ACTIVE",
    IDLE: "IDLE"
  }
  return ssaiStates
end function
