// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int kTexturingModeStretch = 0;
const int kTexturingModeTile = 1;

uniform sampler2D sourceTexture;

uniform highp vec2 origin;
uniform highp vec2 size;
uniform highp mat2 toRotatedRect;
uniform highp mat2 fromRotatedRect;
uniform highp vec2 scaling;

uniform int texturingMode;

varying highp vec2 vTexcoord;

// Returns tiled texture coordinate given a regular (e.g. normally stretched) texture coordinate.
highp vec2 toTiledTexCoord(in highp vec2 texCoord) {
  // 1. Transform the point such that the top-left vertex of the containing rect is in (0, 0).
  highp vec2 translated = texCoord - origin;
  // 2. Transform point to rect's coordinate system (which can be rotated).
  highp vec2 transformed = toRotatedRect * translated;
  // 3. Do the tiling.
  highp vec2 tiled = mod(transformed * scaling, size);
  // 4. Restore the texture coordinate to original coordinate system.
  highp vec2 restored = fromRotatedRect * tiled;
  // 5. Add back the origin.
  return restored + origin;
}

void main() {
  if (texturingMode == kTexturingModeStretch) {
    gl_FragColor = texture2D(sourceTexture, vTexcoord);
  } else if (texturingMode == kTexturingModeTile) {
    gl_FragColor = texture2D(sourceTexture, toTiledTexCoord(vTexcoord));
  }
}
