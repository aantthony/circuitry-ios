var path = require('path');

var base = path.resolve(__dirname, '../Problems');
var list = require(base);

var all = list.problems.map(function (meta) {
  if (meta.hidden) return;
  var p = path.resolve(base, meta.path, 'package');
  var package = require(p);
  if (package.title !== meta.title) {
    throw new Error('Invalid name');
  }
  package.image = 'level-' + meta.path;
  package.name = meta.path;
  return package;
}).filter(Boolean);

console.log(JSON.stringify(all));