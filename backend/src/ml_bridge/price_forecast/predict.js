/**
 * Naive stand-in for the trained LSTM/GRU price-forecast model described in
 * docs/MODEL_SPECS.md. Projects the next 7 days as the last known price
 * plus small random-walk noise — just enough for the UI to have real
 * "forecast" data to render before a trained model exists. Swap the body
 * of forecast() for an onnxruntime-node inference call; see README.md.
 */

function forecast(lastKnownPrice, days = 7) {
  const series = [];
  let price = lastKnownPrice;
  for (let i = 0; i < days; i++) {
    const drift = (Math.random() - 0.48) * price * 0.01; // slight upward bias, +/-1%
    price = Math.max(0, price + drift);
    series.push(Math.round(price * 100) / 100);
  }
  return series;
}

module.exports = { forecast };
