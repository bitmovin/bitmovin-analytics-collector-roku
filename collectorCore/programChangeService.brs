' Shared implementation of the `programChange` API.
'
' The body is player-agnostic: it drives the impression boundary through `setVideoTimeStart`,
' `setVideoTimeEnd`, `updateSample` and `sendAnalyticsRequestAndClearValues`, which every concrete
' collector implements and baseCollector.brs declares, plus `m.currentState` and
' `m.playerStateTimer`. The state vocabulary is passed in rather than discovered.

'Conclude the running impression and open a new one for the new program, without interrupting playback.
'@param {Object} newSourceMetadata - AnalyticsConfig fields for the new program, optionally plus
'                                    `mpdUrl` / `m3u8Url` / `progUrl` / `path`.
'@param {Object} stateNames - This collector's `playing` and `paused` state names, plus
'                             `startupFinished`. May be `invalid` before a player is attached.
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

  ' `skipHeartbeatReset` on both sends: every client of a live stream hits the same program
  ' boundary at the same moment, and resetting the heartbeat timer here would synchronise all of
  ' them into one thundering herd a minute later.
  sendAnalyticsRequestAndClearValues(finalSampleData, stateDuration, m.currentState, true)

  ' Regenerates impressionId, resets sequenceNumber, and closes any open SSAI ad break on the
  ' outgoing impression via ssaiOnSourceChange().
  m.collectorCore.callFunc("setupSample")

  ' Config-level fields only - getMetadataFromAnalyticsConfig drops the URLs applied below.
  m.collectorCore.callFunc("updateAnalyticsConfig", newSourceMetadata)
  updateSample(getProgramChangeSourceMetadata(newSourceMetadata))

  ' Synthetic startup for the new session. `videoStartupTime` and `duration` are both 1 so plays,
  ' playAttempts and billing work without this counting as real startup time; the backend excludes
  ' it from the startup percentiles by the isProgramChange flag. The state name is lower case to
  ' match the other platforms (Android: DefaultStateMachineListener.onProgramChange).
  setVideoTimeStart()
  setVideoTimeEnd()
  sendAnalyticsRequestAndClearValues({ isProgramChange: true, videoStartupTime: 1 }, 1, "programchange", true)

  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

'Whether there is no session worth concluding yet, in which case `programChange` degrades to a
'metadata merge: no player attached, no state recorded, or playback has never started. A program
'change during startup is just a normal startup carrying different metadata, so it must not open a
'second session - mirrors `!isStartupFinished` in the Android state machine.
'@param {Object} stateNames - The collector's state vocabulary, or `invalid`.
'@return {Boolean}
function isBeforeFirstProgram(stateNames)
  if stateNames = invalid then return true
  if m.currentState = invalid then return true

  return not stateNames.startupFinished
end function

'Map the stream URL carried by the new program metadata onto sample fields, inferring `streamFormat`.
'@param {Object} metadata - The new program metadata.
'@return {Object} - Sample fields to merge; empty when the metadata carries no URL.
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
