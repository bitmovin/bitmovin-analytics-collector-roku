' THEO does not directly expose a 'state', so these values are used to track state for analytics
function getCollectorStates()
  return {
    SETUP: "setup"
    PLAYING: "playing"
    PAUSED: "paused"
    SEEKING: "seeking"
    AD: "ad"
  }
end function

' SSAI integrations we've smoke-tested / explicitly support. Anything else - including a
' missing/unknown `adBreak.integration` - fails closed to the legacy CSAI path instead of
' silently opting an untested integration into SSAI tracking. Extend this list as further
' integrations are verified.
function getSupportedSsaiIntegrations()
  return ["google-dai", "mediakind"]
end function
