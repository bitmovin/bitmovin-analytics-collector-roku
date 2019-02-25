function getCurrentTimeInMilliseconds()
  ' TODO: return dt.AsSeconds() * 1000 probably exceeds maximum size
  dt = CreateObject("roDateTime")
  return dt.AsSeconds().ToStr() + "000"
end function

function getCurrentTimeInSeconds()
  dt = CreateObject("roDateTime")
  return dt.AsSeconds()
end function
