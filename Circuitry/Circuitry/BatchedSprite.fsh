uniform sampler2D texture;
varying lowp vec2 vTexCoord0;
void main()
{
    gl_FragColor = texture2D(texture, vTexCoord0);
}
