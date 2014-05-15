// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require
#extension GL_OES_standard_derivatives : require

uniform highp float opacity;

varying highp vec2 vPosition;
varying highp vec4 vShadowMaskAndWidth;
varying highp vec3 vEdge01;
varying highp vec3 vEdge12;
varying highp vec3 vEdge20;
varying highp vec4 vColor;
varying highp vec4 vShadowColor;
varying highp vec3 vBarycentric;

void main() {
  mediump vec4 dst = gl_LastFragData[0];
  mediump vec4 src = vec4(0.0, 0.0, 0.0, 0.0);

  // Assuming negative distance inside the triangle.
  highp vec3 position = vec3(vPosition, 1.0);
  highp float distance01 = dot(vEdge01, position) / length(vEdge01.xy);
  highp float distance12 = dot(vEdge12, position) / length(vEdge12.xy);
  highp float distance20 = dot(vEdge20, position) / length(vEdge20.xy);
  highp vec3 distances = vec3(distance01, distance12, distance20);

  // Smooth the triangle edges.
  highp vec3 edgeFactors = smoothstep(vec3(0.5), vec3(0.0), distances);
  highp float colorFactor = min(edgeFactors.x, min(edgeFactors.y, edgeFactors.z));
  
  // Smooth shadows around the triangle edges.
  highp float shadowWidth = vShadowMaskAndWidth.w;
  highp vec3 dBarycentric = fwidth(vBarycentric);
  highp vec3 shadowFactors = smoothstep(vec3(0.0), dBarycentric * shadowWidth, vBarycentric);
  shadowFactors *= shadowFactors;
  highp float shadowFactor = 0.5 * shadowFactors.x * shadowFactors.y * shadowFactors.z;

  // Discard shadows on edges without shadow (according to the shadow mask).
  highp vec3 noShadowMask = vec3(lessThan(vShadowMaskAndWidth.xyz, vec3(0.5)));
  shadowFactor *= 1.0 - float(any(greaterThan(distances * noShadowMask, vec3(0.0))));
  
  // Mix the color and shadow.
  highp vec4 color = vec4(vColor.rgb, vColor.a * colorFactor);
  highp vec4 shadow = vec4(vShadowColor.rgb, vShadowColor.a * shadowFactor);
  src = mix(shadow, color, vec4(colorFactor));
  
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
