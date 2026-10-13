// .pragma library

function isWordBoundary(charBefore) {
  return charBefore === '/' || charBefore === '_' || charBefore === '-' || charBefore === '.' || charBefore === ' ';
}

function isUpper(char) {
  return char >= 'A' && char <= 'Z';
}

function score(pattern, text) {
  if (!pattern) return { score: 1, matches: [] };
  if (!text) return null;

  var pLen = pattern.length;
  var tLen = text.length;
  if (pLen > tLen) return null;

  var pLower = pattern.toLowerCase();
  var tLower = text.toLowerCase();

  var pIdx = 0;
  var tIdx = 0;
  var matches = [];
  var scoreVal = 0;
  var prevMatchIdx = -2;

  while (pIdx < pLen && tIdx < tLen) {
    var pChar = pLower[pIdx];
    var tChar = tLower[tIdx];

    if (pChar === tChar) {
      matches.push(tIdx);

      var charScore = 10;

      // 1. Prefix match bonus
      if (tIdx === 0) {
        charScore += 60;
      } else if (isWordBoundary(text[tIdx - 1])) {
        // 2. Word boundary bonus
        charScore += 40;
      } else if (isUpper(text[tIdx]) && !isUpper(text[tIdx - 1])) {
        // 3. CamelCase bonus
        charScore += 30;
      }

      // 4. Consecutive match bonus
      if (tIdx === prevMatchIdx + 1) {
        charScore += 25;
      }

      scoreVal += charScore;
      prevMatchIdx = tIdx;
      pIdx++;
    }
    tIdx++;
  }

  // If pattern was not fully matched
  if (pIdx < pLen) {
    return null;
  }

  // Exact match bonus
  if (pLen === tLen) {
    scoreVal += 100;
  }

  // Length difference penalty to prefer tighter matches
  scoreVal -= Math.min(30, (tLen - pLen) * 0.5);

  return {
    score: Math.max(1, Math.round(scoreVal)),
    matches: matches
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { score: score };
}
