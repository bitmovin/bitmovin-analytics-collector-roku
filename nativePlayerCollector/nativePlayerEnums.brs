' Player states
function getPlayerStates()
  playerStates = {
    PLAYING: "playing",
    BUFFERING: "buffering",
    PAUSED: "paused",
    FINISHED: "finished",
    ERROR: "error",
    NONE: "none",
    SEEKING: "seeking",
    SOURCE_CHANGING: "sourceChanging"
  }
  return playerStates
end function

' Player controls
function getPlayerControls()
  controlStates = {
    NONE: "none",
    PLAY: "play",
    STOP: "stop",
    PAUSE: "pause",
    RESUME: "resume",
    REPLAY: "replay",
    PREBUFFER: "prebuffer",
    SKIP_CONTENT: "skipcontent"
  }
  return controlStates
end function
