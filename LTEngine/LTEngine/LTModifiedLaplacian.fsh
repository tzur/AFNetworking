// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

uniform sampler2D sourceTexture;

uniform highp vec2 texelStep;
varying highp vec2 vTexcoord;

void main() {
  mediump vec4 center = texture2D(sourceTexture, vTexcoord);
  mediump vec4 sampleX1 = texture2D(sourceTexture, vTexcoord + vec2(texelStep.x, 0));
  mediump vec4 sampleX2 = texture2D(sourceTexture, vTexcoord - vec2(texelStep.x, 0));
  mediump vec4 sampleY1 = texture2D(sourceTexture, vTexcoord + vec2(0, texelStep.y));
  mediump vec4 sampleY2 = texture2D(sourceTexture, vTexcoord - vec2(0, texelStep.y));

  mediump vec4 modLap = abs(2.0 * center - sampleX1 - sampleX2) +
                        abs(2.0 * center - sampleY1 - sampleY2);

  // Avoid high values on border of image or where alpha mask is low.
  modLap = modLap * (sampleX1.a * sampleX2.a * sampleY1.a * sampleY2.a);

  mediump float gray = dot(modLap.rgb, vec3(0.299, 0.587, 0.114));

  gl_FragColor.r = gray / 4.0;
}
