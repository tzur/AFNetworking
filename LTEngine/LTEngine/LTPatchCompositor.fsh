// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D targetTexture;
uniform lowp sampler2D membraneTexture;
uniform lowp sampler2D maskTexture;

uniform highp float sourceOpacity;
uniform highp float smoothingAlpha;

varying highp vec2 vSourceTexcoord;
varying highp vec2 vTargetTexcoord;
varying highp vec2 vBaseTexcoord;

highp vec2 wrapCoordinatesMirror(highp vec2 coordinates) {
  return 1.0 - abs(mod(coordinates, 2.0) - 1.0);
}

void main() {
  lowp vec4 source = texture2D(sourceTexture, wrapCoordinatesMirror(vSourceTexcoord));
  lowp vec4 target = texture2D(targetTexture, vTargetTexcoord);
  lowp vec4 membrane = texture2D(membraneTexture, vBaseTexcoord);
  lowp vec4 mask = texture2D(maskTexture, vBaseTexcoord);

  highp float feathering = 1.0 - step(1.0, 1.0 - mask.r);

  if (smoothingAlpha * mask.r > 0.0) {
    feathering = (1.0 - smoothingAlpha) + smoothingAlpha * mask.r;
  }

  gl_FragColor = vec4(mix(target.rgb, source.rgb + membrane.rgb, feathering * sourceOpacity), 1.0);
}
