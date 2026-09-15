' The primitives called here - setVideoTimeStart/End, updateSample and
' sendAnalyticsRequestAndClearValues - are implemented by each concrete collector and declared as
' stubs in baseCollector.brs, so this scope validates.
sub handleProgramChange(newSourceMetadata, stateNames)
  if newSourceMetadata = invalid then return

  if isBeforeFirstProgram(stateNames)
    m.collectorCore.callFunc("updateAnalyticsConfig", newSourceMetadata)
    return
  end if

  setVideoTimeEnd()
  stateDuration = m.playerStateTimer.TotalMilliseconds()

  finalSampleData = { isProgramChange: true }
  if m.currentState = stateNames.playing
    finalSampleData.played = stateDuration
  else if m.currentState = stateNames.paused
    finalSampleData.paused = stateDuration
  end if

  ' skipHeartbeatReset on both sends: every client of a live stream hits the same program boundary
  ' at the same moment, and resetting the heartbeat timer would synchronise them into one
  ' thundering herd a minute later.
  sendAnalyticsRequestAndClearValues(finalSampleData, stateDuration, m.currentState, true)

  ' Also closes any open SSAI ad break on the outgoing impression, via ssaiOnSourceChange().
  m.collectorCore.callFunc("setupSample")

  ' getMetadataFromAnalyticsConfig keeps config fields only, so the URLs go through updateSample.
  m.collectorCore.callFunc("updateAnalyticsConfig", newSourceMetadata)
  updateSample(getProgramChangeSourceMetadata(newSourceMetadata))

  ' videoStartupTime and duration are both 1 so plays, playAttempts and billing work without this
  ' counting as real startup time; the backend excludes it by the isProgramChange flag. Lower-case
  ' state name matches the other platforms (Android: DefaultStateMachineListener.onProgramChange).
  setVideoTimeStart()
  setVideoTimeEnd()
  sendAnalyticsRequestAndClearValues({ isProgramChange: true, videoStartupTime: 1 }, 1, "programchange", true)

  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

' A programChange during startup is a normal startup carrying different metadata, so it must not
' open a second session - mirrors !isStartupFinished in the Android state machine.
function isBeforeFirstProgram(stateNames)
  if stateNames = invalid then return true
  if m.currentState = invalid then return true

  return not stateNames.startupFinished
end function

function getProgramChangeSourceMetadata(metadata)
  sourceMetadata = {}
  if metadata.DoesExist("path") then sourceMetadata.path = metadata.path
  if metadata.DoesExist("mpdUrl")
    sourceMetadata.mpdUrl = metadata.mpdUrl
    sourceMetadata.streamFormat = "dash"
  end if
  if metadata.DoesExist("m3u8Url")
    sourceMetadata.m3u8Url = metadata.m3u8Url
    sourceMetadata.streamFormat = "hls"
  end if
  if metadata.DoesExist("progUrl")
    sourceMetadata.progUrl = metadata.progUrl
    sourceMetadata.streamFormat = "progressive"
  end if
  return sourceMetadata
end function
