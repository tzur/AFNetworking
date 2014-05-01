// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a duo filter using dual mask.
// See lightricks-research/enlight/Duo/ for a playground with concepts used by this shader.

uniform sampler2D sourceTexture;
uniform sampler2D dualMaskTexture;

uniform sampler2D blueLUT;
uniform sampler2D redLUT;
uniform mediump float opacity;

varying highp vec2 vTexcoord;

void main() {
  // Default NTSC weights for color->luminance conversion.
  const lowp vec3 kColorFilter = vec3(0.299, 0.587, 0.114);
  
  lowp vec3 color = texture2D(sourceTexture, vTexcoord).rgb;
  lowp float lum = dot(color.rgb, kColorFilter);
  
  lowp float dualMask = texture2D(dualMaskTexture, vTexcoord).r;
  
  lowp vec4 blueColor = texture2D(blueLUT, vec2(lum, 0.0));
  lowp vec4 redColor = texture2D(redLUT, vec2(lum, 0.0));
  
  // Contribution of the "blue" color.
  lowp vec3 result = mix(color, blueColor.rgb, dualMask * blueColor.a);
  // Contribution of the "red" color.
  result = mix(result, redColor.rgb, (1.0 - dualMask) * redColor.a);
  // Overal opacity.
  result = mix(color, result, opacity);
  
  gl_FragColor = vec4(result, 1.0);
}
