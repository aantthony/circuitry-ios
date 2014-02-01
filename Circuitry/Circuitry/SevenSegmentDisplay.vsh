uniform mat4 modelViewProjectionMatrix;
uniform vec2 size;
uniform vec3 pos;
uniform vec4 source;

uniform int data;

attribute vec4 position;
attribute vec2 texCoord0;

varying lowp vec2 vTexCoord0;

void main()
{
    vec2 unitSize = source.zw / vec2(16.0, 8.0);
    float fdata = float(data);
    vec2 dcomp = vec2((mod(fdata, 16.0)), floor(fdata / 16.0));
    
    vec4 sloc = vec4(source.xy + dcomp * unitSize, unitSize);
    vTexCoord0 = sloc.xy + texCoord0 * sloc.zw;
    gl_Position = modelViewProjectionMatrix * (vec4(pos, 0.0) + position * vec4(size, 1.0, 1.0));
}
