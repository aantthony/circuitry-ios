uniform lowp vec3 color1;
uniform lowp vec3 color2;

varying lowp float v;
void main()
{
    lowp float x = 1.5 * (v - 0.1 - pow(1.15 * v, 20.0));
    gl_FragColor = vec4(mix(color2, color1, x), 1.0);
}
