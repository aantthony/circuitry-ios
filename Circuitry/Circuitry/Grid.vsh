attribute vec4 position;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    // TODO: transform coordinates
    gl_Position = modelViewProjectionMatrix * position;
}
