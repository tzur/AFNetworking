// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjusts hue, saturation and luminance of the source image based on hue/luminance
// masks that it constructs.

#define M_PI 3.14159265

uniform sampler2D sourceTexture;
uniform sampler2D hsvTexture;

uniform mediump float redSaturation;
uniform mediump float redLuminance;
uniform mediump float redHue;

uniform mediump float orangeSaturation;
uniform mediump float orangeLuminance;
uniform mediump float orangeHue;

uniform mediump float yellowSaturation;
uniform mediump float yellowLuminance;
uniform mediump float yellowHue;

uniform mediump float greenSaturation;
uniform mediump float greenLuminance;
uniform mediump float greenHue;

uniform mediump float cyanSaturation;
uniform mediump float cyanLuminance;
uniform mediump float cyanHue;

uniform mediump float blueSaturation;
uniform mediump float blueLuminance;
uniform mediump float blueHue;

varying highp vec2 vTexcoord;

/// This cryptic code is inspired by: http://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
mediump vec3 HSVToRGB(mediump vec3 hsv) {
  mediump vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  mediump vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
  return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

/// Update hue, saturation and luminance of the color band. Color band is determined by using a soft
/// hue threshold.
mediump vec3 updateColorBand(mediump vec3 hsv, mediump vec3 newHsv, mediump float hueCenter,
                             mediump float maskCorrection, mediump float hueShift,
                             mediump float saturationScaling, mediump float luminanceScaling) {
  mediump float mask = smoothstep(0.5, 0.0, sin(abs(hsv.r - hueCenter) * M_PI)) * maskCorrection;
  newHsv.r = mix(newHsv.r, mod(newHsv.r + hueShift, 1.0), mask);
  newHsv.g = mix(newHsv.g, newHsv.g * saturationScaling, mask);
  newHsv.b = mix(newHsv.b, newHsv.b * luminanceScaling, mask);
  return newHsv;
}

void main() {
  sourceTexture;
  
  mediump vec3 hsv = texture2D(hsvTexture, vTexcoord).rgb;
  mediump float luminanceCorrection = smoothstep(0.0, 0.5, hsv.b);
  
  mediump vec3 newHsv;
  newHsv = updateColorBand(hsv, hsv, 0.0, luminanceCorrection, redHue, redSaturation, redLuminance);
  newHsv = updateColorBand(hsv, newHsv, 0.0833, luminanceCorrection, orangeHue, orangeSaturation,
                           orangeLuminance);
  newHsv = updateColorBand(hsv, newHsv, 0.1667, luminanceCorrection, yellowHue, yellowSaturation,
                           yellowLuminance);
  newHsv = updateColorBand(hsv, newHsv, 0.333, luminanceCorrection, greenHue, greenSaturation,
                           greenLuminance);
  newHsv = updateColorBand(hsv, newHsv, 0.5, luminanceCorrection, cyanHue, cyanSaturation,
                           cyanLuminance);
  newHsv = updateColorBand(hsv, newHsv, 0.6667, luminanceCorrection, blueHue, blueSaturation,
                           blueLuminance);
  
  gl_FragColor = vec4(HSVToRGB(clamp(newHsv, 0.0, 1.0)), 1.0);
}
