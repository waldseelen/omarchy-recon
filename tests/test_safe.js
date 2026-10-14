const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const cp = require('child_process');
const Safe = require('../script/Safe.js');

console.log("Running Safe (security) tests...");

// ---- sanitizeExt ----
assert.strictEqual(Safe.sanitizeExt('tmp'), 'tmp');
assert.strictEqual(Safe.sanitizeExt('.LOG'), 'log');
assert.strictEqual(Safe.sanitizeExt("x'; touch /tmp/pwn; '"), '');
assert.strictEqual(Safe.sanitizeExt('$(id)'), '');
assert.strictEqual(Safe.sanitizeExt('a b'), '');
assert.strictEqual(Safe.sanitizeExt(''), '');
assert.strictEqual(Safe.sanitizeExt('c++'), 'c++');

// ---- sanitizeDirName ----
assert.strictEqual(Safe.sanitizeDirName(' node_modules '), 'node_modules');
assert.strictEqual(Safe.sanitizeDirName('a\nb'), '');
assert.strictEqual(Safe.sanitizeDirName('a\0b'), '');
assert.strictEqual(Safe.sanitizeDirName(''), '');

// ---- isSafeAbsPath ----
assert.ok(Safe.isSafeAbsPath('/home/hp/x y'));
assert.ok(!Safe.isSafeAbsPath('relative/path'));
assert.ok(!Safe.isSafeAbsPath('-rf'));
assert.ok(!Safe.isSafeAbsPath('/a\nb'));
assert.ok(!Safe.isSafeAbsPath('/a\0b'));
assert.ok(!Safe.isSafeAbsPath(''));
assert.ok(!Safe.isSafeAbsPath(null));

// ---- sanitizeEntryName (rename) ----
assert.strictEqual(Safe.sanitizeEntryName(' notes.txt '), 'notes.txt');
assert.strictEqual(Safe.sanitizeEntryName('../x'), '');
assert.strictEqual(Safe.sanitizeEntryName('a/b'), '');
assert.strictEqual(Safe.sanitizeEntryName('..'), '');
assert.strictEqual(Safe.sanitizeEntryName('.'), '');
assert.strictEqual(Safe.sanitizeEntryName('a\nb'), '');
assert.strictEqual(Safe.sanitizeEntryName(''), '');

// ---- sanitizeRelPath (new file) ----
assert.strictEqual(Safe.sanitizeRelPath('a/b.txt'), 'a/b.txt');
assert.strictEqual(Safe.sanitizeRelPath('a//b.txt'), 'a/b.txt');
assert.strictEqual(Safe.sanitizeRelPath('./a.txt'), 'a.txt');
assert.strictEqual(Safe.sanitizeRelPath('../x'), '');
assert.strictEqual(Safe.sanitizeRelPath('a/../../x'), '');
assert.strictEqual(Safe.sanitizeRelPath('/etc/passwd'), '');
assert.strictEqual(Safe.sanitizeRelPath('a/'), '');
assert.strictEqual(Safe.sanitizeRelPath('a\nb'), '');

// ---- sanitizeConfig ----
var cfg = Safe.sanitizeConfig({
  targetDir: 'relative',
  excludeDirs: ['ok', 'bad\nname', 5],
  excludeExts: ['tmp', "x'; touch /tmp/pwn; '", '.BAK'],
  excludeHidden: 'yes'
}, { targetDir: '/home/u', excludeDirs: ['d'], excludeExts: ['e'], excludeHidden: true });
assert.strictEqual(cfg.targetDir, '/home/u');
assert.deepStrictEqual(cfg.excludeDirs, ['ok']);
assert.deepStrictEqual(cfg.excludeExts, ['tmp', 'bak']);
assert.strictEqual(cfg.excludeHidden, true);
assert.strictEqual(Safe.sanitizeConfig({ targetDir: '/data' }, { targetDir: '/home/u' }).targetDir, '/data');
assert.strictEqual(Safe.sanitizeConfig(null, { targetDir: '/home/u' }).targetDir, '/home/u');

// ---- isSensitivePath ----
['/home/u/.ssh/id_rsa', '/home/u/.gnupg/private-keys-v1.d/x', '/home/u/.aws/credentials',
 '/home/u/proj/.env', '/home/u/proj/.env.production', '/x/server.pem', '/x/tls.key',
 '/x/vault.kdbx', '/home/u/.netrc', '/home/u/.git-credentials', '/home/u/.config/gh/hosts.yml'
].forEach(function(p) { assert.ok(Safe.isSensitivePath(p), 'should be sensitive: ' + p); });
['/home/u/notes.md', '/home/u/environment.txt', '/home/u/keyboard.md', '/home/u/proj/env.js']
  .forEach(function(p) { assert.ok(!Safe.isSensitivePath(p), 'should not be sensitive: ' + p); });

// ---- buildSearch / buildPreview: integration against real bash/fd/rg ----
function have(bin) { return cp.spawnSync('bash', ['-c', 'command -v ' + bin]).status === 0; }

function run(built, timeoutMs) {
  var env = Object.assign({}, process.env, built.env || {});
  return cp.spawnSync(built.argv[0], built.argv.slice(1), { env: env, encoding: 'utf8', timeout: timeoutMs || 15000 });
}

var tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'recon-safe-'));
try {
  fs.writeFileSync(path.join(tmp, 'a.txt'), 'hello needle world\n');
  fs.writeFileSync(path.join(tmp, "-weird$(touch PWNED)'.txt"), 'needle in weird file\n');
  fs.writeFileSync(path.join(tmp, '.env'), 'needle=SECRET\n');
  fs.writeFileSync(path.join(tmp, 'big.txt'), 'x'.repeat(300000));

  var pwned = path.join(tmp, 'PWNED');
  var pwnedCwd = path.join(process.cwd(), 'PWNED');

  // Query never lands in argv; it travels via env.
  var q = '--pre=touch PWNED';
  var b = Safe.buildSearch({ isRg: true, q: q, target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' });
  assert.ok(JSON.stringify(b.argv).indexOf(q) === -1, 'query must not appear in argv');
  assert.strictEqual(b.env.RECON_Q, q);

  if (have('rg') && have('fd')) {
    // rg option injection must be inert.
    run(b);
    assert.ok(!fs.existsSync(pwnedCwd) && !fs.existsSync(pwned), 'rg --pre injection must not execute');

    // fd option injection must be inert.
    var fb = Safe.buildSearch({ isRg: false, q: '--exec=touch PWNED', target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' });
    run(fb);
    assert.ok(!fs.existsSync(pwnedCwd) && !fs.existsSync(pwned), 'fd --exec injection must not execute');

    // Content search finds file without exposing query on cmdline.
    var secretQuery = 'needle';
    var ok = run(Safe.buildSearch({ isRg: true, q: secretQuery, target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' }));
    assert.ok(ok.stdout.indexOf('a.txt:1:') !== -1, 'rg should find a.txt');
    // Sensitive files are skipped by content search even with hidden enabled.
    assert.ok(ok.stdout.indexOf('.env') === -1, 'rg must skip .env');

    // Unclosed regex bracket falls back safely to literal fixed string search.
    fs.writeFileSync(path.join(tmp, 'bracket[1].txt'), 'bracket[1] content here\n');
    var bq = run(Safe.buildSearch({ isRg: true, q: 'bracket[1]', target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' }));
    assert.ok(bq.stdout.indexOf('bracket[1].txt:1:') !== -1, 'rg fallback should find literal bracket[1]');

    var fbq = run(Safe.buildSearch({ isRg: false, q: 'bracket[1]', target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' }));
    assert.ok(fbq.stdout.indexOf('bracket[1].txt') !== -1, 'fd search should find literal bracket[1]');

    // Malicious extension in exclude list is dropped, never executed.
    var eb = Safe.buildSearch({ isRg: false, q: 'a.txt', target: tmp, excludeDirs: ["x'; touch PWNED; '"], excludeExts: ["x'; touch PWNED; '"], excludeHidden: true, tab: 'all', sub: 'all' });
    var er = run(eb);
    assert.ok(!fs.existsSync(pwnedCwd) && !fs.existsSync(pwned), 'ext/dir injection must not execute');
    assert.ok(er.stdout.indexOf('regular file\t') === 0 || er.stdout.indexOf('regular file') !== -1, 'fd+stat output format');
    assert.ok(er.stdout.indexOf(path.join(tmp, 'a.txt')) !== -1, 'fd should find a.txt');

    // Weird filename survives with leading dash and shell metachars.
    var wr = run(Safe.buildSearch({ isRg: false, q: 'weird', target: tmp, excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' }));
    assert.ok(wr.stdout.indexOf("weird$(touch PWNED)'.txt") !== -1, 'weird filename listed');
    assert.ok(!fs.existsSync(pwnedCwd) && !fs.existsSync(pwned));

    // Relative / non-directory target falls back to $HOME instead of option injection.
    var rb = Safe.buildSearch({ isRg: false, q: 'a.txt', target: '-x', excludeDirs: [], excludeExts: [], excludeHidden: false, tab: 'all', sub: 'all' });
    rb.env.HOME = tmp;
    var rr = run(rb);
    assert.ok(rr.status !== null && rr.stdout.indexOf(path.join(tmp, 'a.txt')) !== -1, 'relative target falls back to $HOME');
  }

  // Preview: regular file is capped, FIFO does not hang, weird name is literal.
  var big = run(Safe.buildPreview({ path: path.join(tmp, 'big.txt'), isDir: false, tag: 'FILE', sizeText: '300 KB' }));
  assert.ok(big.stdout.length <= 65536 + 1, 'preview capped to 64 KiB, got ' + big.stdout.length);

  var fifo = path.join(tmp, 'pipe');
  cp.spawnSync('mkfifo', [fifo]);
  var t0 = Date.now();
  var fr = run(Safe.buildPreview({ path: fifo, isDir: false, tag: 'FILE', sizeText: '0 B' }), 8000);
  assert.ok(fr.status !== null && Date.now() - t0 < 7000, 'FIFO preview must not hang');

  var wp = run(Safe.buildPreview({ path: path.join(tmp, "-weird$(touch PWNED)'.txt"), isDir: false, tag: 'FILE', sizeText: '1 B' }));
  assert.ok(wp.stdout.indexOf('needle in weird file') !== -1, 'weird filename previews literally');
  assert.ok(!fs.existsSync(pwnedCwd) && !fs.existsSync(pwned));

  var dp = run(Safe.buildPreview({ path: tmp, isDir: true, tag: 'DIR', sizeText: 'DIR' }));
  assert.ok(dp.stdout.indexOf('a.txt') !== -1, 'dir preview lists entries');

  var sp = Safe.buildPreview({ path: path.join(tmp, '.env'), isDir: false, tag: 'FILE', sizeText: '1 B' }, tmp);
  assert.ok(sp.blocked === true, 'sensitive preview must be blocked');
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
  try { fs.rmSync(path.join(process.cwd(), 'PWNED')); } catch (e) {}
}

console.log("All Safe tests passed.");
