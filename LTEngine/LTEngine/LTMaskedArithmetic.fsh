// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform lowp sampler2D firstTexture;
uniform lowp sampler2D secondTexture;
uniform lowp sampler2D sourceTexture;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 mask = texture2D(sourceTexture, vTexcoord);
  lowp vec4 first = texture2D(firstTexture, vTexcoord);
  lowp vec4 second = texture2D(secondTexture, vTexcoord);

  gl_FragColor = mix(vec4(0.0, 0.0, 0.0, 1.0), vec4(first.rgb - second.rgb, 1.0), mask.r);
}
