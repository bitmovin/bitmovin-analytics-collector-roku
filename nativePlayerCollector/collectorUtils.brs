function getCurrentTimeInMilliseconds()
  dateTime = CreateObject("roDateTime")
  seconds# = dateTime.AsSeconds()
  miliseconds# = seconds# * 1000
  return miliseconds#
end function

function getCurrentTimeInSeconds()
  dateTime = CreateObject("roDateTime")
  seconds# = dateTime.AsSeconds()
  return seconds#
end function

function getDuration(timer)
  if timer = invalid then return invalid

  return timer.TotalMilliseconds()
end function

function mapPlayerStateForAnalytic(playerState)
  map = {}
  map[playerState.PLAYING] = "played"
  map[playerState.PAUSED] = "paused"
  map[playerState.BUFFERING] = "buffered"
  map[playerState.NONE] = "none"

  return map
end function

function getDefaultStateTimeData()
  return {
    played: 0,
    buffered: 0,
    paused: 0
  }
end function
