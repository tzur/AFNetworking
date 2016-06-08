// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform sampler2D sourceTexture;
uniform sampler2D anotherTexture;
uniform highp float factor;

varying highp vec2 vTexcoord;
varying highp float vVertexFactor;

void main() {
  gl_FragColor = vec4(vec3(vVertexFactor), 1) *
      mix(texture2D(sourceTexture, vTexcoord), texture2D(anotherTexture, vTexcoord), factor);
}
