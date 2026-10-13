const assert = require('assert');
const Fuzzy = require('../script/Fuzzy.js');

console.log("Running Fuzzy matching tests...");

// 1. Empty pattern matches with base score
const emptyMatch = Fuzzy.score('', 'anything.txt');
assert.ok(emptyMatch, 'Empty pattern should match');
assert.strictEqual(emptyMatch.score, 1);

// 2. Exact match scores very high
const exactMatch = Fuzzy.score('readme.md', 'readme.md');
assert.ok(exactMatch, 'Exact match should match');
assert.ok(exactMatch.score >= 100, 'Exact match score should be >= 100');

// 3. Typo/abbreviation match works
const abbrMatch = Fuzzy.score('scshot', 'screenshot_2026.png');
assert.ok(abbrMatch, 'Abbreviation should match');

// 4. Non-matching pattern returns null
const noMatch = Fuzzy.score('xyz', 'readme.md');
assert.strictEqual(noMatch, null, 'Non-matching pattern should return null');

// 5. Prefix match ranks higher than mid-string match
const prefixMatch = Fuzzy.score('doc', 'document.txt');
const midMatch = Fuzzy.score('doc', 'my_great_doc.txt');
assert.ok(prefixMatch.score > midMatch.score, 'Prefix match should rank higher than middle match');

// 6. Word boundary matches score bonus
const boundaryMatch = Fuzzy.score('rm', 'README.md');
assert.ok(boundaryMatch, 'Word boundary initials should match');

console.log("All Fuzzy matching tests passed successfully!");
