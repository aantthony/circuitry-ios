uniform sampler2D texture;
varying lowp vec2 vTexCoord0;

void main()
{
    gl_FragColor = texture2D(texture, vTexCoord0);
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
