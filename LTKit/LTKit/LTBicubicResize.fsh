// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader implements bicubic filtering with cubic B-spline kernel. Leveraging on the fact that
// sampling texture with bilinear kernel is similar in cost to nearest neighbor, it re-formulates
// the problem so only 4 texture reads are performed.
// Notice that B-spline weights are all positive, thus it lacks the negative lobes that cause the
// sharpening associated with a standard bicubic filtering.
// Adobe Photoshop resampling mode that most closely matches this kernel is Bicubic Smoother
// (enlargement).
//
// Relevant references.
// 1. SO discussion: http://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl
// 2. GPU Gems 2, Chapter 20. Excerpt: http://http.download.nvidia.com/developer/SDK/Individual_Samples/DEMOS/OpenGL/src/fast_third_order/docs/Gems2_ch20_SDK.pdf

uniform sampler2D sourceTexture;
uniform highp vec2 texelOffset;

varying highp vec2 vTexcoord;

// Construct basis functions give the position of the sample on [0-1] interval.
// Uniform Cubic B-Spline Curve: http://www2.cs.uregina.ca/~anima/408/Notes/Interpolation/UniformBSpline.htm
highp vec4 cubic(highp float x) {
  highp float x2 = x * x;
  highp float x3 = x2 * x;
  highp vec4 rhs = vec4(x3, x2, x, 1.0);
  // B-spline basis functions.
  const highp mat4 spline = mat4(-1.0,  3.0, -3.0, 1.0,  // First column.
                                  3.0, -6.0,  3.0, 0.0,  // Second column.
                                 -3.0,  0.0,  3.0, 0.0,  // Third column.
                                  1.0,  4.0,  1.0, 0.0); // Fourth columm.
  return spline * rhs / 6.0;
  

}

highp vec4 filter(sampler2D texture, highp vec2 texcoord, highp vec2 texscale) {
  // texcoord is in the coordinate system of the source image dimensions.
  highp float fx = fract(texcoord.x);
  highp float fy = fract(texcoord.y);
  texcoord.x -= fx;
  texcoord.y -= fy;
  
  // Construct B-Spline in each dimension.
  highp vec4 xcubic = cubic(fx);
  highp vec4 ycubic = cubic(fy);
  
  // Compute the offests.
  highp vec4 c = vec4(texcoord.x - 0.5, texcoord.x + 1.5, texcoord.y - 0.5, texcoord.y + 1.5);
  highp vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y,
                      ycubic.z + ycubic.w);
  highp vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;
  
  // Sample using bilinear interpolation. Won't produce correct results if nearest neighbour is
  // defined for the source texture.
  highp vec4 sample0 = texture2D(texture, vec2(offset.x, offset.z) * texscale);
  highp vec4 sample1 = texture2D(texture, vec2(offset.y, offset.z) * texscale);
  highp vec4 sample2 = texture2D(texture, vec2(offset.x, offset.w) * texscale);
  highp vec4 sample3 = texture2D(texture, vec2(offset.y, offset.w) * texscale);
  
  highp float sx = s.x / (s.x + s.y);
  highp float sy = s.z / (s.z + s.w);
  
  return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

void main() {
  gl_FragColor = filter(sourceTexture, vTexcoord * 1.0/texelOffset, texelOffset);
}
