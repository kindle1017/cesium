// #ifdef GL_EXT_frag_depth
// #extension GL_EXT_frag_depth : enable
// #endif

void czm_adjustSolidOutlineDepth() {
// #ifdef GL_EXT_frag_depth
//     // gl_FragDepthEXT -= 5e-5;
// #endif
}

czm_ray getPickRay(vec2 screenPosition) {
    float width = czm_viewport.z;
    float height = czm_viewport.w;
    float x = (2.0 / width) * screenPosition.x - 1.0;
    float y = (2.0 / height) * screenPosition.y - 1.0;

    float near = czm_currentFrustum.x;
    vec3 nearCenter = vec3(0.0, 0.0, -near);
    vec3 xDir = vec3(x * czm_frustumPlanes.w, 0.0, 0.0);
    vec3 yDir = vec3(0.0, y * czm_frustumPlanes.x, 0.0);
    vec3 direction = normalize(nearCenter + xDir + yDir);

    return czm_ray(vec3(0.0), direction);
}

vec3 noIntersection = vec3(czm_infinity, czm_infinity, czm_infinity);

vec3 intersectRayPlane(czm_ray ray, vec3 pointInPlane, vec3 planeNormal) {
    vec3 origin = ray.origin;
    vec3 direction = ray.direction;
    float denominator = dot(planeNormal, direction);
    float planeDistance = -dot(planeNormal, pointInPlane);

    if (abs(denominator) < 0.1) {
        // Ray is parallel to plane.  The ray may be in the polygon's plane.
        return noIntersection;
    }

    float t = (-planeDistance - dot(planeNormal, origin)) / denominator;

    if (t < 0.0) {
        return noIntersection;
    }

    vec3 result = direction * t;
    return origin + result;
}

vec3 czm_adjustSolidOutlineDepth(vec3 positionEye, vec3 normalEye) {
// #if defined(LOG_DEPTH) && defined(GL_EXT_frag_depth)
    // Find ray to diagonally-adjacent pixel (i.e. +1 in both X and Y directions)
    vec2 currentPixel = czm_eyeToWindowCoordinates(vec4(positionEye, 1.0)).xy;
    czm_ray currentRay = getPickRay(currentPixel);
    vec2 nextPixel = currentPixel + vec2(1.0, 1.0);
    czm_ray nextRay = getPickRay(nextPixel);

    // Find intersection of ray with plane created by fragment position and normal.
    vec3 currentIntersection = intersectRayPlane(currentRay, positionEye, normalEye);
    vec3 nextIntersection = intersectRayPlane(nextRay, positionEye, normalEye);

    if (currentIntersection == noIntersection || nextIntersection == noIntersection) {
        return positionEye;
    }

    // Compute the amount depth changes when we move by one pixel. Expresed in eye coordinates.
    float deltaDepth = abs(currentIntersection.z - nextIntersection.z);

    positionEye.z += deltaDepth;
    return positionEye;
// #endif
}
