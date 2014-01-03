#version 130

uniform mat4 modelViewProjectionMatrix;

uniform vec2 A;
uniform vec2 B;

attribute int position;

varying lowp vec4 vColor;

/*
 
 From A -> B
 
 dx: B.x - A.x / 2
 
 a: A
 b: (A.x + dx, A.y)
 c: (B.x - dx, B.y)
 d: B

 */

vec2 unpacked (float t) {
    float dx = (B.x - A.x) / 2;
    float yT = mix(A.y, B.y, t);
    return mix(
        vec2(
            mix(A.x + dx * t, A.x + dx),
            mix(A.y, yT, t)
        ),
        mix(
            vec2(A.x + dx, yT),
            vec2(B.x + dx * (t - 1.0), B.y)
            t),               
        t
    );
}
vec2 lowp bezier(lowp vec2 a, lowp vec2 b, lowp vec2 c, lowp vec2 d, lowp float t) {
    return mix(
        mix(mix(a, b, t), mix(b, c, t),t),
        mix(mix(b, c, t), mix(c, d, t), t),
        t
    );
}

void main()
{
    vTexCoord0 = texCoord0;
    vColor = color;
    vec2 p = unpacked(position / 256.0);

    gl_Position = modelViewProjectionMatrix * vec4(p, 0.0, 1.0);
}
