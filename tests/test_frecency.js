const assert = require('assert');
const Frecency = require('../script/Frecency.js');

console.log("Running Frecency tests...");

let data = {};

// 1. Initial access records count 1 and timestamp
data = Frecency.recordAccess(data, '/test/doc.md');
assert.ok(data['/test/doc.md'], 'Path should be recorded');
assert.strictEqual(data['/test/doc.md'].count, 1, 'Initial count should be 1');

// 2. Score increases on multiple accesses
data = Frecency.recordAccess(data, '/test/doc.md');
assert.strictEqual(data['/test/doc.md'].count, 2, 'Count should increment to 2');

const score = Frecency.getScore(data, '/test/doc.md');
assert.ok(score > 50, 'Recent and accessed file should score > 50');

// 3. Unknown path returns 0 score
const unknownScore = Frecency.getScore(data, '/unknown/path.txt');
assert.strictEqual(unknownScore, 0, 'Unknown path score should be 0');

// 4. Prune keeps entries bounded
let bigData = {};
for (let i = 0; i < 600; i++) {
  bigData[`/path/file_${i}.txt`] = { count: 1, lastAccess: Date.now() - i * 1000 };
}
const pruned = Frecency.prune(bigData, 500);
assert.strictEqual(Object.keys(pruned).length, 500, 'Pruning should cap entries at 500');

// 5. Remove access deletes entry
data = Frecency.removeAccess(data, '/test/doc.md');
assert.strictEqual(data['/test/doc.md'], undefined, 'Removed path should not exist');
assert.strictEqual(Frecency.getScore(data, '/test/doc.md'), 0, 'Removed path score should be 0');

// 6. Rename access moves entry to new key
data = Frecency.recordAccess(data, '/test/old.md');
const oldScore = Frecency.getScore(data, '/test/old.md');
data = Frecency.renameAccess(data, '/test/old.md', '/test/new.md');
assert.strictEqual(data['/test/old.md'], undefined, 'Old path should be removed');
assert.strictEqual(Frecency.getScore(data, '/test/new.md'), oldScore, 'New path should inherit score');

console.log("All Frecency tests passed successfully!");
