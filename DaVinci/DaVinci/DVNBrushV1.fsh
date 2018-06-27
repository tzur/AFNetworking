// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#extension GL_EXT_shader_framebuffer_fetch : require

/// Single-channel or RGBA texture, in premultiplied format, mapped onto the brush tip quad.
uniform highp sampler2D sourceTexture;

/// \c YES if the \c sourceTexture is in non-premultiplied format.
uniform bool sourceTextureIsNonPremultiplied;

/// Enumeration value determining how to sample the \c sourceTexture.
uniform int sourceTextureSampleMode;

/// Value for \c sourceTextureSampleMode indicating that the values of \c vTexcoord should be used
/// as texture coordinates for sampling the \c sourceTexture.
const int kSourceTextureSampleModeTexcoord = 0;

/// Value for \c sourceTextureSampleMode indicating that the interpolated vertex positions should be
/// used as texture coordinates for sampling the \c sourceTexture.
const int kSourceTextureSampleModeVertexPosition = 1;

/// Value for \c sourceTextureSampleMode indicating that the quad center should be used as texture
/// coordinate for sampling the \c sourceTexture.
const int kSourceTextureSampleModeQuadCenter = 2;

/// Single-channel texture used as mask of the brush tip quad.
uniform highp sampler2D maskTexture;

/// Edge avoidance factor. Must be in range <tt>[0, 1]</tt>.
uniform highp float edgeAvoidance;

/// Single-channel or RGBA texture, in non-premultiplied or premultiplied format, used for computing
/// the edges potentially restricting the rendering.
uniform highp sampler2D edgeAvoidanceGuideTexture;

/// Flow used per rendered quad. Must be in range <tt>[0, 1]</tt>.
uniform highp float flow;

/// Linear transformation for transforming the texture coordinate system used for sampling the
/// \c sourceTexture.
uniform highp mat4 sourceTextureCoordTransform;

/// \c YES if the render target has a single channel.
uniform bool renderTargetHasSingleChannel;

/// \c YES if the render target is in non-premultiplied format.
uniform bool renderTargetIsNonPremultiplied;

/// Blend mode to be used for blending.
uniform int blendMode;

/// RGBA color, in premultiplied format.
varying highp vec4 vPremultipliedColor;
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
const int kBlendModeOpaqueSource = 12;
const int kBlendModeOpaqueDestination = 13;

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
  highp vec3 below = 2.0 * src.rgb * dst.rgb + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  highp vec3 above = src.rgb * (1.0 + dst.a) + dst.rgb * (1.0 + src.a) - src.a * dst.a - 2.0 *
      src.rgb * dst.rgb;
  return vec4(mix(below, above, step(0.5 * src.a, src.rgb)), src.a + dst.a - src.a * dst.a);
}

highp vec4 softLight(highp vec4 src, highp vec4 dst) {
  highp float safeA = dst.a + step(dst.a, 0.0);
  highp vec3 below = 2.0 * src.rgb * dst.rgb + dst.rgb * (dst.rgb / safeA) *
      (src.a - 2.0 * src.rgb) + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  highp vec3 above = 2.0 * dst.rgb * (src.a - src.rgb) + sqrt(dst.rgb * dst.a) *
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
  highp float safeA = dst.a + step(dst.a, 0.0);
  highp vec3 stepRGB = step(src.rgb, vec3(0.0));
  highp vec3 safeRGB = src.rgb + stepRGB;
  highp vec3 zero = src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  highp vec3 nonzero = src.a * dst.a * (vec3(1.0) - min(vec3(1.0), (1.0 - dst.rgb / safeA) *
      src.a / safeRGB)) + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  return vec4(mix(zero, nonzero, 1.0 - stepRGB), src.a + dst.a - src.a * dst.a);
}

highp vec4 overlay(highp vec4 src, highp vec4 dst) {
  highp vec3 below = 2.0 * src.rgb * dst.rgb + src.rgb * (1.0 - dst.a) + dst.rgb * (1.0 - src.a);
  highp vec3 above = src.rgb * (1.0 + dst.a) + dst.rgb * (1.0 + src.a) - 2.0 * dst.rgb * src.rgb -
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

highp vec4 blendOfPremultipliedColors(highp vec4 src, highp vec4 dst, int mode) {
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
  } else if (blendMode == kBlendModeOpaqueSource) {
    premultipliedOutputColor = src;
  } else if (blendMode == kBlendModeOpaqueDestination) {
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

highp vec4 premultipliedColor(in highp vec4 nonPremultipliedColor) {
  return vec4(nonPremultipliedColor.rgb * nonPremultipliedColor.a, nonPremultipliedColor.a);
}

highp vec4 nonPremultipliedColor(in highp vec4 premultipliedColor) {
  highp float safeA = premultipliedColor.a + step(premultipliedColor.a, 0.0);
  return vec4(premultipliedColor.rgb / safeA, premultipliedColor.a);
}

void main() {
  highp vec4 premultipliedContent = vPremultipliedColor;

  highp vec4 sourceColor = vec4(1);

  // Compute the content to be blended with the render target content, as well as the mask
  // restricting the blended result to a certain subset of the pixels.
  if (sourceTextureSampleMode == kSourceTextureSampleModeTexcoord) {
    sourceColor = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);
  } else if (sourceTextureSampleMode == kSourceTextureSampleModeVertexPosition) {
    highp vec4 homogeneousSourceTextureCoord =
        sourceTextureCoordTransform * vec4((vPosition / vPosition.w).xy, 0.0, 1.0);
    sourceColor = texture2D(sourceTexture,
                            homogeneousSourceTextureCoord.xy / homogeneousSourceTextureCoord.w);
  } else {
    // No need to deal with sourceTextureSampleMode equalling kSourceTextureSampleModeQuadCenter at
    // this point since the sampling is assumed to already have been performed in the vertex shader.
  }

  if (sourceTextureIsNonPremultiplied) {
    premultipliedContent *= premultipliedColor(sourceColor);
  } else {
    premultipliedContent *= sourceColor;
  }

  highp float mask = texture2D(maskTexture, vTexcoord.xy / vTexcoord.z).r * flow;

  // Perform the blending of the content with the render target content.
  highp vec4 premultipliedDst;

  if (renderTargetIsNonPremultiplied) {
    premultipliedDst = premultipliedColor(gl_LastFragData[0]);
  } else {
    premultipliedDst = gl_LastFragData[0];
  }

  highp vec4 premultipliedSrc = premultipliedContent;
  highp vec4 premultipliedBlendedColor = blendOfPremultipliedColors(premultipliedSrc,
                                                                    premultipliedDst, blendMode);

  // Perform the masking.
  highp vec4 premultipliedBlendedAndMaskedColor =
      mix(premultipliedDst, premultipliedBlendedColor,
          mask * edgeAvoidanceFactor(length(premultipliedSrc)));

  if (renderTargetHasSingleChannel || !renderTargetIsNonPremultiplied) {
    gl_FragColor = premultipliedBlendedAndMaskedColor;
  } else {
    gl_FragColor = nonPremultipliedColor(premultipliedBlendedAndMaskedColor);
  }
}
