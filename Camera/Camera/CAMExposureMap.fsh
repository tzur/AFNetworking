// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

uniform lowp sampler2D sourceTexture;

varying highp vec2 vTexcoord;

const highp vec3 center = vec3(0.5);

void main() {
  highp vec3 value = texture2D(sourceTexture, vTexcoord).rgb;

  value -= center;
  value = exp(-(value * value) / 0.08);

  gl_FragColor.r = value.r * value.g * value.b;
}
