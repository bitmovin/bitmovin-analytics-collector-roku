
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
sub programChange()
end sub


' Implemented by every concrete collector; declared here so scripts attached at this level resolve
' against a defined contract. Reaching one of these bodies means the child's override did not
' resolve, which would silently turn the caller into a no-op. The parameters are printed both to
' name what was dropped and to keep the device compiler from warning about unused variables.
function updateSample(sampleData)
  print "[baseCollector] BUG: base stub `updateSample` called, dropped sample: "; sampleData
  return false
end function

sub setVideoTimeStart()
  print "[baseCollector] BUG: base stub `setVideoTimeStart` called"
end sub

sub setVideoTimeEnd()
  print "[baseCollector] BUG: base stub `setVideoTimeEnd` called"
end sub

sub sendAnalyticsRequestAndClearValues(eventData, duration, state = "", skipHeartbeatReset = false)
  print "[baseCollector] BUG: base stub `sendAnalyticsRequestAndClearValues` called, dropped state="; state; " duration="; duration; " skipHeartbeatReset="; skipHeartbeatReset; " eventData="; eventData
end sub
