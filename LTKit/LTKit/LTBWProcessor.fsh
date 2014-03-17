// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D grainTexture;
uniform sampler2D vignettingTexture;
uniform sampler2D outerFrameTexture;
uniform sampler2D innerFrameTexture;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform mediump vec3 vignetteColor;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;

void main() {
  mediump vec4 tone = texture2D(sourceTexture, vTexcoord);
  mediump float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  mediump float vignette = texture2D(vignettingTexture, vTexcoord).r;
  mediump vec4 innerFrame = texture2D(innerFrameTexture, vTexcoord);
  mediump vec4 outerFrame = texture2D(outerFrameTexture, vTexcoord);
  
  tone.rgb = tone.rgb + grainAmplitude * (grain - 0.5);
  tone.rgb = mix(tone.rgb, vignetteColor, vignette);
  
  tone.rgb = innerFrame.rgb + (1.0 - innerFrame.a) * tone.rgb;
  tone.rgb = outerFrame.rgb + (1.0 - outerFrame.a) * tone.rgb;
  
  gl_FragColor = tone;
}
