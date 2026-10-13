// .pragma library

function recordAccess(data, path) {
  if (!path) return data || {};
  var res = data ? JSON.parse(JSON.stringify(data)) : {};
  var entry = res[path] || { count: 0, lastAccess: 0 };
  entry.count = (entry.count || 0) + 1;
  entry.lastAccess = Date.now();
  res[path] = entry;
  return prune(res, 500);
}

function getScore(data, path) {
  if (!data || !path || !data[path]) return 0;
  var entry = data[path];
  var count = entry.count || 0;
  var last = entry.lastAccess || 0;
  var now = Date.now();
  var diffHours = (now - last) / (1000 * 60 * 60);

  var recencyBonus = 0;
  if (diffHours < 1) recencyBonus = 80;
  else if (diffHours < 24) recencyBonus = 50;
  else if (diffHours < 24 * 7) recencyBonus = 25;
  else if (diffHours < 24 * 30) recencyBonus = 10;

  var frequencyScore = Math.min(100, count * 5);
  return frequencyScore + recencyBonus;
}

function prune(data, maxEntries) {
  if (!data) return {};
  var limit = maxEntries || 500;
  var keys = Object.keys(data);
  if (keys.length <= limit) return data;

  // Sort by score descending
  keys.sort(function(a, b) {
    return getScore(data, b) - getScore(data, a);
  });

  var pruned = {};
  for (var i = 0; i < limit; i++) {
    pruned[keys[i]] = data[keys[i]];
  }
  return pruned;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    recordAccess: recordAccess,
    getScore: getScore,
    prune: prune
  };
}
