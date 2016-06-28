// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

uniform highp vec2 meshDisplacementScale;
uniform highp sampler2D meshTexture;
uniform highp mat3 meshPosition;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;

void main() {
  position;
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;

  highp vec2 meshTexcoord = (meshPosition * vec3(vTexcoord.xy, 1.0)).xy;
  highp vec2 offset = texture2D(meshTexture, meshTexcoord).rg;

  gl_Position = projection * modelview * position +
      vec4(meshDisplacementScale * offset * 2.0, 0.0, 0.0);
}
