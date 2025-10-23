function getVideoStartFailedEvents()
  return {
    PlayerError: "PLAYER_ERROR",
    Timeout: "TIMEOUT"
  }
end function

function getErrorSeverities()
  return {
    critical: "CRITICAL",
    info: "INFO"
  }
end function
