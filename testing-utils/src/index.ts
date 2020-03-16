import toxy = require('toxy');
import express = require('express');
import bodyParser = require('body-parser');

const PROXY_PORT = 8081;
const EXPRESS_PORT = 3000;

interface PoisonConfig {
  chunk: number;
  delay: number;
}

const { poisons } = toxy;

// Create a new toxy proxy
const proxy = toxy();

const createPoison = (config: PoisonConfig) => {
  return poisons.throttle({ chunk: config.chunk, delay: config.delay })
};

proxy
  .get('/content/*')
  .forward('https://bitmovin-a.akamaihd.net')
  .outgoingPoison(createPoison({ chunk: 1024, delay: 1000 }));

const updatePoisions = (config: { chunk: number, delay: number }) => {
  logInfo('Updating poison config');
  logInfo(config)
  proxy.flushPoisons();
  proxy.outgoingPoison(createPoison(config))
};

proxy.listen(PROXY_PORT);
logInfo(`Server listening on port: ${PROXY_PORT}`);


const app = express();
app.use(proxy.middleware());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.post('/throttle', (req, res) => {
  try {
    const config: PoisonConfig = req.body;
    updatePoisions(config);
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