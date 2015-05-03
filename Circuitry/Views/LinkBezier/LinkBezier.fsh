uniform lowp vec3 color1;
uniform lowp vec3 color2;

varying lowp float v;
void main()
{
    highp float vv = v - 0.1;
    gl_FragColor = vec4(mix(color2, color1, 1.5 * (vv - pow(1.15 * v, 20.0))), 1.0);
}
