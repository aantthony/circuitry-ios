uniform mat4 modelViewProjectionMatrix;
uniform vec3 pos;
uniform float radius;

attribute vec4 position;      // unit
attribute vec2 texCoord0;     // unit

varying lowp vec2 vTexCoord0; // unit

void main()
{
    // lerp:
    vTexCoord0 = texCoord0;
    
    gl_Position = modelViewProjectionMatrix * (vec4(pos, 0.0) + position * vec4(radius * 2., radius * 2., 1.0, 1.0));
}
