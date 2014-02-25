// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D targetTexture;
uniform lowp sampler2D membraneTexture;
uniform lowp sampler2D maskTexture;

varying highp vec2 vSourceTexcoord;
varying highp vec2 vTargetTexcoord;
varying highp vec2 vBaseTexcoord;

void main() {
  lowp vec4 source = texture2D(sourceTexture, vSourceTexcoord);
  lowp vec4 target = texture2D(targetTexture, vTargetTexcoord);
  lowp vec4 membrane = texture2D(membraneTexture, vBaseTexcoord);
  lowp vec4 mask = texture2D(maskTexture, vBaseTexcoord);

  gl_FragColor = mix(target, source + membrane, mask.r);
}
