import express = require('express');
import bodyParser = require('body-parser');

interface PoisonConfig {
  chunk: number;
  delay: number;
}

const toxy = require('toxy');
const { poisons, rules } = toxy;

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
  console.log('Updating poison config');
  console.log(config)
  proxy.flushPoisons();
  proxy.outgoingPoison(createPoison(config))
};

proxy.listen(8080);
// tslint:disable-next-line: no-console
console.log('Server listening on port:', 8080);


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
    console.log(error)
    res.sendStatus(400);
  }
});

app.listen(3000, () => {
  console.log('Example app listening on port 3000');
});
