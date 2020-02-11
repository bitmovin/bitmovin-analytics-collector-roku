# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Develop
### Added
- `streamFormat` and corresponding `url` to sample (AN-1135)
- `videoWindowHeight` and `videoWindowWidth` to sample for bitmovin and native player (AN-1139)
- `size` to sample for bitmovin and native player (AN-1136)

### Fixed
- `pageLoadType` was not set to `FOREGROUND` (AN-1145)
- `platform` field not set to `roku` (AN-1134)
- missing player `version` in samples for native player (AN-1137)
- missing `state` for setup and startup samples (AN-1140, AN-1141)
- missing `startuptime` in the sample and reset startup/setup measurements (AN-1145)
- heartbeat timer not resetting after a sample was sent out
