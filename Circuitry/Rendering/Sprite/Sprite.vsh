uniform mat4 modelViewProjectionMatrix;
uniform vec2 size;
uniform vec3 pos;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord0;

varying lowp vec2 vTexCoord0;
varying lowp vec4 vColor;

void main()
{
    vTexCoord0 = texCoord0;
    vColor = color;
    gl_Position = modelViewProjectionMatrix * (vec4(pos, 0.0) + position * vec4(size, 1.0, 1.0));
}
