// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform sampler2D sourceTexture;
uniform sampler2D anotherTexture;
uniform highp float factor;

varying highp vec3 vTexcoord;

void main() {
  highp vec2 texcoord = vTexcoord.xy / vTexcoord.z;
  gl_FragColor =
      mix(texture2D(sourceTexture, texcoord), texture2D(anotherTexture, texcoord), factor);
}
