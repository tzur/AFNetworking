// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

/// Is assumed to be orthographic projection.
uniform highp mat4 projection;

uniform mediump sampler2D colorTexture;
uniform bool sampleUniformColorFromColorTexture;

attribute highp vec4 position;
attribute highp vec3 texcoord;
attribute highp vec2 quadVertex0;
attribute highp vec2 quadVertex1;
attribute highp vec2 quadVertex2;
attribute highp vec2 quadVertex3;
attribute highp vec3 color;

varying highp vec2 vPosition;
varying highp vec3 vTexcoord;
varying highp vec2 vQuadVertex0;
varying highp vec2 vQuadVertex1;
varying highp vec2 vQuadVertex2;
varying highp vec2 vQuadVertex3;
varying highp vec3 vColor;

void main() {
  if (sampleUniformColorFromColorTexture) {
    vColor =
        texture2D(colorTexture, (quadVertex0 + quadVertex1 + quadVertex2 + quadVertex3) / 4.0).rgb;
  } else {
    vColor = color;
  }
  vPosition = position.xy;
  vTexcoord = texcoord;
  vQuadVertex0 = quadVertex0;
  vQuadVertex1 = quadVertex1;
  vQuadVertex2 = quadVertex2;
  vQuadVertex3 = quadVertex3;
  gl_Position = projection * position;
}
