// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjust the saturation and the luminance of the source image based on hue/saturation
// masks that it constructs.

#define M_PI 3.14159265

uniform sampler2D sourceTexture;
uniform sampler2D hsvTexture;

uniform mediump float redSaturation;
uniform mediump float redLuminance;

uniform mediump float orangeSaturation;
uniform mediump float orangeLuminance;

uniform mediump float yellowSaturation;
uniform mediump float yellowLuminance;

uniform mediump float greenSaturation;
uniform mediump float greenLuminance;

uniform mediump float cyanSaturation;
uniform mediump float cyanLuminance;

uniform mediump float blueSaturation;
uniform mediump float blueLuminance;

varying highp vec2 vTexcoord;

// This cryptic code is inspired by: http://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
mediump vec3 HSVToRGB(mediump vec3 c) {
  mediump vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  mediump vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
  sourceTexture;
  
  mediump vec3 hsv = texture2D(hsvTexture, vTexcoord).rgb;
  mediump vec3 newHsv;
  
  // Red.
  mediump float mask;
  mask = smoothstep(0.4, 0.0, sin(hsv.r * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(hsv.g, hsv.g * redSaturation, mask);
  newHsv.b = mix(hsv.b, hsv.b * redLuminance, mask);
  // Orange.
  mask = smoothstep(0.4, 0.0, sin(abs(hsv.r - 0.0833) * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(newHsv.g, newHsv.g * orangeSaturation, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * orangeLuminance, mask);
  // Yellow.
  mask = smoothstep(0.4, 0.0, sin(abs(hsv.r - 0.1667) * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(newHsv.g, newHsv.g * yellowSaturation, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * yellowLuminance, mask);
  // Green.
  mask = smoothstep(0.8, 0.0, sin(abs(hsv.r - 0.333) * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(newHsv.g, newHsv.g * greenSaturation, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * greenLuminance, mask);
  // Cyan.
  mask = smoothstep(0.4, 0.0, sin(abs(hsv.r - 0.5) * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(newHsv.g, newHsv.g * cyanSaturation, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * cyanLuminance, mask);
  // Blue.
  mask = smoothstep(0.8, 0.0, sin(abs(hsv.r - 0.6667) * M_PI));
  mask = mask * smoothstep(0.0, 0.2, hsv.g);
  newHsv.g = mix(newHsv.g, newHsv.g * blueSaturation, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * blueLuminance, mask);
  
  // Hue channel doesn't change.
  newHsv.r = hsv.r;
  
  gl_FragColor = vec4(HSVToRGB(clamp(newHsv, 0.0, 1.0)), 1.0);
}
