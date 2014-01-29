// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;

// Fractional noise seed.
uniform highp float seed;
// Hihger values will create higher number of island-like structures. Recommended values are in
// [2-20] range.
uniform highp float density;
// Providing aspect ratio will create an isotropic noise. Values above or bellow aspect ratio will
// favor x or y axes, creating elongated structures along this dimension.
uniform highp float directionality;

varying highp vec2 vTexcoord;

// Fractional noise with a single seed.
highp float noise(highp vec2 texcoord) {
  return fract(sin(dot(texcoord, vec2(78.233, 12.9898))) * (43758.5453 + seed));
}

highp float bilinearNoise(highp vec2 p){
  // Find integer and fractional parts.
	highp vec2 i = floor(p - 0.5);
	highp vec2 f = fract(p - 0.5);
  // Smoother step: http://www.iquilezles.org/www/articles/texture/texture.htm
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  // Bilinear interpolation: x-axis.
	highp float rt = mix(noise(i), noise(i + vec2(1.0, 0.0)), f.x);
	highp float rb = mix(noise(i + vec2(0.0, 1.0)), noise(i + vec2(1.0, 1.0)), f.x);
  // Bilinear interpolation: y-axis. Subtract mean and center around zero.
	return mix(rt, rb, f.y) - 0.5;
}

void main() {
  sourceTexture;
  directionality;
  highp vec2 p = vTexcoord.xy * vec2(density * directionality, density);
  highp float f = 0.5 + 0.5 * bilinearNoise(p) + 0.25 * bilinearNoise(2.0 * p) +
                        0.125 * bilinearNoise(4.0 * p) + 0.0625 * bilinearNoise(8.0 * p) +
                        0.03125 * bilinearNoise(16.0 * p) + 0.015 * bilinearNoise(32.0 * p);
  gl_FragColor = vec4(f, f, f, 1.0);
}
