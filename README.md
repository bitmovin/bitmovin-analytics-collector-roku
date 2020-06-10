# [![bitmovin](http://bitmovin-a.akamaihd.net/webpages/bitmovin-logo-github.png)](http://www.bitmovin.com)

Roku client that allows you to monitor your Native ROKU or Bitmovin Player playback with [Bitmovin Analytics](https://bitmovin.com/video-analytics)

## Getting started

### Manifest

In the `root` folder of your project find the `manifest` file
and add licence key for the Analytics:

```bash
# Analytics license key
bitmovin_analytics_license_key=INSERT_LICENSE_KEY_HERE
```

In order to obtain a license key please log into [Bitmovin dashboard](https://bitmovin.com/dashboard) with your account.
Once there, navigate from the dashboard side bar to `Analytics` and select `Licenses`.
Choose the one you want from the list and copy/paste the `licenseKey` to the `manifest` file as mentioned above.

### Analytics License setup

After choosing the license, make sure that your domain -- the value of `appInfo.getID()` -- is whitelisted. During local development the domain will be `dev`. A random channel id will be assigned once your channel is released. Update the whitelist accordingly. This step is essential to enable analytics data collection.

## Bitmovin player collector

Bitmovin analytics collector for monitoring Bitmovin player playback.

### Basic use

Copy `collectorCore` and `bitmovinPlayerCollector` folders into Your project.

In order to use the collector, first create a Bitmovin player collector object:

```javascript
m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with Bitmovin player object as an argument before `setup` function is called on the Bitmovin player.

```javascript
m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
```

## Native player collector

Bitmovin analytics collector for monitoring native ROKU player playback.

### Basic use

Copy `collectorCore` and `nativePlayerCollector` folders into Your project.

In order to use the collector, first create a native player collector object:

```javascript
m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
```

To start monitoring the player, `initializePlayer` function must be called with native player object send as an argument before content is set to ROKU native player:

```javascript
m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
```

## Optional

To improve analytics data collection, call `setAnalyticsConfig` before the `initializePlayer` of the adapters. Here you can set additional information like, video title, custom data and so on.
See the example below for a full setup:

### Bitmovin player collector

```javascript
analyticsConfig = {
  isLive: false,
  title: "Art of Motion",
  videoId: "ArtOfMotion",
  customUserId: "John Doe",
  customData1: "overlay-off",
  experimentName: "myTestExperiment"
}
m.bitmovinPlayerCollector.callFunc("setAnalyticsConfig", analyticsConfig)
m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
```

### Native player collector

```javascript
analyticsConfig = {
  isLive: false,
  title: "Art of Motion",
  videoId: "ArtOfMotion",
  customUserId: "John Doe",
  customData1: "overlay-off",
  experimentName: "myTestExperiment"
}
m.nativePlayerCollector.callFunc("setAnalyticsConfig", analyticsConfig)
m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
```

## Optional Configuration Parameters

```javascript
analyticsConfig = {
  videoId: "videoId1234",
  customUserId: "customUserId1",
  cdnProvider: "CDNProvider",
  experimentName: "experiment-1",
  customData1: "customData1",
  customData2: "customData2",
  customData3: "customData3",
  customData4: "customData4",
  customData5: "customData5",
  heartbeatInterval: 59700, // value is in ms
}
```

## Development

### How to run the tests

If you have not done so, do an `npm install` at this point. This will also install the `Rooibos-cli` preprocessor.
Rooibos-cli is a preprocessor tool that rooibos unit testing framework use in order to preprocess the files needed to run the tests.

Next step is copying of `collectorCore`, `nativePlayerCollector` and `bitmovinPlayerCollector` into `testing` folder. You can do this by running the `npm run refresh-collectors` command.

Before the tests can run successfully we should add our device ip and developer password to the `package.json` file in `run-tests` script. In order to do this, please change the values for `ROKU_DEV_TARGET` and `DEVPASSWORD` to your device ip address and to your developer password.

The last step is running the tests. We should position ourselves to root of the repository and run the following command:

```bash
npm run run-tests
```

## VSCode IDE Brightscript Setup

Please install `vscode-ide-brightscript` package using `VSCode` package manager in order to have out of the box support for:

- On the fly linting and error checking
- Code snippets for common statements (`if`, `for`, `while`, `function`)
- Code region folding

### Wist Linter

Wist linter is included in the `vscode-ide-brightscript` package.
Wist linter rules can be edited by updating rules from `.wistrc.json` file which is added to the root folder of the repository.
Full list of supported rules can be found [here](https://willowtreeapps.github.io/wist/user-guide/rules/).
