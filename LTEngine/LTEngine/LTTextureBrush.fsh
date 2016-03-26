// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform bool premultiplied;

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

uniform bool singleChannelTarget;

varying highp vec2 vTexcoord;

highp vec4 normal(in highp vec3 Sca, in highp vec3 Dca, in highp float Sa, in highp float Da) {
  return vec4(Sca + Dca * (1.0 - Sa), Sa + Da - Sa * Da);
}

void main() {
  // Apply the per-channel intensity on all channels.
  mediump vec4 dst = gl_LastFragData[0];
  highp vec4 src = texture2D(sourceTexture, vTexcoord) * intensity;

  // If the target is a single channel, use a simple mix according to the brush's alpha, flow and
  // opacity. Otherwise, normal blending is used.
  if (singleChannelTarget) {
    highp float safeA = src.a + (step(src.a, 0.0));
    gl_FragColor = vec4(mix(dst.r, src.r / safeA, min(src.a * flow, opacity)), 0.0, 0.0, 1.0);
  } else {
    if (!premultiplied) {
      dst.rgb *= dst.a;
    }

    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    // Update the rgb channels with the ratio, since we assume premultiplied alpha.
    highp float baseA = src.a + step(src.a, 0.0);
    src.a = min(src.a * flow, opacity);
    src.rgb *= src.a / baseA;
    highp vec4 blend = normal(src.rgb, dst.rgb, src.a, dst.a);

    if (!premultiplied) {
      highp float safeA = blend.a + (step(blend.a, 0.0));
      blend.rgb /= safeA;
    }

    gl_FragColor = blend;
  }
}
