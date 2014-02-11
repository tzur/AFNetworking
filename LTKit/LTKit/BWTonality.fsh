// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D smoothTexture;
uniform sampler2D colorGradient;

// RGB to BW conversion weights.
uniform highp vec3 colorFilter;
uniform highp float brightness;
uniform highp float contrast;
uniform highp float exposure;
uniform highp float structure;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 smoothColor = texture2D(smoothTexture, vTexcoord);
  
  mediump float lum = dot(color.rgb, colorFilter);
  mediump float smoothLum = dot(smoothColor.rgb, colorFilter);
  
  lum = smoothLum + structure * (lum - smoothLum);
  lum = brightness + 0.5 + contrast * (exposure * lum - 0.5);
  
  color.rgb = texture2D(colorGradient, vec2(lum, 0.0)).rgb;
  
  gl_FragColor = color;
}
