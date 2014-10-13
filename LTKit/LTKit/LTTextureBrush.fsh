// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform bool premultiplied;

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

// Blend the source and the target according to the normal alpha blending formula:
// http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
// Note that we're assuming both the source and destination are premultiplied, and that the
// result should be premultiplied as well, hence the differences in the implemented formula.
void normalPremultiplied(in highp vec4 src, in highp vec4 dst) {
  highp vec3 rgb = src.rgb + (1.0 - src.a) * dst.rgb;
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  gl_FragColor = vec4(rgb, a);
}

// Blend the source and the target according to the normal alpha blending formula:
// http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
void normalNonPremultiplied(in highp vec4 src, in highp vec4 dst) {
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;

  // If the result alpha is 0, the result rgb should be 0 as well.
  // safeA = (a <= 0) ? 1 : a;
  // gl_FragColor = (a <= 0) ? 0 : vec4(rgb / a, a);
  highp float safeA = a + (step(a, 0.0));
  gl_FragColor = (1.0 - step(a, 0.0)) * vec4(rgb / safeA, a);
}

void main() {
  // Apply the per-channel intensity on all channels.
  mediump vec4 dst = gl_LastFragData[0];
  highp vec4 src = texture2D(sourceTexture, vTexcoord) * intensity;
  
  if (premultiplied) {
    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    // Update the rgb channels with the ratio, since we assume premultiplied alpha.
    highp float baseA = src.a + step(src.a, 0.0);
    src.a = min(src.a * flow, opacity);
    src.rgb *= src.a / baseA;

    normalPremultiplied(src, dst);
  } else {
    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    src.a = min(src.a * flow, opacity);

    normalNonPremultiplied(src, dst);
  }
}
