// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform bool filled;
uniform highp float opacity;

varying highp vec2 vOffset;
varying highp vec4 vLineBounds;
varying highp vec4 vShadowBounds;
varying highp vec4 vColor;
varying highp vec4 vShadowColor;

void main() {
  mediump vec4 dst = gl_LastFragData[0];
  mediump vec4 src = vec4(0.0, 0.0, 0.0, 0.0);

  // Seperate flows for filling an elliptic shape or drawing its outline.
  if (filled) {
    // In the filled shape, we basically test whether the offset is inside the elliptic equation,
    // after normalizing it by the width and height factors.
    // The colorFactor is 1 inside the ellipse, 0 outside the ellipse, linear between them on the
    // 2-pixel boundary of the ellipse.
    // The shadowFactor is linearly decreasing the same way, but in a larger area near the boundary.
    // Note that while the edge for the smoothstep calculation of the shadow could have been the
    // boundary itself, moving it slightly inside gives a little softer shadow and a better look.
    highp vec2 coeffs = vOffset / vLineBounds.xy;
    highp float d = coeffs.x * coeffs.x + coeffs.y * coeffs.y;
    highp float pixelThickness = 1.0 / min(vLineBounds.x, vLineBounds.y);
    highp float colorFactor = smoothstep(1.0 + pixelThickness , 1.0 - pixelThickness, d);
    highp float shadowFactor = smoothstep(1.0 + pixelThickness * vShadowBounds.x,
                                          1.0 - pixelThickness * vShadowBounds.x, d);
    highp vec4 color = vec4(vColor.rgb, vColor.a * colorFactor);
    highp vec4 shadow = vec4(vShadowColor.rgb, vShadowColor.a * shadowFactor);
    src = mix(shadow, color, vec4(colorFactor));
  } else {
    // In the outline mode, we're only interested in the y axis (since there's no shadow or smooth
    // edge in the x-axis, as all the segments are connected there).
    // The colorFactor is 1 for y offsets approximately inside [-lineRadius,lineRadius], and 0
    // outside this segment. Again, the factor is linear in a small area on the boundary.
    // Shadows work in a similar manner, decreasing linearly as getting away from the boundary.
    highp vec2 lineBounds = vec2(vLineBounds.y * -1.0, vLineBounds.w);
    highp vec2 shadowBounds = vec2(vShadowBounds.y * -1.0, vShadowBounds.w);
    highp vec2 edge0 = lineBounds - vec2(-0.5, 0.5);
    highp vec2 edge1 = lineBounds + vec2(-0.5, 0.5);
    highp vec2 shadowEdge0 = edge0 - vec2(-1.0, 1.0);
    highp vec2 shadowEdge1 = shadowBounds + vec2(-0.5, 0.5);
    
    highp vec2 offset = vec2(vOffset.y);
    highp vec2 colorFactors = smoothstep(edge1, edge0, offset);
    highp float colorFactor = colorFactors.x * colorFactors.y;
    
    highp vec2 shadowFactors = smoothstep(shadowEdge1, shadowEdge0, offset);
    highp float shadowFactor = shadowFactors.x * shadowFactors.y;
    shadowFactor = 0.5 * shadowFactor * shadowFactor;
    
    highp float colorStep = float(offset.x > lineBounds.x && offset.y < lineBounds.y);
    
    highp vec4 color = vec4(vColor.rgb, vColor.a * colorFactor * colorStep);
    highp vec4 shadow = vec4(vShadowColor.rgb, vShadowColor.a * shadowFactor);
    src = mix(shadow, color, vec4(colorFactor));
  }
  
  // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
  src.a = min(src.a, opacity);
  
  // Blend the source and the target according to the normal alpha blending formula:
  // http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;
  
  // If the result alpha is 0, the result rgb should be 0 as well.
  // safeA = (a <= 0) ? 1 : a;
  // gl_FragColor = (a <= 0) ? 0 : vec4(rgb / a, a);
  highp float safeA = a + step(a, 0.0);
  gl_FragColor = (1.0 - step(a, 0.0)) * vec4(rgb / safeA, a);
}
