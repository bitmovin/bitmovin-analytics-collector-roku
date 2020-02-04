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

'Return the video window size as reported by the video element of the player.
'@param {video} - The Video node
'@return {Object} - Object containing videoWindowHeight and videoWindowWidth as required by the analytics sample.
function getVideoWindowSize(video)
  height = m.deviceInfo.GetDisplaySize().h
  width = m.deviceInfo.GetDisplaySize().w
  if video.height <> 0
    height = video.height
  end if
  if video.width <> 0
    width = video.width
  end if
  return {videoWindowHeight: Int(height), videoWindowWidth: Int(width)}
end function

'Return the playback size type (FULLSCREEN, WINDOW) of the stream
'@param {videoWindowHeight} - Video window height
'@param {videoWindowWidth} - Video window width
'@return {String} - Either FULLSCREEN or WINDOW depending on the width and height of the video window
function getSizeType(videoWindowHeight, videoWindowWidth)
  if videoWindowHeight.GetInt() >= m.deviceInfo.GetDisplaySize().h.GetInt() and videoWindowWidth.GetInt() >= m.deviceInfo.GetDisplaySize().w.GetInt()
    return "FULLSCREEN"
  end if
  return "WINDOW"
end function