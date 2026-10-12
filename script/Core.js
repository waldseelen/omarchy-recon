// Core utility functions for omarchy-recon

function formatBytes(bytes) {
  var b = parseInt(bytes, 10);
  if (isNaN(b) || b <= 0) return "0 B";
  if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB";
  if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB";
  if (b >= 1024) return (b / 1024).toFixed(1) + " KB";
  return b + " B";
}

function getBaseName(path) {
  if (!path) return "";
  var s = String(path).replace(/\/+$/, "");
  var idx = s.lastIndexOf("/");
  return idx >= 0 ? s.substring(idx + 1) : s;
}

function getDirName(path) {
  if (!path) return "";
  var s = String(path).replace(/\/+$/, "");
  var idx = s.lastIndexOf("/");
  return idx >= 0 ? s.substring(0, idx) : "";
}

function getExtension(path) {
  var base = getBaseName(path);
  var idx = base.lastIndexOf(".");
  if (idx <= 0 || idx === base.length - 1) return "";
  return base.substring(idx + 1).toLowerCase();
}

function getTag(path, isDir) {
  if (isDir) return "DIR";
  var ext = getExtension(path);
  if (ext === "md" || ext === "txt" || ext === "org") return "DOC";
  if (ext === "pdf") return "PDF";
  if (ext === "json") return "JSON";
  if (/^(py|js|ts|m|sh|html|css|lua|c|cpp|rs|go|h)$/.test(ext)) return "CODE";
  if (/^(docx|doc|odt|xlsx|pptx|csv)$/.test(ext)) return "OFFICE";
  if (/^(png|jpg|jpeg|webp|gif|svg|bmp)$/.test(ext)) return "IMAGE";
  return "FILE";
}

function matchesTab(tag, tab) {
  if (tab === "all") return true;
  if (tab === "folders") return tag === "DIR";
  if (tab === "docs") return tag === "DOC" || tag === "PDF";
  if (tab === "code") return tag === "CODE" || tag === "JSON";
  if (tab === "pdf") return tag === "PDF";
  if (tab === "office") return tag === "OFFICE";
  if (tab === "images") return tag === "IMAGE";
  return true;
}

function collapsePath(path, home, targetDir) {
  if (!path) return "";
  if (targetDir && path.indexOf(targetDir) === 0) {
    var rel = path.substring(targetDir.length);
    return "SSS" + (rel.charAt(0) === "/" ? rel : "/" + rel);
  }
  if (home && path.indexOf(home) === 0) {
    return "~" + path.substring(home.length);
  }
  return path;
}
