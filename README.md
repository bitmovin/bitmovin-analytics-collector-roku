# [![bitmovin](http://bitmovin-a.akamaihd.net/webpages/bitmovin-logo-github.png)](http://www.bitmovin.com)

Roku client that allows you to monitor your Native ROKU or Bitmovin Player playback with [Bitmovin Analytics](https://bitmovin.com/video-analytics)

## Getting started

### Analytics license setup

Choose a Bitmovin Analytics license from the [Bitmovin dashboard](https://bitmovin.com/dashboard/analytics/licenses).
Make sure that Your domain (channel id) is in the allow-list and postfixed with `.roku`.
During local development the domain will be `dev.roku`.
A random channel id will be assigned once your channel is released. Update the allow-list in the dashboard accordingly.
This step is essential to enable analytics data collection.

Configure the license key in the `manifest` file located in the root folder of the project:

```bash
# Analytics license key
bitmovin_analytics_license_key=INSERT_LICENSE_KEY_HERE
```

Or set it in the Bitmovin Analytics configuration object:

```javascript
analyticsConfig = {
  key: "INSERT_LICENSE_KEY_HERE",
  title: "Your Video Title",
  videoId: "your-video-id",
}
```

## Bitmovin player collector

Bitmovin analytics collector for monitoring Bitmovin player playback.

### Basic use

Copy `collectorCore` and `bitmovinPlayerCollector` folders into Your project.

In order to use the collector, first create a Bitmovin player collector object:

```javascript
m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")
```

To set up Bitmovin Analytics and start monitoring the player, call `initializeAnalytics` with the analytics configuration, and then the `initializePlayer` with the Bitmovin player object as an argument.
This must happen before the `setup` function is called on the Bitmovin player.

```javascript
m.bitmovinPlayerCollector.callFunc("initializeAnalytics", analyticsConfig)
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

To set up Bitmovin Analytics and start monitoring the player, call `initializeAnalytics` with the analytics configuration, and then the `initializePlayer` with the native player object as an argument.
This must happen before any content is set on the ROKU native player:

```javascript
m.nativePlayerCollector.callFunc("initializeAnalytics", analyticsConfig)
m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
```

## Optional configuration parameters for Bitmovin Analytics

Several other fields can be added to the Bitmovin Analytics configuration in order to improve data collection:

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

## Support

If you have any questions or issues with this Analytics Collector or its examples, or you require other technical support for our services, please login to your Bitmovin Dashboard at https://bitmovin.com/dashboard and create a new support case. Our team will get back to you as soon as possible 👍
