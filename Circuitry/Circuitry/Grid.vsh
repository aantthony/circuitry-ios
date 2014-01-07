uniform mat4 gridMatrix;
uniform mat4 modelViewProjectionMatrix;

attribute vec3 position;

void main()
{
    gl_Position = modelViewProjectionMatrix * gridMatrix * vec4(position, 1.0);
}
