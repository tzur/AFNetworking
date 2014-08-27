// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adds a border to image by combining two frames together.

uniform sampler2D sourceTexture;
uniform sampler2D outerFrameTexture;
uniform sampler2D innerFrameTexture;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp vec4 innerFrame = texture2D(innerFrameTexture, vTexcoord);
  lowp vec4 outerFrame = texture2D(outerFrameTexture, vTexcoord);
  
  lowp vec4 outputColor;
  outputColor.rgb = innerFrame.rgb + (1.0 - innerFrame.a) * color.rgb;
  outputColor.rgb = outerFrame.rgb + (1.0 - outerFrame.a) * outputColor.rgb;
  outputColor.a = min(1.0, color.a + innerFrame.a + outerFrame.a);
  gl_FragColor = outputColor;
}
