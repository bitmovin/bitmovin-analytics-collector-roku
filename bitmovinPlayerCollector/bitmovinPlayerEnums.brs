' Player states
function getPlayerStates()
  playerStates = {
    PLAYING: "playing",
    STALLING: "stalling",
    PAUSED: "paused",
    FINISHED: "finished",
    ERROR: "error",
    NONE: "none",
    SETUP: "setup",
    READY: "ready"
  }
  return playerStates
end function

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
