# [![bitmovin](http://bitmovin-a.akamaihd.net/webpages/bitmovin-logo-github.png)](http://www.bitmovin.com)
Roku client that allows you to monitor your Native ROKU or Bitmovin Player playback with [Bitmovin Analytics](https://bitmovin.com/video-analytics/)

# Getting started
## Manifest

In the `root` folder of your project find `manifest` file
 and add licence key for the Anlaytics:
```

# License key
bitmovin_analytics_license_key=INSERT-LICENSE-KEY-HERE
```

In order to obtain licence key please log into Bitmovin [dashboard](https://bitmovin.com/dashboard) with your Bitmovin account.
Once there, from dashboard side menu please select `Analytics` and then from  drop down menu pick `Licences`.
Here you will found your default licence named `default-licence`. You can also create new or edit curent licence.
Please copy/paste your licence to project `manifest` file as mentioned above.

## Native player collector

Bitmovin analytics collector for monitoring native ROKU player playback.

### Basic use

Please copy `collectorCore` and `nativePlayerCollector` folders into Your project.

In order to use the collector, first create a native player collector object:

```
m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with native player object send as an argument before content is set to ROKU native player:

```
m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
```

## Bitmovin player collector

Bitmovin analytics collector for monitoring Bitmovin player playback.

### Basic use

Please copy `collectorCore` and `bitmovinPlayerCollector` folders into Your project.

In order to use the collector, first create a Bitmovin player collector object:

```
m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with Bitmovin player object send as an argument before `setup` function is called on Bitmovin player.

```
m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
```

# Optional

Optionally you can call `setAnalyticsConfig` after creation of native or Bitmovin player collector object but prior to callng `initializePlayer` in order to
set custom initial data for the collector:

#### Native player collector

```
m.nativePlayerCollector.callFunc("setAnalyticsConfig", {customData1: "overlay-off"})
```

or

#### Bitmovin player collector

```
m.bitmovinPlayerCollector.callFunc("setAnalyticsConfig", {customData1: "overlay-off"})
```

## Optional Configuration Parameters

```
analyticsConfig = {
  videoId: "videoId1234",
  customUserId: "customUserId1",
  cdnProvider: "CDNProvider",
  experimentName: "experiment-1",
  customData1: customData1,
  customData2: customData2,
  customData3: customData3,
  customData4: customData4,
  customData5: customData5,
  heartbeatInterval: 59700 // value is in ms
}
```
