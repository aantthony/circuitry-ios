uniform mat4 modelViewProjectionMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord0;

varying lowp vec2 vTexCoord0;
varying lowp vec4 vColor;

void main()
{
    vTexCoord0 = texCoord0;
    vColor = color;
    gl_Position = modelViewProjectionMatrix * position;
}
