const vec3 REPEAT = vec3(3.0, 3.0, 3.0);
const int MAX_MARHCING_STEPS = 256;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

struct Camera
{
    vec3 pos;
    vec3 dir;
    float fov;
} camera;

float sphereSDF(vec3 p) {
    float r = 1.0;
    return length(p) - r;
}

float boxSDF(vec3 p) {
    return 0.0;
}

float sceneSDF(vec3 p) {
    if (REPEAT.x > 0.0) {
        p.x = mod(p.x, REPEAT.x) - REPEAT.x * 0.5;
    }
    if (REPEAT.y > 0.0) {
        p.y = mod(p.y, REPEAT.y) - REPEAT.y * 0.5;
    }
    if (REPEAT.z > 0.0) {
        p.z = mod(p.z, REPEAT.z) - REPEAT.z * 0.5;
    }
    return sphereSDF(p);
}

float raymarch(vec3 rayDir, float start, float end) {
    float depth = start;

    for (int i = 0; i < MAX_MARHCING_STEPS; i++) {
        float dist = sceneSDF(camera.pos + depth * rayDir);
        
        if (dist < EPSILON) {
            return depth;
        }

        depth += dist;

        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirFromCamera(vec2 size, vec2 coord) {
    vec2 xy = coord - size / 2.0;
    float z = size.y / tan(radians(camera.fov) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 sceneNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

void main() {
    camera.pos = vec3(0.0, 0.0, 20.0);
    camera.dir = vec3(0.0, 0.0, 1.0);
    camera.fov = 90.0;

    vec3 dir = rayDirFromCamera(iResolution.xy, gl_FragCoord.xy);
    float dist = raymarch(dir, MIN_DIST, MAX_DIST);
    vec3 norm = sceneNormal(camera.pos + dist * dir);

    if (dist > MAX_DIST - EPSILON) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * dot(camera.dir, norm);
}