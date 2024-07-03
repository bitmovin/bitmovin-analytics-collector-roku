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

function getCustomDataValueKeys()
  customDataValuesKeys = [
    "customData1",
    "customData2",
    "customData3",
    "customData4",
    "customData5",
    "customData6",
    "customData7",
    "customData8",
    "customData9",
    "customData10",
    "customData11",
    "customData12",
    "customData13",
    "customData14",
    "customData15",
    "customData16",
    "customData17",
    "customData18",
    "customData19",
    "customData20",
    "customData21",
    "customData22",
    "customData23",
    "customData24",
    "customData25",
    "customData26",
    "customData27",
    "customData28",
    "customData29",
    "customData30",
    "experimentName",
  ]
  return customDataValuesKeys
end function
