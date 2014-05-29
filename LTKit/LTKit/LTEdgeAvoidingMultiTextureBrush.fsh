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

varying highp vec2 vTexcoord;
varying highp vec2 vImgcoord;

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
  if (sigma < 1.0) {
    highp float rgbDist = dot(rgbDiff, rgbDiff);
    highp float spatialDistanceFactor = texture2D(gaussianTexture, vTexcoord).r;
    highp float factor = exp(-rgbDist / max(spatialDistanceFactor * sigma, sigma));
    src.a *= factor;
  }
  
  if (premultiplied) {
    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    // Update the rgb channels with the ratio, since we assume premultiplied alpha.
    highp float baseA = src.a;
    src.a = min(src.a * flow, opacity);
    src.rgb *= src.a / baseA;
    
    // Blend the source and the target according to the normal alpha blending formula:
    // http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
    // Note that we're assuming both the source and destination are premultiplied, and that the result
    // should be premultiplied as well, hence the differences in the implemented formula.
    highp vec3 rgb = src.rgb + (1.0 - src.a) * dst.rgb;
    highp float a = dst.a + (1.0 - dst.a) * src.a;
    
    gl_FragColor = vec4(rgb, a);
  } else {
    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    src.a = min(src.a * flow, opacity);
    
    // Blend the source and the target according to the normal alpha blending formula:
    // http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
    highp float a = dst.a + (1.0 - dst.a) * src.a;
    highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;
    
    // If the result alpha is 0, the result rgb should be 0 as well.
    // safeA = (a <= 0) ? 1 : a;
    // gl_FragColor = (a <= 0) ? 0 : vec4(rgb / a, a);
    highp float safeA = a + (step(a, 0.0));
    gl_FragColor = (1.0 - step(a, 0.0)) * vec4(rgb / safeA, a);
  }
}
