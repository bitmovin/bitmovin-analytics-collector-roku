# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Develop

### Internal

- fixed warnings and added comments

## v2.5.1

### Removed

- deinitialization call for the analytics collector as it gets automatically destroyed alongside the Bitmovin player.

## v2.5.0

### Internal

- Added `runTask`, `stopTask` and `isTaskRunning` to `AnalyticsDataTask` to prevent orphaned tasks running in the background.

## v2.4.0

### Added

- tracking of audio- and subtitle language for Bitmovin and Native player (AN-2829)

## v2.3.0

### Added

- additional `customData` fields 26 to 30 (AN-2640)

## v2.2.0

### Added

- additional `customData` fields 8 to 25 (AN-2640)

## v2.1.0

### Fixed

- native collector reporting `seekTime` in seconds (AN-2200)

### Changed

- collector behaviour to stop collecting data after an error (AN-2237)

### Removed

- collection of error segments (AN-2237)

## v2.0.0

### Changed

- setup of Bitmovin Analytics: use `callFunc("initializeAnalytics", config)` before the `initializePlayer` call to set the licenseKey during runtime (AN-1959)

### Fixed

- detection of operating system and device type

## v1.1.1

### Fixed

- `videoTitle` in sample always `null` which can be configured with the `analyticsConfig.title` attribute (AN-1616)

## v1.1.0

### Added

- support for `wist` linter (PR-185)
- playAttempt tracking for PlayerError and Timeout (AN-1290)
- logging for failed licensing requests (AN-1504)

## v1.0.0

### Added

- `streamFormat` and corresponding `url` to samples (AN-1135)
- `videoWindowHeight` and `videoWindowWidth` to samples (AN-1139)
- `size` (fullscreen or window) to samples (AN-1136)
- `videoTimeStart` and `videoTimeEnd` to samples (AN-1144)
- `sequenceNumber` to samples (AN-1138)

### Fixed

- `pageLoadType` was not set to `FOREGROUND` (AN-1145)
- `platform` field not set to `roku` (AN-1134)
- missing player `version` in samples for native/bitmovin player (AN-1137)
- missing `state` for setup and startup samples (AN-1140, AN-1141)
- missing `startuptime` in the sample and reset startup/setup measurements (AN-1145)
- heartbeat timer not resetting after a sample was sent out
- `played` not set in heartbeat samples
- sample data from previous session being sent out with `impressionId` from new session when a sourceChange happened (AN-1162)
- buffering samples not having same videoTimeStart/End and bitmovin adapter not listening to correct stalling events (AN-1149)
- sourceChange event not handled correctly for native player (AN-1169)
- heartbeatTimer not correctly reset which led to heartbeatSamples added to queue after pauseEvent > 1min
- analytics configuration fields (videoId, title, ...) missing in sample (AN-1163)
- default values of `errorCode`, `errorMessage` and `errorSegments` by setting them to `invalid` (AN-1147)

### Changed

- native collector to be up-to-date with bitmovin collector (AN-1164)
