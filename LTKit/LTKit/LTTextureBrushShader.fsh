// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

void main() {
  // Apply the per-channel intensity on all channels.
  mediump vec4 dst = gl_LastFragData[0];
  highp vec4 src = texture2D(sourceTexture, vTexcoord) * intensity;
  
  // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
  src.a = min(src.a * flow, opacity);
  
  // Blend the source and the target according to the normal alpha blending formula:
  // http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;
  gl_FragColor = vec4(rgb / a, a);
}
