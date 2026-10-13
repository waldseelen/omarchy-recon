const assert = require('assert');
const Core = require('../script/Core.js');

console.log("Running Core tests...");

// Label derives from target dir name, not a hardcoded drive name.
assert.strictEqual(Core.collapsePath('/data/media/a', '/home/u', '/data/media'), 'media/a');
assert.strictEqual(Core.collapsePath('/data/media', '/home/u', '/data/media'), 'media/');
// Target equal to home collapses to ~.
assert.strictEqual(Core.collapsePath('/home/u/docs', '/home/u', '/home/u'), '~/docs');
// Prefix must end on a path boundary.
assert.strictEqual(Core.collapsePath('/data/media2/a', '/home/u', '/data/media'), '/data/media2/a');
// Home fallback and passthrough.
assert.strictEqual(Core.collapsePath('/home/u/x', '/home/u', '/data/media'), '~/x');
assert.strictEqual(Core.collapsePath('/etc/x', '/home/u', '/data/media'), '/etc/x');
assert.strictEqual(Core.collapsePath('', '/home/u', '/data/media'), '');
// No personal drive name leaks from source.
assert.ok(require('fs').readFileSync(__dirname + '/../script/Core.js', 'utf8').indexOf('SSS') === -1);

console.log("All Core tests passed.");
