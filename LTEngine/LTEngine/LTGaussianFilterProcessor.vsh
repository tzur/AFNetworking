// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Should be odd, @NUMBER_OF_TAPS@ is to be replaced with a real value in the run-time before
// compiling the shader.
const lowp int kNumberOfTaps = @NUMBER_OF_TAPS@;
const lowp int kCenterTap = (kNumberOfTaps - 1) / 2;

attribute highp vec4 position;
attribute highp vec3 texcoord;

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 texelOffset;

varying highp vec2 vTexcoords[kNumberOfTaps];

void main() {
  texture;
  for (highp int i = 0; i < kNumberOfTaps; ++i) {
    vTexcoords[i] = texcoord.xy + float(i - kCenterTap) * texelOffset;
  }
  gl_Position = projection * modelview * position;
}
