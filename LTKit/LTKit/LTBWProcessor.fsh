// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D grainTexture;
uniform sampler2D vignettingTexture;
uniform sampler2D wideFrameTexture;
uniform sampler2D narrowFrameTexture;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform mediump vec3 vignetteColor;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;

void main() {
  mediump vec4 tone = texture2D(sourceTexture, vTexcoord);
  mediump float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  mediump float vignette = texture2D(vignettingTexture, vTexcoord).r;
  mediump vec4 wideFrame = texture2D(wideFrameTexture, vTexcoord);
  mediump vec4 narrowFrame = texture2D(narrowFrameTexture, vTexcoord);
  
  tone.rgb = tone.rgb + grainAmplitude * (grain - 0.5);
  //  tone.rgb = mix(tone.rgb, vec3(grain), 0.8);
  tone.rgb = mix(tone.rgb, vignetteColor, vignette);

  tone.rgb = wideFrame.rgb + (1.0 - wideFrame.a) * tone.rgb;
  tone.rgb = narrowFrame.rgb + (1.0 - narrowFrame.a) * tone.rgb;
  
//  gl_FragColor = vec4(vec3(grain), 1.0);
  gl_FragColor = tone;
}
