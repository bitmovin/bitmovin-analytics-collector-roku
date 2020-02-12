# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Develop
### Added
- `streamFormat` and corresponding `url` to samples (AN-1135)
- `videoWindowHeight` and `videoWindowWidth` to samples (AN-1139)
- `size` (fullscreen or window) to samples (AN-1136)
- `videoTimeStart` and `videoTimeEnd` to samples (AN-1144)
- `sequenceNumber` to samples (AN-1138)

### Fixed
- `pageLoadType` was not set to `FOREGROUND` (AN-1145)
- `platform` field not set to `roku` (AN-1134)
- missing player `version` in samples for native player (AN-1137)
- missing `state` for setup and startup samples (AN-1140, AN-1141)
- missing `startuptime` in the sample and reset startup/setup measurements (AN-1145)
- `played` not set in heartbeat samples
- sample data from previous session being sent out with `impressionId` from new session when a sourceChange happened (AN-1162)
- buffering sample not having the same videoTimeStart and videoTimeEnd (AN-1149)

### Changed
- native collector to be up-to-date with bitmovin collector (AN-1164)
