// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kModePaint = 0;
const int kModeEraseDirect = 1;
const int kModeEraseIndirect = 2;
const int kModeBlend = 3;

uniform int mode;

uniform mediump sampler2D sourceTexture;
uniform lowp sampler2D inputImage;

uniform highp float sigma;
uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;
varying highp vec2 vImgcoord;

uniform highp vec2 samplePoint0;
uniform highp vec2 samplePoint1;
uniform highp vec2 samplePoint2;
uniform highp vec2 samplePoint3;
uniform highp vec2 samplePoint4;

// Blend the source and the target according to the normal alpha blending formula:
// http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
void normalNonPremultiplied(in highp vec4 src, in highp vec4 dst) {
  highp float a = src.a + dst.a - src.a * dst.a;
  highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;

  // If the result alpha is 0, the result rgb should be 0 as well.
  // safeA = (a <= 0) ? 1 : a;
  // gl_FragColor = (a <= 0) ? 0 : vec4(rgb / a, a);
  highp float safeA = a + (step(a, 0.0));
  gl_FragColor = clamp((1.0 - step(a, 0.0)) * vec4(rgb / safeA, a), 0.0, 1.0);
}

void main() {
  highp float brush = texture2D(sourceTexture, vTexcoord).r;

  highp vec3 inputImagePixel = texture2D(inputImage, vImgcoord).rgb;
  highp vec3 sampleDiff0 = inputImagePixel - texture2D(inputImage, samplePoint0).rgb;
  highp vec3 sampleDiff1 = inputImagePixel - texture2D(inputImage, samplePoint1).rgb;
  highp vec3 sampleDiff2 = inputImagePixel - texture2D(inputImage, samplePoint2).rgb;
  highp vec3 sampleDiff3 = inputImagePixel - texture2D(inputImage, samplePoint3).rgb;
  highp vec3 sampleDiff4 = inputImagePixel - texture2D(inputImage, samplePoint4).rgb;
  
  highp float rgbDist0 = dot(sampleDiff0, sampleDiff0);
  highp float rgbDist1 = dot(sampleDiff1, sampleDiff1);
  highp float rgbDist2 = dot(sampleDiff2, sampleDiff2);
  highp float rgbDist3 = dot(sampleDiff3, sampleDiff3);
  highp float rgbDist4 = dot(sampleDiff4, sampleDiff4);

  // The rgb (range) falloff of the current pixel is a minimum of the distances from the points
  // sampled at and around the center of the kernel.
  highp float rgbDist = sqrt(min(rgbDist0, min(min(rgbDist1, rgbDist2), min(rgbDist3, rgbDist4))));
  highp float factor = exp(-rgbDist / max(brush * sigma * 2.0, sigma));

  mediump vec4 previousColor = gl_LastFragData[0];
  if (mode == kModeEraseDirect) {
    highp vec4 newColor = brush * factor * intensity;
    gl_FragColor =
        clamp(max(previousColor - flow * newColor, 1.0 - opacity), vec4(0.0), previousColor);
  } else if (mode == kModeEraseIndirect) {
    highp vec4 newColor = brush * factor * intensity;
    gl_FragColor = clamp(max(previousColor - flow * newColor, -opacity), vec4(-1.0), previousColor);
  } else if (mode == kModeBlend) {
    highp vec4 newColor = intensity;
    newColor.a = min(newColor.a * flow * brush, opacity);
    normalNonPremultiplied(newColor, previousColor);
  } else {
    // Default mode is LTRoundBrushModePaint: regular painting.
    highp vec4 newColor = brush * factor * intensity;
    gl_FragColor = clamp(min(previousColor + flow * newColor, opacity), previousColor, vec4(1.0));
  }
}
