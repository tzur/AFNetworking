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
  // Update the rgb channels with the ratio, since we assume premultiplied alpha.
  highp float baseA = src.a;
  src.a = min(src.a * flow, opacity);
  src.rgb *= src.a / baseA;
  
  // Blend the source and the target according to the normal alpha blending formula:
  // http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
  // Note that we're assuming both the source and destination are premultiplied, and that the result
  // should be premultiplied as well, hence the differences in the implemented formula.
  highp vec3 rgb = src.rgb + (1.0 - src.a) * dst.rgb;
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  
  gl_FragColor = vec4(rgb, a);
}
