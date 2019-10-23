function getCurrentTimeInMilliseconds()
  dateTime = CreateObject("roDateTime")
  return (dateTime.AsSeconds().ToStr() + "000").toInt()
end function

function getCurrentTimeInSeconds()
  dateTime = CreateObject("roDateTime")
  return dateTime.AsSeconds()
end function

function getDuration(currentTimestamp, previousTimestamp)
  if currentTimestamp = invalid or previousTimestamp = invalid
    return invalid
  end if

  return (currentTimestamp - previousTimeStamp)
end function