# Testing Utils

This project is used test the player/analytics behaviour under different network conditions on the fly. A [proxy](https://github.com/h2non/toxy) is used to intercept network requests to video streams available on our akamai net storage residing in the `content` folder.

## Setup

```bash
yarn install
yarn start
```

## Usage

1. Start the proxy with `yarn start`.
2. Replace the host of the stream that you want to play with the proxy's address. For example:

    `https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8` -> `http://192.168.0.150:8080/content/sintel/hls/playlist.m3u8`
3. Use the API provided by the testing-utils to change network conditions on the fly.

## API

A postman collection is available [here](testing-utils.postman_collection.json).

### Throttle Speed

Limit the bandwidth of the streams with following commands:

```bash
curl \
--location \
--request POST 'http://localhost:3000/throttle' \
--header 'Content-Type: application/json' \
--data-raw '{
    "bandwidth": 65536
}'
```

Good values for the parameter to see the player buffering are:
- 65536
- 16384

### Reset throttle

Removes throttling for stream requests and continues with normal speed.

```bash
curl --location --request GET 'http://localhost:3000/unthrottle'
```
