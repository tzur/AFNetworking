// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

varying mediump vec4 vMembraneColor;
varying mediump vec2 vSourceCoord;
varying mediump vec2 vTargetCoord;

uniform sampler2D sourceTexture;

// True if circular patch mode is heal.
uniform bool isCircularPatchModeHeal;
uniform mediump float alpha;

mediump float boundaryConditionForPosition(mediump float location) {
  mediump float base = mod(location, 1.0);
  base += step(base, 0.0);

  // Find number of repetitions. On odd repetitions we should mirror the signal, otherwise we keep
  // it as is.
  return mix(base, 1.0 - base, float(mod(floor(location), 2.0) > 0.0));
}

mediump vec2 boundaryConditionForCoordinate(mediump vec2 coord) {
  coord.x =
      mix(coord.x, boundaryConditionForPosition(coord.x), float(coord.x < 0.0 || coord.x >= 1.0));
  coord.y =
      mix(coord.y, boundaryConditionForPosition(coord.y), float(coord.y < 0.0 || coord.y >= 1.0));
  return coord;
}

void main() {
  lowp vec4 sourceColor;
  if (isCircularPatchModeHeal) {
    sourceColor = vec4(0.0, 0.0, 0.0, 1.0);
  } else {
    sourceColor = texture2D(sourceTexture, boundaryConditionForCoordinate(vSourceCoord));
  }
  
  lowp vec4 targetColor = texture2D(sourceTexture, boundaryConditionForCoordinate(vTargetCoord));
  gl_FragColor = vec4(mix(targetColor.rgb, vMembraneColor.rgb + sourceColor.rgb,
                          vMembraneColor.a * alpha), 1.0);
}
