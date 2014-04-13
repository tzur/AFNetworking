// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader converts from RGB to HSV color space.

uniform sampler2D sourceTexture;

varying highp vec2 vTexcoord;

// This cryptic code is inspired by: http://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// Main point is to avoid ifs using swizzling and steps.
mediump vec3 rgb2hsv(mediump vec3 rgb) {
  mediump float eps = 1.0e-5;
  mediump vec4 swizzle = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  
  mediump vec4 p = mix(vec4(rgb.bg, swizzle.wz), vec4(rgb.gb, swizzle.xy), step(rgb.b, rgb.g));
  mediump vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));
  mediump float r = q.x - min(q.w, q.y);
  
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * r + eps)), r / (q.x + eps), q.x);
}

void main() {
  gl_FragColor = vec4(rgb2hsv(texture2D(sourceTexture, vTexcoord).rgb), 1.0);
}
