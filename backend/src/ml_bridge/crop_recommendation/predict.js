/**
 * Rule-based stand-in for the trained RandomForest+XGBoost ensemble
 * described in docs/MODEL_SPECS.md. Same input/output shape the real
 * model must produce — swap the body of predict() for a call into
 * model.onnx via onnxruntime-node and nothing else in the app needs to
 * change. See README.md in this directory for the exact contract.
 */

const CROP_PROFILES = [
  { name: 'Rice', n: [80, 120], p: [40, 60], k: [40, 60], ph: [5.5, 7] },
  { name: 'Wheat', n: [100, 140], p: [50, 70], k: [40, 60], ph: [6, 7.5] },
  { name: 'Maize', n: [100, 140], p: [50, 70], k: [40, 60], ph: [5.5, 7.5] },
  { name: 'Cotton', n: [80, 120], p: [40, 60], k: [40, 60], ph: [6, 8] },
  { name: 'Mustard', n: [60, 100], p: [30, 50], k: [30, 50], ph: [6, 7.5] },
  { name: 'Potato', n: [100, 150], p: [60, 90], k: [100, 150], ph: [5, 6.5] },
  { name: 'Tomato', n: [100, 150], p: [60, 90], k: [100, 150], ph: [6, 7] },
  { name: 'Soybean', n: [20, 40], p: [40, 60], k: [40, 60], ph: [6, 7.5] },
];

function scoreRange(value, [min, max]) {
  if (value >= min && value <= max) return 1;
  const span = max - min || 1;
  const distance = value < min ? min - value : value - max;
  return Math.max(0, 1 - distance / span);
}

function buildNutrientAdvice(soil) {
  const advice = [];
  if (soil.nitrogen < 80) advice.push('Nitrogen looks low — consider applying urea (~50kg/acre).');
  if (soil.phosphorus < 40) advice.push('Phosphorus looks low — consider applying DAP (~40kg/acre).');
  if (soil.potassium < 40) advice.push('Potassium looks low — consider applying MOP (~30kg/acre).');
  if (soil.ph < 5.5) advice.push('Soil is acidic — consider liming to raise pH.');
  if (soil.ph > 8) advice.push('Soil is alkaline — consider gypsum application.');
  if (soil.organicCarbon < 0.5) advice.push('Organic carbon is low — add farmyard manure or compost.');
  if (advice.length === 0) advice.push('Soil nutrient levels look balanced for most crops.');
  return advice;
}

function predict(soil) {
  const scored = CROP_PROFILES.map((crop) => ({
    cropName: crop.name,
    suitabilityScore:
      Math.round(
        ((scoreRange(soil.nitrogen, crop.n) +
          scoreRange(soil.phosphorus, crop.p) +
          scoreRange(soil.potassium, crop.k) +
          scoreRange(soil.ph, crop.ph)) /
          4) *
          100
      ) / 100,
  }));

  scored.sort((a, b) => b.suitabilityScore - a.suitabilityScore);
  const top = scored.slice(0, 5);
  const nutrientAdvice = buildNutrientAdvice(soil);

  return top.map((item, index) => ({
    ...item,
    nutrientAdvice: index === 0 ? nutrientAdvice : [],
  }));
}

module.exports = { predict };
