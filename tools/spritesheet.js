var fs = require('fs');
var path = process.argv[2];

var outputImage = process.argv[3] || 'output.png';

if (outputImage[0] != '/') outputImage = process.cwd() + '/' + outputImage;

var spritesheet = require('spritesheet-js');

const outputPath = __dirname + '/tmp';

spritesheet(path + '/*.png', {format: 'json', powerOfTwo: true, padding: 1, path: outputPath}, function (err) {
  if (err) throw err;

  const res = JSON.parse(
    fs.readFileSync(outputPath + '/spritesheet.json', 'utf8')
  );

  fs.renameSync(outputPath + '/spritesheet.png', outputImage);

  var map = {};

  Object.keys(res.frames).map(function (fileName) {
    const image = res.frames[fileName];
    map[fileName] = {
      x: image.frame.x,
      y: image.frame.y,
      width: image.frame.w,
      height: image.frame.h
    };
  });
  process.stdout.write(JSON.stringify(map, null, 4));
});
