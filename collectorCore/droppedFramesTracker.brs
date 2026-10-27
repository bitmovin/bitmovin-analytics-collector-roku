sub initDroppedFramesTracker()
  m.droppedFramesVideoNode = invalid
  m.didEnableDecoderStats = false
  m.lastDecoderStats = invalid
  m.pendingDroppedFrames = 0
end sub

sub startDroppedFramesTracking(videoNode)
  stopDroppedFramesTracking()
  m.pendingDroppedFrames = 0

  if videoNode = invalid or not videoNode.hasField("enableDecoderStats") then return

  m.droppedFramesVideoNode = videoNode
  m.didEnableDecoderStats = not videoNode.enableDecoderStats
  videoNode.enableDecoderStats = true
  ' Counters that are already running were collected before we attached; they are the baseline.
  m.lastDecoderStats = readDecoderStatsSnapshot(videoNode.decoderStats)
  videoNode.observeFieldScoped("decoderStats", "onDecoderStatsChanged")
end sub

sub stopDroppedFramesTracking()
  videoNode = m.droppedFramesVideoNode
  if videoNode <> invalid
    videoNode.unobserveFieldScoped("decoderStats")
    ' Leave the app`s own setting alone if it had decoder stats on before we attached.
    if m.didEnableDecoderStats then videoNode.enableDecoderStats = false
  end if

  m.droppedFramesVideoNode = invalid
  m.didEnableDecoderStats = false
  m.lastDecoderStats = invalid
end sub

sub onDecoderStatsChanged(event)
  accumulateDroppedFrames(event.getData())
end sub

sub accumulateDroppedFrames(decoderStats)
  snapshot = readDecoderStatsSnapshot(decoderStats)
  if snapshot = invalid
    ' No decoder: whatever reports next starts counting from zero.
    m.lastDecoderStats = invalid
    return
  end if

  last = m.lastDecoderStats
  if last = invalid or snapshot.renderCount < last.renderCount or snapshot.frameDropCount < last.frameDropCount
    ' Counters restarted (seek, new source): every drop they show happened since then.
    ' Not detected: a restart whose first update has renderCount >= last.renderCount and
    ' frameDropCount >= last.frameDropCount. The tracker then undercounts the new drops by
    ' last.frameDropCount.
    m.pendingDroppedFrames = m.pendingDroppedFrames + snapshot.frameDropCount
  else
    m.pendingDroppedFrames = m.pendingDroppedFrames + snapshot.frameDropCount - last.frameDropCount
  end if
  m.lastDecoderStats = snapshot
end sub

' Returns the frames dropped since the previous call and starts the next interval.
function takeDroppedFrames()
  ' Picks up an update whose observer callback has not run yet; re-reading a snapshot already seen
  ' adds nothing.
  if m.droppedFramesVideoNode <> invalid then accumulateDroppedFrames(m.droppedFramesVideoNode.decoderStats)

  droppedFrames = m.pendingDroppedFrames
  m.pendingDroppedFrames = 0
  return droppedFrames
end function

function readDecoderStatsSnapshot(decoderStats)
  if GetInterface(decoderStats, "ifAssociativeArray") = invalid then return invalid
  if not isWholeNumber(decoderStats.frameDropCount) or not isWholeNumber(decoderStats.renderCount) then return invalid

  return {
    frameDropCount: decoderStats.frameDropCount,
    renderCount: decoderStats.renderCount
  }
end function

function isWholeNumber(value) as boolean
  return GetInterface(value, "ifInt") <> invalid or GetInterface(value, "ifLongInt") <> invalid
end function
