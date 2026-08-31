const express = require('express');
const faq = require('../assistant_faq.json');

const router = express.Router();

const FALLBACK_ANSWER =
  "I don't have a good answer for that yet. Try asking about crop calendar, " +
  'MSP, pests, fertilizer, irrigation, ordering, or your local Krishi Vigyan Kendra.';

/**
 * Mock RAG: keyword match against the same curated FAQ content the app
 * bundles for its offline fallback (see docs/MODEL_SPECS.md — AI Assistant
 * section). Swap the body of this handler for a real retrieval step
 * (vector search over crop calendars / pest guides / scheme info) feeding
 * an LLM call once you're ready to wire one in; the request/response shape
 * below is what the Flutter app already expects, so nothing else changes.
 */
router.post('/query', (req, res) => {
  const query = (req.body.query || '').toLowerCase();
  const match = faq.find((entry) => entry.keywords.some((k) => query.includes(k.toLowerCase())));
  res.json({ answer: match ? match.answer : FALLBACK_ANSWER });
});

module.exports = router;
