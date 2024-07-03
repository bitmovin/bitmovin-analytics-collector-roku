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
    NO_AD = 0,
    CSAI = 1,
    SSAI = 2
  }
  return adTypes
end function
