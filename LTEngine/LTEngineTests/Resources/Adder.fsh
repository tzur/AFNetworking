// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform sampler2D sourceTexture;
uniform sampler2D auxTexture;
uniform highp float value;

varying highp vec2 vTexcoord;

void main() {
  highp vec4 sourceColor = texture2D(sourceTexture, vTexcoord);
  highp vec4 auxColor = texture2D(auxTexture, vTexcoord);

  gl_FragColor = sourceColor + auxColor + vec4(value);
}
