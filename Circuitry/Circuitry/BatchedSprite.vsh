// #extension GL_EXT_gpu_shader4

uniform mat4 modelViewProjectionMatrix;

attribute vec4 position;
attribute vec2 texCoord0;

attribute vec2 translate;
attribute vec4 source;

varying lowp vec2 vTexCoord0;

void main()
{
    vTexCoord0 = source.xy + texCoord0;// * Not yet implemented;
    gl_Position = modelViewProjectionMatrix * vec4(translate + position.xy * source.zw, 0.0, 1.0);
}
