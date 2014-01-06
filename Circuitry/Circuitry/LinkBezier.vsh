uniform mat4 modelViewProjectionMatrix;

uniform vec2 A;
uniform vec2 B;

attribute float position;

varying lowp float v;

/*
 
 From A -> B
 
 dx: B.x - A.x / 2
 
 a: A
 b: (A.x + dx, A.y)
 c: (B.x - dx, B.y)
 d: B

 */

vec2 unpacked (float t) {
    float dx = (B.x - A.x) / 2.0;
    float yT = mix(A.y, B.y, t);
    return mix(
        vec2(
            mix(A.x + dx * t, A.x + dx, t),
            mix(A.y, yT, t)
        ),
        mix(
            vec2(A.x + dx, yT),
            vec2(B.x + dx * (t - 1.0), B.y),
            t),   
        t
    );
}
vec2 bezier(vec2 a, vec2 b, vec2 c, vec2 d, float t) {
    return mix(
        mix(mix(a, b, t), mix(b, c, t),t),
        mix(mix(b, c, t), mix(c, d, t), t),
        t
    );
}


float dx = (B.x - A.x) / 2.0;

#define NVERTSM2 62.0

void main()
{
    v = 0.0;
    float rem = mod(position, 2.0);
    float displacement = (rem >= 1.0) ? 1.0 : -1.0;
    v = max(displacement, 0.0);
    float t = (position - rem) / NVERTSM2;
    vec2 z = bezier(A, vec2(A.x + dx, A.y), vec2(A.x + dx, B.y), B, t);
    vec2 dz = 5.0 * displacement * normalize(z - bezier(A, vec2(A.x + dx, A.y), vec2(A.x + dx, B.y), B, t - 1.0 / NVERTSM2));
    
    gl_Position = modelViewProjectionMatrix * vec4(z + vec2(dz.y, -dz.x), 0.0, 1.0);
}
