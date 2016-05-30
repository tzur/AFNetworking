// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

uniform mediump sampler2D sourceTexture;

uniform mediump sampler2D secondTexture;
uniform mediump sampler2D thirdTexture;
uniform mediump sampler2D fourthTexture;

uniform int inputTexturesCount;

varying highp vec2 vTexcoord;

void main() {
  mediump float firstValue = texture2D(sourceTexture, vTexcoord).r;
  if (inputTexturesCount == 1) {
    gl_FragColor = vec4(firstValue, 0.0, 0.0, 0.0);
    return;
  }

  mediump float secondValue = texture2D(secondTexture, vTexcoord).r;
  if (inputTexturesCount == 2) {
    gl_FragColor = vec4(firstValue, secondValue, 0.0, 0.0);
    return;
  }

  mediump float thirdValue = texture2D(thirdTexture, vTexcoord).r;
  if (inputTexturesCount == 3) {
    gl_FragColor = vec4(firstValue, secondValue, thirdValue, 0.0);
    return;
  }

  mediump float fourthValue = texture2D(fourthTexture, vTexcoord).r;
  gl_FragColor = vec4(firstValue, secondValue, thirdValue, fourthValue);
}
