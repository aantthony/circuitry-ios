uniform mat4 gridMatrix;
uniform mat4 modelViewProjectionMatrix;

attribute vec4 position;

void main()
{
    gl_Position = modelViewProjectionMatrix * gridMatrix * position;
}
