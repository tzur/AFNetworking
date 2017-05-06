// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D weightMap;
uniform mediump sampler2D higherGaussianLevel;

uniform highp vec2 texelStep;

varying highp vec2 vTexcoord;

const lowp mat3 kernelWeights = mat3(36.0 / 64.0, 24.0 / 64.0, 6.0 / 64.0,
                                     24.0 / 64.0, 16.0 / 64.0, 4.0 / 64.0,
                                     6.0 / 64.0, 4.0 / 64.0, 1.0 / 64.0);

void main() {
  mediump vec3 baseSample = texture2D(sourceTexture, vTexcoord).rgb;

  int initialX = -2 + int(mod(gl_FragCoord.x, 2.0));
  int initialY = -2 + int(mod(gl_FragCoord.y, 2.0));
  highp float texelStepX, texelStepY;
  mediump vec3 upSample = vec3(0.0);

  for (int i = initialX ; i <= 2 ; i += 2) {
    texelStepX = texelStep.x * float(i);
    int xIndex = int(abs(float(i)));
    for (int j = initialY ; j <= 2 ; j +=2) {
      texelStepY = texelStep.y * float(j);
      upSample += kernelWeights[int(abs(float(j)))][xIndex] *
          texture2D(higherGaussianLevel, vTexcoord + vec2(texelStepX, texelStepY)).rgb;
    }
  }

  highp float weight = texture2D(weightMap, vTexcoord).r;
  highp vec3 laplacian = vec3(weight) * (baseSample - upSample);

  gl_FragColor = vec4(gl_LastFragData[0].rgb + laplacian, 1.0);
}
