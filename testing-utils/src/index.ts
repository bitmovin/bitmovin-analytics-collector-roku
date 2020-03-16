import toxy = require('toxy');
import express = require('express');
import bodyParser = require('body-parser');

const PROXY_PORT = 8081;
const EXPRESS_PORT = 3000;

interface PoisonConfig {
  bandwidth: number;
}

const { poisons } = toxy;

// Create a new toxy proxy
const proxy = toxy();


proxy
  .get('/content/*')
  .forward('https://bitmovin-a.akamaihd.net');

proxy.listen(PROXY_PORT);
logInfo(`Server listening on port: ${PROXY_PORT}`);


const app = express();
app.use(proxy.middleware());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.post('/throttle', (req, res) => {
  try {
    const config: PoisonConfig = req.body;
    proxy.flushPoisons();
    proxy.poison(poisons.bandwidth(config.bandwidth));

    res.sendStatus(200);
  } catch (error) {
    logError(error);
    res.sendStatus(400);
  }
});

app.get('/unthrottle', (req, res) => {
  try {
    proxy.flushPoisons();

    res.sendStatus(200);
  } catch (error) {
    logError(error);
    res.sendStatus(400);
  }
});

app.listen(EXPRESS_PORT, () => {
  logInfo(`Example app listening on port ${EXPRESS_PORT}`);
});


function logError(msg: any) {
  // tslint:disable-next-line: no-console
  console.error(msg);
}

function logInfo(msg: any) {
  // tslint:disable-next-line: no-console
  console.info(msg);
}