' SSAI States
function getSsaiStates()
  ssaiStates = {
    AD_BREAK_STARTED: "AD_BREAK_STARTED",
    ACTIVE: "ACTIVE",
    IDLE: "IDLE"
  }
  return ssaiStates
end function

function getAdTypes()
  adTypes = {
    NO_AD: 0,
    CSAI: 1,
    SSAI: 2
  }
  return adTypes
end function

function getAdQuartileTypes()
  adQuartileTypes = {
    FIRST: "first",
    MIDPOINT: "midpoint",
    THIRD: "third",
    COMPLETED: "completed",
  }
  return adQuartileTypes
end function

function getCustomDataValueKeys()
  maxFieldIndex = 100
  keys = []
  for i = 1 to maxFieldIndex
    keys.Push("customData" + i.ToStr())
  end for
  return keys
end function

function getErrorSeverities()
  return {
    critical: "CRITICAL",
    info: "INFO"
  }
end function
