uniform lowp vec4 color;

varying lowp vec2 vTexCoord0; // unit
void main()
{
    lowp vec2 d = vTexCoord0 - vec2(0.5,0.5);
    lowp float dist = length(d);
    lowp float m = dist < 0.5 ? 1.0 : 0.0;
    gl_FragColor = vec4(color.rgb, color.a * m);
    
}
