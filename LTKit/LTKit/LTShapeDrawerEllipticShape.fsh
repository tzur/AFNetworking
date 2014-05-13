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

  if (filled) {
    highp vec2 coeffs = vOffset / vLineBounds.xy;
    highp float d = coeffs.x * coeffs.x + coeffs.y * coeffs.y;
    highp float thickness = 1.0 / min(vLineBounds.x, vLineBounds.y);
    highp float colorFactor = smoothstep(1.0 + thickness , 1.0 - thickness, d);
    highp float shadowFactor = smoothstep(1.0 + thickness * vShadowBounds.x,
                                          1.0 - thickness * vShadowBounds.x, d);
    highp vec4 color = vec4(vColor.rgb, vColor.a * colorFactor);
    highp vec4 shadow = vec4(vShadowColor.rgb, vShadowColor.a * shadowFactor);
    src = mix(shadow, color, vec4(colorFactor));
  } else {
    highp vec4 lineBounds = vec4(vLineBounds.xy * -1.0, vLineBounds.zw);
    highp vec4 shadowBounds = vec4(vShadowBounds.xy * -1.0, vShadowBounds.zw);
    highp vec4 edge0 = lineBounds - vec4(-0.0, -0.5, 0.0, 0.5);
    highp vec4 edge1 = lineBounds + vec4(-0.5, -0.5, 0.5, 0.5);
    highp vec4 shadowEdge0 = edge0 - vec4(-0.5, -1.0, 0.5, 1.0);
    highp vec4 shadowEdge1 = shadowBounds + vec4(-0.0, -0.5, 0.0, 0.5);
    
    highp vec4 offset = vec4(vOffset, vOffset);
    highp vec4 colorFactors = smoothstep(edge1, edge0, offset);
    highp float colorFactor = colorFactors.x * colorFactors.y * colorFactors.z * colorFactors.w;
    
    highp vec4 shadowFactors = smoothstep(shadowEdge1, shadowEdge0, offset);
    highp float shadowFactor =
        shadowFactors.x * shadowFactors.y * shadowFactors.z * shadowFactors.w;
    shadowFactor = 0.5 * shadowFactor * shadowFactor;
    
    highp float colorStep = float(offset.x > lineBounds.x && offset.z < lineBounds.z &&
                                  offset.y > lineBounds.y && offset.w < lineBounds.w);
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
  highp float safeA = a + (step(a, 0.0));
  gl_FragColor = (1.0 - step(a, 0.0)) * vec4(rgb / safeA, a);
}