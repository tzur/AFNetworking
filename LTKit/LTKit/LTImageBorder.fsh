// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adds a border to image by combining two frames together. Border is constructed out of
// two frame textures: front and back, which are blended with the source image using overlay
// blending.
const int kSymmetrizationTypeOriginal = 0;
const int kSymmetrizationTypeTop = 1;
const int kSymmetrizationTypeBottom = 2;
const int kSymmetrizationTypeLeft = 3;
const int kSymmetrizationTypeRight = 4;
const int kSymmetrizationTypeTopLeft = 5;
const int kSymmetrizationTypeTopRight = 6;
const int kSymmetrizationTypeBottomLeft = 7;
const int kSymmetrizationTypeBottomRight = 8;

uniform sampler2D sourceTexture;
uniform sampler2D frontTexture;
uniform sampler2D backTexture;

uniform mediump vec2 frontWidth;
uniform mediump vec2 backWidth;
uniform mediump float opacity;
uniform mediump vec3 frameColor;

uniform mediump float edge0;
uniform mediump float edge1;

uniform bool frontFlipHorizontal;
uniform bool frontFlipVertical;
uniform bool backFlipHorizontal;
uniform bool backFlipVertical;

uniform int frontSymmetrization;
uniform int backSymmetrization;

// Width / Height.
uniform mediump float aspectRatio;

varying highp vec2 vTexcoord;

// Sca - scource, top.
// Dca - destination, bottom.
mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca) {
  mediump vec3 below = 2.0 * Sca * Dca;
  mediump vec3 above = Sca * 2.0 + Dca * 2.0 - 2.0 * Dca * Sca - 1.0;
  
  return mix(below, above, step(0.5, Dca));
}

mediump float overlay(in mediump float Sca, in mediump float Dca) {
  mediump float below = 2.0 * Sca * Dca;
  mediump float above = Sca * 2.0 + Dca * 2.0 - 2.0 * Dca * Sca - 1.0;

  return mix(below, above, step(0.5, Dca));
}

mediump vec2 getBorderCoords(in mediump vec2 coords, in mediump vec2 width,
                             in mediump float ratio) {
  highp vec2 borderCoords;
  borderCoords.y = mix(coords.y - width.y, coords.y + width.y, step(0.5, coords.y));
  borderCoords.x = mix((coords.x - width.x) * ratio,
                      1.0 - (1.0 - coords.x - width.x) * ratio, step(0.5, coords.x));
  return borderCoords;
}

mediump vec2 topSymmetry(in mediump vec2 coords) {
  return vec2(coords.x, 0.5 - abs(coords.y - 0.5));
}

mediump vec2 bottomSymmetry(in mediump vec2 coords) {
  return vec2(coords.x, 0.5 + abs(coords.y - 0.5));
}

mediump vec2 leftSymmetry(in mediump vec2 coords) {
  return vec2(0.5 - abs(coords.x - 0.5), coords.y);
}

mediump vec2 rightSymmetry(in mediump vec2 coords) {
  return vec2(0.5 + abs(coords.x - 0.5), coords.y);
}

mediump vec2 topLeftSymmetry(in mediump vec2 coords) {
  return 0.5 - abs(coords - 0.5);
}

mediump vec2 bottomRightSymmetry(in mediump vec2 coords) {
  return 0.5 + abs(coords - 0.5);
}

mediump vec2 topRightSymmetry(in mediump vec2 coords) {
  return vec2(0.5 + abs(coords.x - 0.5), 0.5 - abs(coords.y - 0.5));
}

mediump vec2 bottomLeftSymmetry(in mediump vec2 coords) {
  return vec2(0.5 - abs(coords.x - 0.5), 0.5 + abs(coords.y - 0.5));
}

mediump vec2 flipHorizontal(in mediump vec2 coords) {
  return vec2(1.0 - coords.x, coords.y);
}

mediump vec2 flipVertical(in mediump vec2 coords) {
  return vec2(coords.x, 1.0 - coords.y);
}

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);

  // 1. Flip coordinates.
  mediump vec2 coords = vTexcoord;
  if (frontFlipHorizontal) {
    coords = flipHorizontal(coords);
  }
  if (frontFlipVertical) {
    coords = flipVertical(coords);
  }
  mediump vec2 frontCoords = mix(getBorderCoords(coords, frontWidth, aspectRatio),
                                 getBorderCoords(coords.yx, frontWidth.yx, 1.0 / aspectRatio).yx,
                                 step(1.0, aspectRatio));

  coords = vTexcoord;
  if (backFlipHorizontal) {
    coords = flipHorizontal(coords);
  }
  if (backFlipVertical) {
    coords = flipVertical(coords);
  }
  mediump vec2 backCoords = mix(getBorderCoords(coords, backWidth, aspectRatio),
                                 getBorderCoords(coords.yx, backWidth.yx, 1.0 / aspectRatio).yx,
                                 step(1.0, aspectRatio));

  // 2. Symmetrize coordinates.
  mediump vec2 symmetrizedBackCoords = backCoords;
  mediump vec2 symmetrizedFrontCoords = frontCoords;

  if (frontSymmetrization == kSymmetrizationTypeTop) {
    symmetrizedFrontCoords = topSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeBottom) {
    symmetrizedFrontCoords = bottomSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeLeft) {
    symmetrizedFrontCoords = leftSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeRight) {
    symmetrizedFrontCoords = rightSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeTopLeft) {
    symmetrizedFrontCoords = topLeftSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeTopRight) {
    symmetrizedFrontCoords = topRightSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeBottomLeft) {
    symmetrizedFrontCoords = bottomLeftSymmetry(frontCoords);
  } else if (frontSymmetrization == kSymmetrizationTypeBottomRight) {
    symmetrizedFrontCoords = bottomRightSymmetry(frontCoords);
  }

  if (backSymmetrization == kSymmetrizationTypeTop) {
    symmetrizedBackCoords = topSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeBottom) {
    symmetrizedBackCoords = bottomSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeLeft) {
    symmetrizedBackCoords = leftSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeRight) {
    symmetrizedBackCoords = rightSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeTopLeft) {
    symmetrizedBackCoords = topLeftSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeTopRight) {
    symmetrizedBackCoords = topRightSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeBottomLeft) {
    symmetrizedBackCoords = bottomLeftSymmetry(backCoords);
  } else if (backSymmetrization == kSymmetrizationTypeBottomRight) {
    symmetrizedBackCoords = bottomRightSymmetry(backCoords);
  }

  // 3. Sample and blend.
  mediump float front = texture2D(frontTexture, frontCoords).r;
  mediump float symmetrizedFront = texture2D(frontTexture, symmetrizedFrontCoords).r;

  mediump float back = texture2D(backTexture, backCoords).r;
  mediump float symmetrizedBack = texture2D(backTexture, symmetrizedBackCoords).r;

  mediump float mask = smoothstep(edge0, edge1, min(abs(0.5 - coords.x), abs(0.5 - coords.y)));

  back = mix(symmetrizedBack, back, mask);
  front = mix(symmetrizedFront, front, mask);

  mediump float border = 0.5 + opacity * (overlay(back, front) - 0.5);
  mediump vec3 outputColor = overlay(color.rgb, vec3(border));

  // 4. Add color using multiply blending on the front frame.
  outputColor = mix(outputColor, outputColor * frameColor, 2.0 * abs(border - 0.5));

  gl_FragColor = vec4(outputColor, color.a);
}
