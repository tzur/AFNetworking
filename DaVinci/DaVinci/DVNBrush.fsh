// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

/// Texture, in non-premultiplied format, used for texture mapping of the rendered quad. Is assumed
/// to be single-channel texture if \c singleChannel is \c YES.
uniform mediump sampler2D sourceTexture;

/// Texture, in non-premultiplied format, used as alternative texture mapping of the rendered quad.
uniform mediump sampler2D overlayTexture;

/// RGB or RGBA texture, in non-premultiplied or premultiplied format, used for computing the edges
/// potentially restricting the rendering.
uniform mediump sampler2D edgeAvoidanceGuideTexture;

/// Opacity used per rendered quad. Must be in range <tt>[0, 1]</tt>.
uniform highp float opacity;

/// Edge avoidance factor. Must be in range <tt>[0, 1]</tt>.
uniform highp float edgeAvoidance;

/// Linear transformation for transforming the texture coordinate system used for sampling the
/// \c overlayTexture.
uniform highp mat4 overlayTextureCoordTransform;

/// Enumeration value indicating whether to use the colors of the \c sourceTexture or the
/// \c overlayTexture as source color.
uniform int sourceType;

/// Value for \c sourceType indicating that the \c vColor should be used as source color.
const int kSourceTypeColor = 0;

/// Value for \c sourceType indicating that the \c sourceTexture should be used as source color.
const int kSourceTypeSourceTexture = 1;

/// Value for \c sourceType indicating that the \c overlayTexture should be used as source color or
/// mask.
const int kSourceTypeOverlayTexture = 2;

/// \c YES if \c sourceTexture should be used as mask. In this case, the texture is assumed to have
/// a single channel, otherwise it is assumed to have RGBA channels.
uniform bool useSourceTextureAsMask;

/// \c YES if \c overlayTexture should be used as mask. In this case, the texture is assumed to have
/// a single channel, otherwise it is assumed to have RGBA channels. Is ignored if \c sourceType
/// does not equal \c kSourceTypeOverlayTexture.
uniform bool useOverlayTextureAsMask;

/// \c YES if the render target has a single channel.
uniform bool renderTargetHasSingleChannel;

/// Blend mode to be used for blending.
uniform int blendMode;

/// RGBA color, in non-premultiplied format.
varying highp vec4 vColor;
varying highp vec4 vPosition;
varying highp vec3 vTexcoord;
varying highp vec3 vSampledColor0;
varying highp vec3 vSampledColor1;
varying highp vec3 vSampledColor2;
varying highp vec3 vSampledColor3;
varying highp vec3 vSampledColor4;

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
const int kBlendModeSrc = 12;
const int kBlendModeDst = 13;

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

highp vec4 blendOfPremultipliedColors(mediump vec4 src, highp vec4 dst, int mode) {
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
  } else if (blendMode == kBlendModeSrc) {
    premultipliedOutputColor = src;
  } else if (blendMode == kBlendModeDst) {
    // Do nothing since premultipliedOutputColor is already dst.
  }
  return premultipliedOutputColor;
}

highp float edgeAvoidanceFactor(in highp float spatialFactor) {
  const highp float kEpsilon = 1e-6;

  if (edgeAvoidance <= 0.0) {
    return 1.0;
  }
  highp vec3 targetPixel = texture2D(edgeAvoidanceGuideTexture, (vPosition / vPosition.w).xy).rgb;

  highp vec3 sampleDiff0 = targetPixel - vSampledColor0;
  highp vec3 sampleDiff1 = targetPixel - vSampledColor1;
  highp vec3 sampleDiff2 = targetPixel - vSampledColor2;
  highp vec3 sampleDiff3 = targetPixel - vSampledColor3;
  highp vec3 sampleDiff4 = targetPixel - vSampledColor4;

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
  // Compute the source content to be blended with the render target content, as well as the mask
  // restricting the blended result to a certain subset of the pixels.
  mediump vec4 nonPremultipliedSourceContent = vColor;
  mediump float mask = opacity;

  mediump vec4 nonPremultipliedSource = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);

  // If required, always use the source texture as mask, independent of whether the overlay texture
  // is used.
  if (useSourceTextureAsMask) {
    mask *= nonPremultipliedSource.r;
  }

  if (sourceType == kSourceTypeSourceTexture && !useSourceTextureAsMask) {
    // Use the tinted sourceTexture value for blending, without any additional masking.
    nonPremultipliedSourceContent = nonPremultipliedSource * vColor;
  } else if (sourceType == kSourceTypeOverlayTexture) {
    highp vec4 overlayTextureCoord =
        overlayTextureCoordTransform * vec4((vPosition / vPosition.w).xy, 0.0, 1.0);
    mediump vec4 overlayTextureColor = texture2D(overlayTexture,
                                                 overlayTextureCoord.xy / overlayTextureCoord.w);
    if (useOverlayTextureAsMask) {
      // Use the overlayTexture as mask, possibly in addition to the mask provided by the
      // sourceTexture.
      mask *= overlayTextureColor.r;
    } else {
      // Use the tinted overlayTexture value for blending, possibly masked by the sourceTexture.
      nonPremultipliedSourceContent = overlayTextureColor * vColor;
    }
  }

  // Perform the blending of the content with the render target content.
  mediump vec4 premultipliedDst = premultipliedColor(gl_LastFragData[0]);
  mediump vec4 premultipliedSrc = premultipliedColor(nonPremultipliedSourceContent);

  mediump vec4 premultipliedBlendedColor = blendOfPremultipliedColors(premultipliedSrc,
                                                                      premultipliedDst, blendMode);

  // Perform the masking.
  mediump vec4 premultipliedBlendedAndMaskedColor =
      mix(premultipliedDst, premultipliedBlendedColor,
          mask * edgeAvoidanceFactor(length(premultipliedSrc)));

  if (renderTargetHasSingleChannel) {
    gl_FragColor = premultipliedBlendedAndMaskedColor;
  } else {
    gl_FragColor = nonPremultipliedColor(premultipliedBlendedAndMaskedColor);
  }
}

