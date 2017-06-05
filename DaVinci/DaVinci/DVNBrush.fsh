// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

/// Texture, in non-premultiplied format, used for texture mapping of the rendered quad. Is
/// single-channel texture if \c singleChannel is \c YES.
uniform mediump sampler2D sourceTexture;

/// Texture, in non-premultiplied format, used as alternative texture mapping of the rendered quad.
uniform mediump sampler2D overlayTexture;

/// RGB or RGBA texture, in non-premultiplied or premultiplied format, used for computing the edges
/// potentially restricting the rendering.
uniform mediump sampler2D edgeAvoidanceGuideTexture;
uniform highp float opacity;
uniform highp float edgeAvoidance;
uniform bool singleChannel;
uniform bool sampleFromOverlayTexture;
uniform int blendMode;

/// RGBA color, in non-premultiplied format.
varying highp vec4 vColor;
varying highp vec4 vPosition;
varying highp vec3 vTexcoord;
varying highp vec2 vQuadCenter;
varying highp vec2 vSamplePoint0;
varying highp vec2 vSamplePoint1;
varying highp vec2 vSamplePoint2;
varying highp vec2 vSamplePoint3;

const int kBlendModeNormal = 0;
const int kBlendModeDarken = 1;
const int kBlendModeMultiply = 2;
const int kBlendModeHardLight = 3;
const int kBlendModeSoftLight = 4;
const int kBlendModeLighten = 5;
const int kBlendModeScreen = 6;
const int kBlendModeColorBurn = 7;
const int kBlendModeOverlay = 8;
const int kBlendModePlusLighter = 9;
const int kBlendModePlusDarker = 10;
const int kBlendModeSubtract = 11;

highp vec4 normal(highp vec4 src, highp vec4 dst) {
  return vec4(src.rgb + dst.rgb * (1.0 - src.a), src.a + dst.a * (1.0 - src.a));
}

highp vec4 darken(highp vec4 src, highp vec4 dst) {
  highp float outA = src.a + dst.a - src.a * dst.a;
  highp vec3 outRGB = min(src.rgb * dst.a, dst.rgb * src.a) + src.rgb * (1.0 - dst.a) + dst.rgb *
      (1.0 - src.a);
  return vec4(outRGB, outA);
}

highp vec4 multiply(highp vec4 src, highp vec4 dst) {
  highp float outA = src.a + dst.a - src.a * dst.a;
  highp vec3 outRGB = src.rgb * dst.rgb + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  return vec4(outRGB, outA);
}

highp vec4 hardLight(highp vec4 src, highp vec4 dst) {
  mediump vec3 below = 2.0 * src.rgb * dst.rgb + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  mediump vec3 above = src.rgb * (1.0 + dst.a) + dst.rgb * (1.0 + src.a) - src.a * dst.a - 2.0 *
      src.rgb * dst.rgb;
  return vec4(mix(below, above, step(0.5 * src.a, src.rgb)), src.a + dst.a - src.a * dst.a);
}

highp vec4 softLight(highp vec4 src, highp vec4 dst) {
  mediump float safeA = dst.a + step(dst.a, 0.0);
  mediump vec3 below = 2.0 * src.rgb * dst.rgb + dst.rgb * (dst.rgb / safeA) *
      (src.a - 2.0 * src.rgb) + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  mediump vec3 above = 2.0 * dst.rgb * (src.a - src.rgb) + sqrt(dst.rgb * dst.a) *
      (2.0 * src.rgb - src.a) + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  return vec4(mix(below, above, step(0.5 * src.a, src.rgb)), src.a + dst.a - src.a * dst.a);
}

highp vec4 lighten(highp vec4 src, highp vec4 dst) {
  highp float outA = src.a + dst.a - src.a * dst.a;
  highp vec3 outRGB = max(src.rgb * dst.a, dst.rgb * src.a) + src.rgb * (1.0 - dst.a) + dst.rgb *
      (1.0 - src.a);
  return vec4(outRGB, outA);
}

highp vec4 screen(highp vec4 src, highp vec4 dst) {
  return vec4(src.rgb + dst.rgb - src.rgb * dst.rgb, src.a + dst.a - src.a * dst.a);
}

highp vec4 colorBurn(highp vec4 src, highp vec4 dst) {
  mediump float safeA = dst.a + step(dst.a, 0.0);
  mediump vec3 stepRGB = step(src.rgb, vec3(0.0));
  mediump vec3 safeRGB = src.rgb + stepRGB;
  mediump vec3 zero = src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  mediump vec3 nonzero = src.a * dst.a * (vec3(1.0) - min(vec3(1.0), (1.0 - dst.rgb / safeA) *
      src.a / safeRGB)) + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  return vec4(mix(zero, nonzero, 1.0 - stepRGB), src.a + dst.a - src.a * dst.a);
}

highp vec4 overlay(highp vec4 src, highp vec4 dst) {
  mediump vec3 below = 2.0 * src.rgb * dst.rgb + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  mediump vec3 above = src.rgb * (1.0 + dst.a) + dst.rgb * (1.0 + src.a) - 2.0 * dst.rgb * src.rgb -
      dst.a * src.a;
  return vec4(mix(below, above, step(0.5 * dst.a, dst.rgb)), src.a + dst.a - src.a * dst.a);
}

highp vec4 plusLighter(highp vec4 src, highp vec4 dst) {
  return clamp(dst + src, vec4(0.0), vec4(1.0));
}

highp vec4 plusDarker(highp vec4 src, highp vec4 dst) {
  return clamp(vec4(dst.rgb + src.rgb - 1.0, dst.a + src.a), vec4(0.0), vec4(1.0));
}

highp vec4 subtract(highp vec4 src, highp vec4 dst) {
  return clamp(dst - src, vec4(0.0), vec4(1.0));
}

highp vec4 blendOfNonPremultipliedColors(mediump vec4 src, highp vec4 dst, int mode) {
  src.rgb *= src.a;
  dst.rgb *= dst.a;
  highp vec4 premultipliedOutputColor = dst;
  
  if (blendMode == kBlendModeNormal) {
    premultipliedOutputColor = normal(src, dst);
  } else if (blendMode == kBlendModeDarken) {
    premultipliedOutputColor = darken(src, dst);
  } else if (blendMode == kBlendModeMultiply) {
    premultipliedOutputColor = multiply(src, dst);
  } else if (blendMode == kBlendModeHardLight) {
    premultipliedOutputColor = hardLight(src, dst);
  } else if (blendMode == kBlendModeSoftLight) {
    premultipliedOutputColor = softLight(src, dst);
  } else if (blendMode == kBlendModeLighten) {
    premultipliedOutputColor = lighten(src, dst);
  } else if (blendMode == kBlendModeScreen) {
    premultipliedOutputColor = screen(src, dst);
  } else if (blendMode == kBlendModeColorBurn) {
    premultipliedOutputColor = colorBurn(src, dst);
  } else if (blendMode == kBlendModeOverlay) {
    premultipliedOutputColor = overlay(src, dst);
  } else if (blendMode == kBlendModePlusLighter) {
    premultipliedOutputColor = plusLighter(src, dst);
  } else if (blendMode == kBlendModePlusDarker) {
    premultipliedOutputColor = plusDarker(src, dst);
  } else if (blendMode == kBlendModeSubtract) {
    premultipliedOutputColor = subtract(src, dst);
  }
  return premultipliedOutputColor;
}

highp float edgeAvoidanceFactor(in highp float spatialFactor) {
  const highp float kEpsilon = 1e-6;
  
  if (edgeAvoidance <= 0.0) {
    return 1.0;
  }
  highp vec3 targetPixel = texture2D(edgeAvoidanceGuideTexture, (vPosition / vPosition.w).xy).rgb;
  
  highp vec3 sampleDiff0 = targetPixel - texture2D(edgeAvoidanceGuideTexture, vQuadCenter).rgb;
  highp vec3 sampleDiff1 = targetPixel - texture2D(edgeAvoidanceGuideTexture, vSamplePoint0).rgb;
  highp vec3 sampleDiff2 = targetPixel - texture2D(edgeAvoidanceGuideTexture, vSamplePoint1).rgb;
  highp vec3 sampleDiff3 = targetPixel - texture2D(edgeAvoidanceGuideTexture, vSamplePoint2).rgb;
  highp vec3 sampleDiff4 = targetPixel - texture2D(edgeAvoidanceGuideTexture, vSamplePoint3).rgb;
  
  highp float rgbDist0 = dot(sampleDiff0, sampleDiff0);
  highp float rgbDist1 = dot(sampleDiff1, sampleDiff1);
  highp float rgbDist2 = dot(sampleDiff2, sampleDiff2);
  highp float rgbDist3 = dot(sampleDiff3, sampleDiff3);
  highp float rgbDist4 = dot(sampleDiff4, sampleDiff4);
  
  // The rgb (range) falloff of the current pixel is a minimum of the distances from the points
  // sampled at and around the center of the kernel.
  highp float rgbDist = sqrt(min(rgbDist0, min(min(rgbDist1, rgbDist2), min(rgbDist3, rgbDist4))));
  
  highp float strength = 1.0 + kEpsilon - edgeAvoidance;
  return exp(-rgbDist / max(spatialFactor * strength * 2.0, strength));
}

mediump vec4 premultipliedColor(in mediump vec4 nonPremultipliedColor) {
  return vec4(nonPremultipliedColor.rgb * nonPremultipliedColor.a, nonPremultipliedColor.a);
}

mediump vec4 nonPremultipliedColor(in mediump vec4 premultipliedColor) {
  highp float safeA = premultipliedColor.a + step(premultipliedColor.a, 0.0);
  return vec4(premultipliedColor.rgb / safeA, premultipliedColor.a);
}

void main() {
  mediump vec4 nonPremultipliedSource = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);
  mediump float alpha = opacity * nonPremultipliedSource.a;

  if (singleChannel) {
    alpha = opacity * nonPremultipliedSource.r;

    if (sampleFromOverlayTexture) {
      nonPremultipliedSource = texture2D(overlayTexture, (vPosition / vPosition.w).xy);
    } else {
      nonPremultipliedSource = vec4(vColor.rgb, vColor.a * alpha);
    }
  } else {
    nonPremultipliedSource *= vColor;
  }
  mediump vec4 nonPremultipliedDst = gl_LastFragData[0];
  mediump vec4 premultipliedDst = premultipliedColor(nonPremultipliedDst);
  mediump vec4 premultipliedBlendedColor;

  if (!sampleFromOverlayTexture) {
    premultipliedBlendedColor =
        blendOfNonPremultipliedColors(nonPremultipliedSource, nonPremultipliedDst, blendMode);
  } else {
    premultipliedBlendedColor = premultipliedColor(nonPremultipliedSource);
  }
  premultipliedBlendedColor = mix(premultipliedDst, premultipliedBlendedColor,
                                  alpha * edgeAvoidanceFactor(length(premultipliedBlendedColor)));
  gl_FragColor = nonPremultipliedColor(premultipliedBlendedColor);
}
