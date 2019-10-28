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

function getDuration(currentTimestamp, previousTimestamp)
  if currentTimestamp = invalid or previousTimestamp = invalid
    return invalid
  end if

  return (currentTimestamp - previousTimeStamp)
end function