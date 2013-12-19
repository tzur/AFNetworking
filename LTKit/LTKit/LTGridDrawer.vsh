// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp vec2 pixelSize;
uniform highp float width;

attribute highp vec4 position;
attribute highp vec2 offset;

void main() {
  highp vec4 new_position = position - vec4(offset, 0.0, 0.0);
  new_position = projection * modelview * new_position;
  new_position.xy += (offset * pixelSize * width * new_position.w);
  gl_Position = new_position;
}
