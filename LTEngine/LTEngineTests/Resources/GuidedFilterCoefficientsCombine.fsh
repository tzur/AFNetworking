// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Source texture.
uniform highp sampler2D sourceTexture;
// Guided filter scale coefficients texture.
uniform highp sampler2D scaleTexture;
// Guided filter shift coefficients texture.
uniform highp sampler2D shiftTexture;

varying highp vec2 vTexcoord;

void main() {
  highp vec4 guide = texture2D(sourceTexture, vTexcoord);
  highp vec3 scale = texture2D(scaleTexture, vTexcoord).rgb;
  highp vec3 shift = texture2D(shiftTexture, vTexcoord).rgb;
  gl_FragColor = vec4(scale * guide.rgb + shift, guide.a);
}
