function getCurrentTimeInMilliseconds()
  dateTime = CreateObject("roDateTime")
  seconds# = dateTime.AsSeconds()
  miliseconds# = seconds# * 1000
  return miliseconds#
end function

'Returns duration of the timer in milliseconds
'@param {Object} timer - The timer object
'@return {number} - Duration the timer was active in milliseconds
function getDuration(timer)
  if timer = invalid then return 0

  return timer.TotalMilliseconds()
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