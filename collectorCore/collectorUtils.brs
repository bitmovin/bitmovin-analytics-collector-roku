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
  if timer = invalid then return 0

  return timer.TotalMilliseconds()
end function

function getDefaultStateTimeData()
  return {
    played: 0,
    buffered: 0,
    paused: 0,
    seeked: 0
  }
end function

function mapNativePlayerStateForAnalytic(playerStates, state)
  map = {}
  map[playerStates.PLAYING] = "played"
  map[playerStates.PAUSED] = "paused"
  map[playerStates.BUFFERING] = "buffered"
  map[playerStates.NONE] = "none"

  return map[state]
end function

function mapBitmovinPlayerStateForAnalytic(playerStates, state)
  map = {}
  map[playerStates.PLAYING] = "played"
  map[playerStates.PAUSED] = "paused"
  map[playerStates.STALLING] = "buffered"
  map[playerStates.NONE] = "none"

  return map[state]
end function