uniform sampler2D texture;

varying lowp vec2 vTexCoord0;
varying lowp vec4 vColor;

void main()
{
    gl_FragColor = vColor * texture2D(texture, vTexCoord0);
}
