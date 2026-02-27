# Bitmovin Analytics Collector — API Reference

All three collector variants (`bitmovinPlayerCollector`, `nativePlayerCollector`, `theoPlayerCollector`) expose the same interface defined in `collectorCore/baseCollector.xml`. Every method is invoked via `callFunc` on the collector node.

| Method | Category | Description |
|--------|----------|-------------|
| [`initializeAnalytics(config)`](#initializeanalyticsconfig) | Lifecycle | Initialize the analytics engine with a license key and metadata |
| [`initializePlayer(player)`](#initializeplayerplayer) | Lifecycle | Attach the collector to a player node |
| [`destroy()`](#destroy) | Lifecycle | Detach the collector and shut down background tasks |
| [`setAnalyticsConfig(config)`](#setanalyticsconfigconfig) | Metadata | Merge updated analytics configuration into the current impression |
| [`setNewMetadata(metadata)`](#setnewmetadatametadata) | Metadata | Queue metadata to apply on the next source load |
| [`setCustomData(customData)`](#setcustomdatacustomdata) | Metadata | Apply custom data fields immediately, finishing the current sample |
| [`setCustomDataOnce(customData)`](#setcustomdataoncecustomdata) | Metadata | Apply custom data to a single sample only |
| [`adBreakStart(adBreakMetadata)`](#adbreakstartadbreakmetadata) | SSAI | Signal the start of an ad break |
| [`adStart(adMetadata)`](#adstartadmetadata) | SSAI | Signal the start of an individual ad |
| [`adBreakEnd()`](#adbreakend) | SSAI | Signal the end of an ad break |
| [`adQuartileFinished(adQuartile, adQuartileMetadata)`](#adquartilefinishedadquartile-adquartilemetadata) | SSAI | Report an ad quartile milestone |
| [`programChange(newSourceMetadata)`](#programchangenewsourcemetadata) | Live | Report a program change in a live stream *(THEO Player only)* |

---

## AnalyticsConfig

Configuration object accepted by `initializeAnalytics`, `setAnalyticsConfig`, and `programChange`.

| Field | Type | Description |
|-------|------|-------------|
| `key` | String | Bitmovin Analytics license key. (Can be set in the channel manifest instead) |
| `title` | String | Human-readable video title. |
| `videoId` | String | Unique identifier for the video asset. |
| `cdnProvider` | String | CDN provider name (e.g. `"Akamai"`). |
| `customUserId` | String | Application-level user identifier. |
| `experimentName` | String | Arbitrary experiment name. |
| `isLive` | Boolean | Set to `true` for live streams. Defaults to `false`. |
| `customData1`–`customData100` | String | Free-form custom dimensions. |
| `ssaiEngagementTrackingEnabled` | Boolean | Enables sending SSAI ad engagement samples (started, quartiles). Defaults to `false`. |

---

## Lifecycle

### `initializeAnalytics(config)`

Initializes the analytics engine. Must be called before `initializePlayer`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config` | AssociativeArray | No | Analytics configuration. See [AnalyticsConfig](#analyticsconfig) below. |

```brightscript
analyticsConfig = {
  key: "YOUR_LICENSE_KEY",
  title: "My Video",
  videoId: "video-123",
  isLive: false,
}
m.collector.callFunc("initializeAnalytics", analyticsConfig)
```

> The license key can also be set in the channel `manifest` as `bitmovin_analytics_license_key` and will be picked up automatically if `config.key` is absent.

---

### `initializePlayer(player)`

Attaches the collector to a player node and starts observing player events. Must be called after `initializeAnalytics` and before the player loads any content.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `player` | roSGNode | Yes | The player node to monitor. |

```brightscript
m.collector.callFunc("initializePlayer", m.player)
```

---

### `destroy()`

Detaches the collector from the player, stops all observers, and shuts down the background analytics task. Call this when the player is being torn down.

```brightscript
m.collector.callFunc("destroy", invalid)
```

---

## Metadata

### `setAnalyticsConfig(config)`

Updates the analytics configuration for the current and future impressions. Fields in `config` are merged into the existing configuration.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config` | AssociativeArray | Yes | Partial or full [AnalyticsConfig](#analyticsconfig). |

```brightscript
m.collector.callFunc("setAnalyticsConfig", { title: "New Title", videoId: "video-456" })
```

---

### `setNewMetadata(metadata)`

Queues metadata to be applied with the next analytics sample. Useful for setting fields that are not yet known at `initializeAnalytics` time. The metadata is consumed once (on the next source load event) and then cleared.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `metadata` | AssociativeArray | Yes | Any valid sample fields to merge in. |

```brightscript
m.collector.callFunc("setNewMetadata", { videoId: "video-789", title: "Episode 2" })
```

---

### `setCustomData(customData)`

Applies custom data fields to the current impression immediately. Finalizes the in-progress sample (sending it) before applying the new values, so the custom data takes effect from the next sample onward.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customData` | AssociativeArray | Yes | Fields to merge into the current sample. Typically `customData1`–`customData100`. |

```brightscript
m.collector.callFunc("setCustomData", { customData1: "segment-A", customData2: "tier-premium" })
```

---

### `setCustomDataOnce(customData)`

Like `setCustomData`, but the custom data is applied to a single sample only and is not retained for subsequent samples.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customData` | AssociativeArray | Yes | Fields to include in one sample only. |

```brightscript
m.collector.callFunc("setCustomDataOnce", { customData3: "chapter-intro" })
```

---

## Server-Side Ad Insertion (SSAI)

The SSAI API follows the state machine: **IDLE → AD_BREAK_STARTED → ACTIVE → IDLE**.

```
adBreakStart()  →  adStart()  →  adQuartileFinished() (×n)  →  adBreakEnd()
```

### `adBreakStart(adBreakMetadata)`

Signals the beginning of an SSAI ad break. No-op if already in an ad break.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adBreakMetadata` | AssociativeArray | No | Ad break details. |
| `adBreakMetadata.adPosition` | String | No | Position of the ad break: `"preroll"`, `"midroll"`, or `"postroll"`. |

```brightscript
m.collector.callFunc("adBreakStart", { adPosition: "midroll" })
```

---

### `adStart(adMetadata)`

Signals the start of an individual ad within the current ad break. Must be called after `adBreakStart`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adMetadata` | AssociativeArray | No | Metadata for the specific ad. |
| `adMetadata.adId` | String | No | Identifier for the ad. |
| `adMetadata.adSystem` | String | No | Ad system/provider name. |
| `adMetadata.customData` | AssociativeArray | No | Custom data fields (`customData1`–`customData100`) scoped to this ad. |

```brightscript
m.collector.callFunc("adStart", {
  adId: "ad-001",
  adSystem: "my-ad-server",
  customData: { customData1: "campaign-X" }
})
```

---

### `adBreakEnd()`

Signals the end of the current ad break and resets SSAI state back to IDLE.

```brightscript
m.collector.callFunc("adBreakEnd", invalid)
```

---

### `adQuartileFinished(adQuartile, adQuartileMetadata)`

Reports that an ad quartile milestone was reached. Each quartile can only be reported once per ad; duplicate calls are silently ignored.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adQuartile` | String | Yes | Quartile reached: `"first"`, `"midpoint"`, `"third"`, or `"completed"`. |
| `adQuartileMetadata` | AssociativeArray | No | Optional metadata for the quartile event. |
| `adQuartileMetadata.failedBeaconUrl` | String | No | URL of a beacon that failed to fire (truncated to 500 chars). |

```brightscript
m.collector.callFunc("adQuartileFinished", "midpoint", invalid)

' With failed beacon:
m.collector.callFunc("adQuartileFinished", "completed", { failedBeaconUrl: "https://..." })
```

---

## Live / Program Change

### `programChange(newSourceMetadata)`

> **THEO Player collector only.**

Reports a program change within a live stream. Finalizes the current impression, starts a new one, and applies updated metadata for the new program. If called before any source has been loaded (SETUP state), applies the metadata as a configuration update without starting a new impression.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `newSourceMetadata` | AssociativeArray | Yes | Metadata for the new program. Accepts all [AnalyticsConfig](#analyticsconfig) fields plus stream URL fields below. |
| `newSourceMetadata.mpdUrl` | String | No | DASH manifest URL (sets `streamFormat` to `"dash"`). |
| `newSourceMetadata.m3u8Url` | String | No | HLS manifest URL (sets `streamFormat` to `"hls"`). |
| `newSourceMetadata.progUrl` | String | No | Progressive video URL (sets `streamFormat` to `"progressive"`). |
| `newSourceMetadata.path` | String | No | Path to report for the stream. |

```brightscript
m.collector.callFunc("programChange", {
  title: "Evening News",
  videoId: "prog-news-2100",
  isLive: true,
  m3u8Url: "https://example.com/news.m3u8",
})
```
