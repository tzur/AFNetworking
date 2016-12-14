// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kModeAdd = 0;
const int kModeSubtract = 1;

const int kMaskChannelR = 0;
const int kMaskChannelG = 1;
const int kMaskChannelB = 2;
const int kMaskChannelA = 3;

uniform mediump sampler2D sourceTexture;
uniform lowp sampler2D edgeAvoidanceGuideTexture;

uniform int mode;
uniform int channel;

uniform highp float flow;
uniform highp float hardness;
uniform highp float edgeAvoidance;

varying highp vec2 vQuadTransform;
varying highp vec2 vQuadCenter;
varying highp vec2 vSamplePoint0;
varying highp vec2 vSamplePoint1;
varying highp vec2 vSamplePoint2;
varying highp vec2 vSamplePoint3;

const highp float kEpsilon = 1e-6;

// Assumes sampleCoords0 is the center of the quad.
highp float edgeAvoidanceFactor(in highp float strength, in sampler2D guideTexture,
                                in highp float spatialFactor, in highp vec2 targetCoords,
                                in highp vec2 sampleCoords0, in highp vec2 sampleCoords1,
                                in highp vec2 sampleCoords2, in highp vec2 sampleCoords3,
                                in highp vec2 sampleCoords4) {
  if (edgeAvoidance <= 0.0) {
    return 1.0;
  }
  
  highp vec3 targetPixel = texture2D(guideTexture, targetCoords).rgb;
  
  highp vec3 sampleDiff0 = targetPixel - texture2D(guideTexture, sampleCoords0).rgb;
  highp vec3 sampleDiff1 = targetPixel - texture2D(guideTexture, sampleCoords1).rgb;
  highp vec3 sampleDiff2 = targetPixel - texture2D(guideTexture, sampleCoords2).rgb;
  highp vec3 sampleDiff3 = targetPixel - texture2D(guideTexture, sampleCoords3).rgb;
  highp vec3 sampleDiff4 = targetPixel - texture2D(guideTexture, sampleCoords4).rgb;
  
  highp float rgbDist0 = dot(sampleDiff0, sampleDiff0);
  highp float rgbDist1 = dot(sampleDiff1, sampleDiff1);
  highp float rgbDist2 = dot(sampleDiff2, sampleDiff2);
  highp float rgbDist3 = dot(sampleDiff3, sampleDiff3);
  highp float rgbDist4 = dot(sampleDiff4, sampleDiff4);
  
  // The rgb (range) falloff of the current pixel is a minimum of the distances from the points
  // sampled at and around the center of the kernel.
  highp float rgbDist = sqrt(min(rgbDist0, min(min(rgbDist1, rgbDist2), min(rgbDist3, rgbDist4))));
  
  strength = 1.0 + kEpsilon - strength;
  return exp(-rgbDist / max(spatialFactor * strength * 2.0, strength));
}

mediump vec4 maskForChannel(in int channel) {
  if (channel == kMaskChannelR) {
    return vec4(1.0, 0.0, 0.0, 0.0);
  } else if (channel == kMaskChannelG) {
    return vec4(0.0, 1.0, 0.0, 0.0);
  } else if (channel == kMaskChannelB) {
    return vec4(0.0, 0.0, 1.0, 0.0);
  } else if (channel == kMaskChannelA) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  } else {
    return vec4(0.0);
  }
}

void main() {
  highp vec2 texcoord = vTexcoord.xy / vTexcoord.z;
  highp float brush = texture2D(sourceTexture, texcoord).r;
  highp float factor = edgeAvoidanceFactor(edgeAvoidance, edgeAvoidanceGuideTexture, brush,
                                           vImgcoord, vQuadCenter, vSamplePoint0, vSamplePoint1,
                                           vSamplePoint2, vSamplePoint3);
  mediump vec4 channelsMask = maskForChannel(channel);
  mediump vec4 previousColor = gl_LastFragData[0];
  mediump vec4 newColor = previousColor;
  
  if (mode == kModeAdd) {
    newColor = min(vec4(1.0), previousColor + channelsMask * brush * factor * flow);
  } else if (mode == kModeSubtract) {
    newColor = max(vec4(-1.0), previousColor - channelsMask * brush * factor * flow);
  }
  gl_FragColor = newColor;
}
