// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// The goal of this shader is to perform color to black-and-white conversion.
// The conversion includes color filter that weights the contribution of each rgb channel.
// Tonal parameters that set the tone of the result and color gradient that adds a tint to the final
// result.

uniform sampler2D sourceTexture;
uniform sampler2D smoothTexture;
uniform sampler2D colorGradient;

// Tone and details LUTs.
uniform sampler2D toneLUT;

// RGB to BW conversion weights.
uniform mediump vec3 colorFilter;
uniform mediump float structure;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp vec4 smoothColor = texture2D(smoothTexture, vTexcoord);
  
  lowp float lum = dot(color.rgb, colorFilter);
  lowp float smoothLum = dot(smoothColor.rgb, colorFilter);
  // Details.
  lum = smoothLum * pow((lum / smoothLum), structure);
  // Apply tonality LUT.
  lum = texture2D(toneLUT, vec2(lum, 0.0)).r;
  // Apply color gradient.
  color.rgb = texture2D(colorGradient, vec2(lum, 0.0)).rgb;
  
  gl_FragColor = color;
}
