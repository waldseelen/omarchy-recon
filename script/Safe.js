// Security helpers for omarchy-recon.
//
// Pure functions only (no Quickshell/QML dependencies) so they can be unit
// tested with node. Everything that turns user input, config values or file
// system names into shell input lives here.
//
// Rules enforced by this module:
//   * User-controlled strings (search query, paths) never appear in argv
//     (visible via /proc/<pid>/cmdline) when they may be secret: queries travel
//     through the process environment (/proc/<pid>/environ is owner-only).
//   * Shell scripts are constant strings; variable data arrives as positional
//     parameters or environment variables, never concatenated into script text.
//   * Every external tool gets `--` / `-e` before data so values starting with
//     "-" cannot become options (rg --pre, fd --exec, ...).
// .pragma library

function shellQuote(value) {
  return "'" + String(value === undefined || value === null ? "" : value).replace(/'/g, "'\\''") + "'";
}

function hasControlChars(s) {
  return /[\0\r\n]/.test(s);
}

// File extension usable in an exclude list: short, [a-z0-9_+-] only.
function sanitizeExt(ext) {
  var e = String(ext === undefined || ext === null ? "" : ext).trim().replace(/^\./, "").toLowerCase();
  return /^[a-z0-9_+\-]{1,16}$/.test(e) ? e : "";
}

// Directory name / glob usable in an exclude list. Quoted at use, so only
// control characters and absurd lengths are rejected.
function sanitizeDirName(name) {
  if (typeof name !== "string") return "";
  var n = name.trim();
  if (!n || n.length > 255 || hasControlChars(n)) return "";
  return n;
}

function isSafeAbsPath(p) {
  return typeof p === "string" && p.length > 0 && p.length < 4096 && p.charAt(0) === "/" && !hasControlChars(p);
}

// A single path component (rename target): no separators, no traversal.
function sanitizeEntryName(value) {
  if (typeof value !== "string") return "";
  var n = value.trim();
  if (!n || n === "." || n === ".." || n.length > 255) return "";
  if (n.indexOf("/") !== -1 || hasControlChars(n)) return "";
  return n;
}

// Relative path below a base dir (new file): no absolute paths, no "..".
function sanitizeRelPath(value) {
  if (typeof value !== "string") return "";
  var v = value.trim();
  if (!v || v.charAt(0) === "/" || v.charAt(v.length - 1) === "/" || v.length > 1024 || hasControlChars(v)) return "";
  var parts = v.split("/");
  var out = [];
  for (var i = 0; i < parts.length; i++) {
    var seg = parts[i];
    if (seg === "" || seg === ".") continue;
    if (seg === ".." || seg.length > 255) return "";
    out.push(seg);
  }
  return out.join("/");
}

function joinInside(base, rel) {
  return String(base).replace(/\/+$/, "") + "/" + rel;
}

// Validate untrusted config (recon.json): keep only well-formed fields.
function sanitizeConfig(data, current) {
  var cur = current || {};
  var out = {
    targetDir: cur.targetDir,
    excludeDirs: cur.excludeDirs,
    excludeExts: cur.excludeExts,
    excludeHidden: cur.excludeHidden
  };
  if (!data || typeof data !== "object") return out;
  if (isSafeAbsPath(data.targetDir)) out.targetDir = data.targetDir;
  if (Array.isArray(data.excludeDirs)) {
    out.excludeDirs = data.excludeDirs.map(sanitizeDirName).filter(function(x) { return x !== ""; });
  }
  if (Array.isArray(data.excludeExts)) {
    out.excludeExts = data.excludeExts.map(sanitizeExt).filter(function(x) { return x !== ""; });
  }
  if (typeof data.excludeHidden === "boolean") out.excludeHidden = data.excludeHidden;
  return out;
}

// ---- Sensitive file guard (preview / copy content / content search) ----
var SENSITIVE_PATTERNS = [
  /(^|\/)\.(ssh|gnupg|aws|kube|docker)(\/|$)/,
  /(^|\/)\.env(\..*)?$/i,
  /\.(pem|key|p12|pfx|kdbx)$/i,
  /(^|\/)id_(rsa|dsa|ecdsa|ed25519)$/,
  /(^|\/)(\.netrc|\.git-credentials|\.npmrc|\.pgpass)$/,
  /(^|\/)\.config\/(gh|glab-cli)\/hosts\.yml$/,
  /(^|\/)keyrings(\/|$)/
];

var SENSITIVE_RG_GLOBS = [
  "!**/.ssh/**", "!**/.gnupg/**", "!**/.aws/**", "!**/.kube/**", "!**/.docker/**",
  "!**/.env", "!**/.env.*", "!*.pem", "!*.key", "!*.p12", "!*.pfx", "!*.kdbx",
  "!**/id_rsa", "!**/id_dsa", "!**/id_ecdsa", "!**/id_ed25519",
  "!**/.netrc", "!**/.git-credentials", "!**/.npmrc", "!**/.pgpass"
];

function isSensitivePath(p) {
  var s = String(p === undefined || p === null ? "" : p);
  for (var i = 0; i < SENSITIVE_PATTERNS.length; i++) {
    if (SENSITIVE_PATTERNS[i].test(s)) return true;
  }
  return false;
}

// ---- Search command ----
// Returns { argv, env }. The script text is constant apart from validated,
// shell-quoted exclude flags; query and target arrive via the environment.
function buildSearch(opts) {
  var isRg = !!opts.isRg;
  var excludeDirs = opts.excludeDirs || [];
  var excludeExts = opts.excludeExts || [];
  var tab = opts.tab || "all";
  var q = String(opts.q === undefined || opts.q === null ? "" : opts.q);

  var excludeFlags = "";
  for (var i = 0; i < excludeDirs.length; i++) {
    var d = sanitizeDirName(excludeDirs[i]);
    if (!d) continue;
    excludeFlags += isRg ? " --glob " + shellQuote("!" + d + "/**") : " --exclude " + shellQuote(d);
  }
  for (var j = 0; j < excludeExts.length; j++) {
    var ext = sanitizeExt(excludeExts[j]);
    if (!ext) continue;
    excludeFlags += isRg ? " --glob " + shellQuote("!*." + ext) : " -E " + shellQuote("*." + ext);
  }

  var prelude = 't="$RECON_T"; case "$t" in /*) [ -d "$t" ] || t="$HOME" ;; *) t="$HOME" ;; esac; ';
  var script;

  if (isRg) {
    var globs = "";
    for (var g = 0; g < SENSITIVE_RG_GLOBS.length; g++) globs += " --glob " + shellQuote(SENSITIVE_RG_GLOBS[g]);
    script = prelude +
      "timeout 20 rg --no-config --color=never --no-heading --line-number --max-count=1 --smart-case" +
      " --max-filesize 5M --max-columns 300" +
      (opts.excludeHidden ? "" : " --hidden") + excludeFlags + globs +
      ' -e "$RECON_Q" -- "$t" 2>/dev/null | head -n 120';
  } else {
    var sub = opts.sub || "all";
    var s = sanitizeExt(sub);
    var typeFlags = "";
    if (tab === "folders") {
      typeFlags = "-t d";
    } else if (tab === "docs") {
      if (s === "md" || s === "pdf" || s === "txt" || s === "org") typeFlags = "-t f -e " + s;
      else typeFlags = "-t f -e md -e txt -e org -e pdf";
    } else if (tab === "code") {
      if (sub === "all") typeFlags = "-t f -e py -e js -e ts -e html -e css -e lua -e c -e cpp -e rs -e go -e json";
      else if (sub === "c") typeFlags = "-t f -e c -e cpp -e h -e hpp";
      else typeFlags = s ? "-t f -e " + s : "-t f";
    } else if (tab === "office") {
      if (sub === "all") typeFlags = "-t f -e docx -e doc -e odt -e xlsx -e pptx -e csv";
      else typeFlags = s ? "-t f -e " + s : "-t f";
    } else if (tab === "images") {
      if (sub === "all") typeFlags = "-t f -e png -e jpg -e jpeg -e webp -e gif -e svg";
      else if (sub === "jpg") typeFlags = "-t f -e jpg -e jpeg";
      else typeFlags = s ? "-t f -e " + s : "-t f";
    }
    script = prelude +
      "timeout 20 fd -i" + (opts.excludeHidden ? "" : " -H") + excludeFlags + " " + typeFlags +
      (q ? "" : " --max-depth 3") +
      ' -- "$RECON_Q" "$t" 2>/dev/null | head -n 250 | ' +
      "xargs -d '\\n' -r stat --printf='%F\\t%s\\t%n\\n' -- 2>/dev/null";
  }

  return {
    argv: ["bash", "-c", script, "recon-search"],
    env: { RECON_Q: q, RECON_T: String(opts.target === undefined || opts.target === null ? "" : opts.target) }
  };
}

// ---- Preview command ----
// Returns { argv, blocked }. Constant scripts; path / line range are
// positional parameters. Only regular, readable files are read, output is
// capped, and slow tools run under `timeout`.
function buildPreview(item) {
  var p = item && item.path;
  if (!isSafeAbsPath(p)) {
    return { argv: ["printf", "%s", "[Preview unavailable: invalid path]"], blocked: true };
  }
  if (!item.isDir && isSensitivePath(p)) {
    return { argv: ["printf", "%s", "[Preview hidden: sensitive file]"], blocked: true };
  }

  var script;
  var extra = [];
  if (item.isDir) {
    script = 'timeout 5 ls -1 -p -- "$1" 2>/dev/null | head -n 40';
  } else {
    var guard = 'if [ ! -f "$1" ]; then file -b -- "$1"; exit 0; fi; ' +
                'if [ ! -r "$1" ]; then echo "[not readable]"; exit 0; fi; ';
    if (item.tag === "PDF") {
      script = guard +
        'out=$(timeout 8 pdftotext -l 5 "$1" - 2>/dev/null | head -n 100); ' +
        'if [ -n "$out" ]; then printf "%s\\n" "$out"; else file -b -- "$1"; fi';
    } else if (item.tag === "MATCH" && item.sizeText && String(item.sizeText).charAt(0) === "L") {
      var lineNum = parseInt(String(item.sizeText).substring(1), 10) || 1;
      extra = [String(Math.max(1, lineNum - 12)), String(lineNum + 65)];
      script = guard + 'head -c 1048576 -- "$1" | sed -n "${2},${3}p"';
    } else {
      script = guard + 'head -c 65536 -- "$1" | head -n 250';
    }
  }
  return { argv: ["bash", "-c", script, "recon-preview", p].concat(extra), blocked: false };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    shellQuote: shellQuote,
    sanitizeExt: sanitizeExt,
    sanitizeDirName: sanitizeDirName,
    isSafeAbsPath: isSafeAbsPath,
    sanitizeEntryName: sanitizeEntryName,
    sanitizeRelPath: sanitizeRelPath,
    joinInside: joinInside,
    sanitizeConfig: sanitizeConfig,
    isSensitivePath: isSensitivePath,
    buildSearch: buildSearch,
    buildPreview: buildPreview
  };
}
