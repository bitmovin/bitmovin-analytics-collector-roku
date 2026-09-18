
sub initializeAnalytics()
end sub
sub setAnalyticsConfig()
end sub
sub initializePlayer()
end sub
sub destroy()
end sub
sub setNewMetadata()
end sub
sub setCustomData()
end sub
sub setCustomDataOnce()
end sub
sub adBreakStart()
end sub
sub adStart()
end sub
sub adBreakEnd()
end sub
sub adQuartileFinished()
end sub
sub programChange(newSourceMetadata = invalid)
end sub


' Implemented by every concrete collector; declared here so scripts attached at this level resolve
' against a defined contract.
function updateSample(sampleData)
  return false
end function

sub setVideoTimeStart()
end sub

sub setVideoTimeEnd()
end sub

sub sendAnalyticsRequestAndClearValues(eventData, duration, state = "", skipHeartbeatReset = false)
end sub
