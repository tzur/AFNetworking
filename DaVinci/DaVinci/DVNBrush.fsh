// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D auxiliaryTexture;
uniform highp float opacity;
uniform bool singleChannel;
uniform bool sampleFromAuxiliaryTexture;

varying highp vec3 vColor;
varying highp vec2 vPosition;
varying highp vec3 vTexcoord;

highp vec4 blend(highp vec4 src, highp vec4 dst) {
  highp float outA = src.a + dst.a * (1.0 - src.a);
  highp vec3 outRGB = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / outA;
  return vec4(outRGB, outA);
}

void main() {
  mediump vec4 src = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);
  
  if (singleChannel) {
    highp float alpha = opacity * src.r;
    
    if (sampleFromAuxiliaryTexture) {
      src = texture2D(auxiliaryTexture, vPosition);
      src.a *= alpha;
    } else {
      src = vec4(vColor, alpha);
    }
  }
  highp vec4 dst = gl_LastFragData[0];
  gl_FragColor = mix(dst, blend(src, dst), opacity);
}
