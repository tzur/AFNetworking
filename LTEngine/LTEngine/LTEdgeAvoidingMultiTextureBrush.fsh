// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform bool premultiplied;
uniform bool useAuxiliaryTexture;

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D gaussianTexture;
uniform lowp sampler2D auxiliaryTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp float sigma;
uniform highp vec4 intensity;

uniform bool singleChannelTarget;

varying highp vec2 vTexcoord;
varying highp vec2 vImgcoord;

highp vec4 normal(in highp vec3 Sca, in highp vec3 Dca, in highp float Sa, in highp float Da) {
  return vec4(Sca + Dca * (1.0 - Sa), Sa + Da - Sa * Da);
}

void main() {
  // Apply the per-channel intensity on all channels.
  mediump vec4 dst = gl_LastFragData[0];
  highp vec4 src = texture2D(sourceTexture, vTexcoord) * intensity;
  
  // Calculate the rgb distance according to the useAuxiliaryTexture flag: either the distance
  // between the intensity and the auxiliary texture, or the intensity and the target framebuffer.
  highp vec3 rgbDiff;
  if (useAuxiliaryTexture) {
    rgbDiff = texture2D(auxiliaryTexture, vImgcoord).rgb - intensity.rgb;
  } else {
    rgbDiff = dst.rgb - intensity.rgb;
  }
  
  // Apply the edge-avoiding factor, if applicable.
  highp float factor = 1.0;
  if (sigma < 1.0) {
    highp float rgbDist = dot(rgbDiff, rgbDiff);
    highp float spatialDistanceFactor = texture2D(gaussianTexture, vTexcoord).r;
    factor = exp(-rgbDist / max(spatialDistanceFactor * sigma, sigma));
  }

  // If the target is a single channel, use a simple mix according to the brush's alpha, flow,
  // opacity and the edge-avoiding factor. Otherwise, normal blending is used.
  if (singleChannelTarget) {
    highp float safeA = src.a + (step(src.a, 0.0));
    gl_FragColor =
        vec4(mix(dst.r, src.r / safeA, min(src.a * flow * factor, opacity)), 0.0, 0.0, 1.0);
  } else {
    if (!premultiplied) {
      dst.rgb *= dst.a;
    }

    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    // Update the rgb channels with the ratio, since we assume premultiplied alpha.
    highp float baseA = src.a + step(src.a, 0.0);
    src.a = min(src.a * flow * factor, opacity);
    src.rgb *= src.a / baseA;
    highp vec4 blend = normal(src.rgb, dst.rgb, src.a, dst.a);

    if (!premultiplied) {
      highp float safeA = blend.a + (step(blend.a, 0.0));
      blend.rgb /= safeA;
    }

    gl_FragColor = blend;
  }
}
