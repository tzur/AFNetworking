// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D maskTexture;

uniform lowp vec4 maskColor;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 image = texture2D(sourceTexture, vTexcoord);
  lowp vec4 mask = 1.0 - texture2D(maskTexture, vTexcoord);

  lowp vec4 color = mix(image, maskColor, mask.r * maskColor.a);
  gl_FragColor = vec4(color.rgb, 1.0);
}
