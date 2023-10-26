#version 330
#include hd_sdf.glsl
layout (location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform int u_frame_n;

const int MAX_REF = 100;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float EPSILON = 0.001;
const float MAX_DIST = 32;

float lastRand = length(gl_FragCoord)/u_time;

float random() {
    vec2 st = vec2(lastRand);
    float rand = fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
    lastRand = rand;
    return 1.0 - 2.0 * rand;
}

mat3 getMatRot(float w) {
    float sinA = random() * w;
    float cosA = 1.0 - sinA * sinA;
    float sinB = random() * w;
    float cosB = 1.0 - sinB * sinB;
    float sinC = random() * w;
    float cosC = 1.0 - sinC * sinC;
    
    vec3 row1 = vec3(cosB*cosC, sinA*sinB*cosC + sinC*cosA, sinA*sinC - sinB*cosA*cosC);
    vec3 row2 = vec3(-sinC*cosB, -sinA*sinB*sinC + cosA*cosC, sinA*cosC + sinB*sinC*cosA);
    vec3 row3 = vec3(sinB, -sinA*cosB, cosA*cosB);

    return mat3(row1, row2, row3);
}

vec2 fOpUnionId(vec2 a, vec2 b) {
    return (a.x < b.x) ? a : b;
}

vec2 map(in vec3 p) {
    vec2 res;

    float plane1Dist = fPlane(p, vec3(0., 1., 0.), 1.0);
    float plane1Id = 1.0;
    vec2 plane1 = vec2(plane1Dist, plane1Id);

    float plane2Dist = fPlane(p, vec3(1., 0., 0.), 5.0);
    float plane2Id = 5.0;
    vec2 plane2 = vec2(plane2Dist, plane2Id);

    float plane3Dist = fPlane(p, vec3(-1., 0., 0.), 5.0);
    float plane3Id = 5.0;
    vec2 plane3 = vec2(plane3Dist, plane3Id);

    float plane4Dist = fPlane(p, vec3(0., -1., 0.), 10.0);
    float plane4Id = 6.0;
    vec2 plane4 = vec2(plane4Dist, plane4Id);

    float plane5Dist = fPlane(p, vec3(0., 0., -1.), 5.0);
    float plane5Id = 5.0;
    vec2 plane5 = vec2(plane5Dist, plane5Id);

    float sphere1Dist = fSphere(p + vec3(0., 0., 0.), 1.0);
    float sphere1Id = 2.0;
    vec2 sphere1 = vec2(sphere1Dist, sphere1Id);

    float sphere2Dist = fSphere(p + vec3(-3., 0., .65), 1.0);
    float sphere2Id = 3.0;
    vec2 sphere2 = vec2(sphere2Dist, sphere2Id);

    float sphere3Dist = fSphere(p + vec3(3., 0., 1.72), 1.0);
    float sphere3Id = 4.0;
    vec2 sphere3 = vec2(sphere3Dist, sphere3Id);

    float box1Dist = fBoxCheap(p + vec3(0., 0., -2.), vec3(1.0));
    float box1Id = 2.0;
    vec2 box1 = vec2(box1Dist, box1Id);

    res = sphere1;
    //res = plane1;
    res = fOpUnionId(res, plane1);
    res = fOpUnionId(res, plane2);
    res = fOpUnionId(res, plane3);
    res = fOpUnionId(res, plane4);
    res = fOpUnionId(res, plane5);
    //res = fOpUnionId(res, sphere2);
    //res = fOpUnionId(res, sphere3);

    return res;
}

vec2 rayMarch(vec3 ro, vec3 rd) {
    vec2 hit, object = vec2(0.0);
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.y = hit.y;
        if (abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
    }
    return object;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
    return normalize(n);
}

vec4 getColor(vec3 p, float id) {
    switch (int(id)) {
        case 0:
        return vec4(0.0);
        case 1:
        return vec4(vec3(0.4 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)), .5);
        case 2:
        return vec4(vec3(0.1, 0.5, .8), -1.0);
        case 3:
        return vec4(vec3(1., 1., 0.), -1.0);
        case 4:
        return vec4(vec3(1., 0., 0.), -1.0);
        case 5:
        return vec4(vec3(0.82, 0.45, 0.24), 0.5);
        case 6:
        return vec4(vec3(1.0), -1.0);
    }
}

mat3 getCam(vec3 ro, vec3 lookAt) {
    vec3 camF = normalize(vec3(lookAt - ro));
    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

vec3 rayTrace(vec2 uv) {
    vec3 ro = vec3(0., 2.5, -5.);
    vec3 lookAt = vec3(0.);
    vec3 rd = getCam(ro, lookAt) * normalize(vec3(uv, FOV));

    vec3 res_color = vec3(1.0);

    for (int i = 0; i < MAX_REF; i++) {
        vec2 object = rayMarch(ro, rd);
        vec3 p = ro + object.x * rd;

        if (abs(object.x) < MAX_DIST) {
            vec4 color_inf = getColor(p, object.y);

            if (color_inf.w < 0.) {
                res_color *= color_inf.xyz;
                break;
            }
                res_color = res_color * color_inf.xyz;
                vec3 n = getNormal(p);
                ro = p + 2 * n * EPSILON;
                n = getMatRot(1 - color_inf.w) * n;
                rd = reflect(rd, n);

        } else {
            res_color *= getColor(p, 0.0).xyz;
            break;
        }
    }
    return res_color;
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;
    vec2 uv_tex = vec2(gl_FragCoord.x / u_resolution.x, gl_FragCoord.y / u_resolution.y);

    vec3 col = rayTrace(uv);
    col = pow(col, vec3(0.4545));

    //vec3 sampleCol = texture(u_texture_0, uv_tex.xy).xyz;
	//col = mix(sampleCol, col, 1.0 / pow(u_frame_n, .9));

    fragColor = vec4(col, 1.0);
}