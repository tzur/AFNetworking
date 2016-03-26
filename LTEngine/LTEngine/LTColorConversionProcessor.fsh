// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int kModeHSV2RGB = 0;
const int kModeRGB2HSV = 1;
const int kModeRGBToYIQ = 2;
const int kModeYIQToRGB = 3;
const int kModeRGBToYYYY = 4;

uniform sampler2D sourceTexture;

uniform int mode;

varying highp vec2 vTexcoord;

// This cryptic code of the rgb <--> hsv conversion is inspired by:
// http://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// Main point is to avoid ifs using swizzling and steps.

mediump vec3 RGBToHSV(mediump vec3 rgb) {
  mediump float eps = 1.0e-5;
  mediump vec4 swizzle = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  
  mediump vec4 p = mix(vec4(rgb.bg, swizzle.wz), vec4(rgb.gb, swizzle.xy), step(rgb.b, rgb.g));
  mediump vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));
  mediump float r = q.x - min(q.w, q.y);
  
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * r + eps)), r / (q.x + eps), q.x);
}

mediump vec3 HSVToRGB(mediump vec3 hsv) {
  mediump vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  mediump vec3 p = abs(fract(hsv.xxx + k.xyz) * 6.0 - k.www);
  return hsv.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), hsv.y);
}

mediump vec3 RGBToYIQ(mediump vec3 rgb) {
  const highp mat3 m = mat3(0.299, 0.595716, 0.211456,
                            0.587, -0.274453, -0.522591,
                            0.144, -0.321263, 0.311135);

  return m * rgb;
}

mediump vec3 YIQToRGB(mediump vec3 yiq) {
  const highp mat3 m = mat3(1, 1, 1,
                            0.9563, -0.2721, -1.1070,
                            0.6210, -0.6474, 1.7046);
  return m * yiq;
}

void main() {
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);

  if (mode == kModeHSV2RGB) {
    gl_FragColor = vec4(RGBToHSV(color.rgb), color.a);
  } else if (mode == kModeRGB2HSV) {
    gl_FragColor = vec4(HSVToRGB(color.rgb), color.a);
  } else if (mode == kModeRGBToYIQ) {
    gl_FragColor = vec4(RGBToYIQ(color.rgb), color.a);
  } else if (mode == kModeYIQToRGB) {
    gl_FragColor = vec4(YIQToRGB(color.rgb), color.a);
  } else if (mode == kModeRGBToYYYY) {
    gl_FragColor = vec4(RGBToYIQ(color.rgb).r);
  }
}
