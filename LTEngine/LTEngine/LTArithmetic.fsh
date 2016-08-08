// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kOperationTypeAdd = 0;
const int kOperationTypeSubtract = 1;
const int kOperationTypeMultiply = 2;
const int kOperationTypeDivide = 3;
const int kOperationTypeMax = 4;
const int kOperationTypeMin = 5;

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D secondTexture;

uniform bool firstInSituProcessing;
uniform bool secondInSituProcessing;

uniform int operationType;

varying highp vec2 vTexcoord;

void main() {
  lowp vec3 first;
  if (firstInSituProcessing) {
    first = gl_LastFragData[0].rgb;
  } else {
    first = texture2D(sourceTexture, vTexcoord).rgb;
  }
  lowp vec3 second;
  if (secondInSituProcessing) {
    second = gl_LastFragData[0].rgb;
  } else {
    second = texture2D(secondTexture, vTexcoord).rgb;
  }

  if (operationType == kOperationTypeAdd) {
    gl_FragColor = vec4(first + second, 1.0);
  } else if (operationType == kOperationTypeSubtract) {
    gl_FragColor = vec4(first - second, 1.0);
  } else if (operationType == kOperationTypeMultiply) {
    gl_FragColor = vec4(first * second, 1.0);
  } else if (operationType == kOperationTypeDivide) {
    gl_FragColor = vec4(first / second, 1.0);
  } else if (operationType == kOperationTypeMax) {
    gl_FragColor = vec4(max(first, second), 1.0);
  } else if (operationType == kOperationTypeMin) {
    gl_FragColor = vec4(min(first, second), 1.0);
  }
}
