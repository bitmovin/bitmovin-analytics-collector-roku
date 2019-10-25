sub init()
  m.tag = "[nativePlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
end sub

sub initializePlayer(player)
  m.player = player

  setUpObservers()
  setUpHelperVariables()

  m.previousState = ""
  m.currentState = player.state
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "native",
    version: "unknown"
  }
  updateSampleDataAndSendAnalyticsRequest(playerData)
end sub

sub setUpObservers()
  m.player.observeFieldScoped("state", "onPlayerStateChanged")
  m.player.observeFieldScoped("seek", "onSeek")
end sub

sub setUpHelperVariables()
  m.seekStartPosition = invalid
  m.alreadySeeking = false
end sub

sub onPlayerStateChanged()
  m.previousState = m.currentState
  m.currentState = m.player.state
  ' TODO remove the print statments, leave only code related to updating the sample

  if m.player.state = "none"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "buffering"
  ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "playing"
    onSeeked()
  else if m.player.state = "paused"
    onSeek()
  else if m.player.state = "stopped"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "finished"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "error"
      ' print m.tag; "Player event caught "; m.player.state
  end if

  m.previousTimestamp = m.currentTimestamp
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  duration = getDuration(m.currentTimestamp.toInt(), m.previousTimestamp.toInt())

  stateChangedData = {
    duration: duration,
    state: m.previousState,
    time: m.currentTimestamp.ToStr()
  }
  updateSampleDataAndSendAnalyticsRequest(stateChangedData)
end sub

sub updateSampleDataAndSendAnalyticsRequest(sampleData)
  m.collectorCore.callFunc("updateSampleAndSendAnalyticsRequest", sampleData)
end sub

sub onSeek()
  if m.alreadySeeking = true then return

  m.alreadySeeking = true
  m.seekStartPosition = m.player.position
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onSeeked()
  if m.seekStartPosition <> invalid and m.seekStartPosition <> m.player.position and m.seekTimer <> invalid
    updateSampleDataAndSendAnalyticsRequest({"seeked": m.seekTimer.TotalMilliseconds()})
  end if

  m.alreadySeeking = false
  m.seekStartPosition = invalid
  m.seekTimer = invalid
end sub
