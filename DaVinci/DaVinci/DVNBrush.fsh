// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D overlayTexture;
uniform mediump sampler2D edgeAvoidanceGuideTexture;
uniform highp float opacity;
uniform highp float edgeAvoidance;
uniform bool singleChannel;
uniform bool sampleFromOverlayTexture;

varying highp vec3 vColor;
varying highp vec2 vPosition;
varying highp vec3 vTexcoord;
varying highp vec2 vQuadCenter;
varying highp vec2 vSamplePoint0;
varying highp vec2 vSamplePoint1;
varying highp vec2 vSamplePoint2;
varying highp vec2 vSamplePoint3;

highp vec4 blend(highp vec4 src, highp vec4 dst) {
  highp float outA = src.a + dst.a * (1.0 - src.a);
  highp vec3 outRGB = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / outA;
  return vec4(outRGB, outA);
}

highp float edgeAvoidanceFactor(in highp float spatialFactor) {
  const highp float kEpsilon = 1e-6;
  
  if (edgeAvoidance <= 0.0) {
    return 1.0;
  }
  highp vec3 targetPixel = texture2D(edgeAvoidanceGuideTexture, vPosition).rgb;
  
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

void main() {
  mediump vec4 src = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);
  
  if (singleChannel) {
    highp float alpha = opacity * src.r;
    
    if (sampleFromOverlayTexture) {
      src = texture2D(overlayTexture, vPosition);
      src.a *= alpha;
    } else {
      src = vec4(vColor, alpha);
    }
  }
  highp vec4 dst = gl_LastFragData[0];
  gl_FragColor = mix(dst, blend(src, dst), opacity * edgeAvoidanceFactor(length(src)));
}
