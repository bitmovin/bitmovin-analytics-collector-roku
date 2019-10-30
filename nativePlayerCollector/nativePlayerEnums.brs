' State enums exposed to user
function getPlayerState()
  playerState = {
    PLAYING: "playing",
    BUFFERING: "buffering",
    PAUSED: "paused",
    FINISHED: "finished",
    ERROR: "error",
    NONE: "none",
  }
  return playerState
end function