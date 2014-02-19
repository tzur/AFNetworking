// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int kOperationTypeAdd = 0;
const int kOperationTypeSubtract = 1;
const int kOperationTypeMultiply = 2;
const int kOperationTypeDivide = 3;

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D secondTexture;

uniform int operationType;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 first = texture2D(sourceTexture, vTexcoord);
  lowp vec4 second = texture2D(secondTexture, vTexcoord);

  if (operationType == kOperationTypeAdd) {
    gl_FragColor = vec4(first.rgb + second.rgb, 1.0);
  } else if (operationType == kOperationTypeSubtract) {
    gl_FragColor = vec4(first.rgb - second.rgb, 1.0);
  } else if (operationType == kOperationTypeMultiply) {
    gl_FragColor = vec4(first.rgb * second.rgb, 1.0);
  } else if (operationType == kOperationTypeDivide) {
    gl_FragColor = vec4(first.rgb / second.rgb, 1.0);
  }
}
