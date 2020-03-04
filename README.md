# [![bitmovin](http://bitmovin-a.akamaihd.net/webpages/bitmovin-logo-github.png)](http://www.bitmovin.com)

Roku client that allows you to monitor your Native ROKU or Bitmovin Player playback with [Bitmovin Analytics](https://bitmovin.com/video-analytics/)

## Getting started

### Manifest

In the `root` folder of your project find `manifest` file
and add licence key for the Analytics:

```bash
# License key
bitmovin_analytics_license_key=INSERT_LICENSE_KEY_HERE
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

```javascript
m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with native player object send as an argument before content is set to ROKU native player:

```javascript
m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
```

## Bitmovin player collector

Bitmovin analytics collector for monitoring Bitmovin player playback.

### Basic use

Please copy `collectorCore` and `bitmovinPlayerCollector` folders into Your project.

In order to use the collector, first create a Bitmovin player collector object:

```javascript
m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with Bitmovin player object send as an argument before `setup` function is called on Bitmovin player.

```javascript
m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
```

## Optional

Optionally you can call `setAnalyticsConfig` after creation of native or Bitmovin player collector object but prior to calling `initializePlayer` in order to
set custom initial data for the collector:

### Native player collector

```javascript
m.nativePlayerCollector.callFunc("setAnalyticsConfig", {customData1: "overlay-off"})
```

### Bitmovin player collector

```javascript
m.bitmovinPlayerCollector.callFunc("setAnalyticsConfig", {customData1: "overlay-off"})
```

## Optional Configuration Parameters

```json
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

## Testing

### How to run the tests

If you have not done so, do an `npm install` at this point. This will also install the `Rooibos-cli` preprocessor.
Rooibos-cli is a preprocessor tool that rooibos unit testing framework use in order to preprocess the files needed to run the tests.

Next step is copying of `collectorCore`, `nativePlayerCollector` and `bitmovinPlayerCollector` into `testing` folder. You can do this by running the `npm run refresh-collectors` command.

After appropriate folders are copied to `testing` folder but before we can run the tests successfully we should add our device ip and developer password to the `package.json` file in `run-tests` script. In order to do this, please change the values for `ROKU_DEV_TARGET` and `DEVPASSWORD` to your device ip address and to your developer password.

The last step is running the tests. We should position ourselves to root of the repository and run the following command:
`npm run run-tests`.
