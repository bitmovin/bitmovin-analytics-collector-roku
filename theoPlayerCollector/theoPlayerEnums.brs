' THEO does not directly expose a 'state', so these values are used to track state for analytics
function getCollectorStates()
  return {
    SETUP: "setup"
    PLAYING: "playing"
    PAUSED: "paused"
  }
end function
