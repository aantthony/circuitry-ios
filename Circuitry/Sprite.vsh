uniform mat4 modelViewProjectionMatrix;
//uniform vec2 size;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord0;

varying lowp vec2 vTexCoord0;
varying lowp vec4 vColor;

void main()
{
    vec2 size = vec2(1024.0, 768.0);
    vTexCoord0 = texCoord0;
    vColor = color;
    gl_Position = modelViewProjectionMatrix * (position * vec4(size, 1.0, 1.0));
}
