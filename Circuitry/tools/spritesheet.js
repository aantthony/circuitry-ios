var fs = require('fs');
var Builder = require( 'node-spritesheet' ).Builder;

var path = process.argv[2];

//path = '/Users/anthony/Projects/circuitry/Circuitry/Circuitry/circuit.image-atlas';

var outputImage = process.argv[3] || 'output.png';

if (outputImage[0] != '/') outputImage = process.cwd() + '/' + outputImage;

var files = fs.readdirSync(path).filter(function (name) {
  return /\.png$/.test(name);
}).map(function (name) {
  return path + '/' + name;
});

var log = console.log;
console.log = console.error;

var builder = new Builder({
  outputDirectory: '/',
  outputImage: outputImage,
  outputCss: 'sprite.css',
  selector: '.sprite',
  images: files
});

builder.writeStyleSheet = function (callback) {
  callback();
};

builder.build( function() {
  if (builder.configs.length != 1) throw new Error('Wrong count');
  var images = builder.configs[0].images;

  var map = {};

  var out = images.map(function (image) {
    map[image.name] = {
      x: image.x,
      y: image.y,
      width: image.width,
      height: image.height
    };
  });
  process.stdout.write(JSON.stringify(map, null, 4));
});