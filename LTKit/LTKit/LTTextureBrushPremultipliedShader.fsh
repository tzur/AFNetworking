// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 dst = gl_LastFragData[0];
  highp vec4 src = texture2D(sourceTexture, vTexcoord) * intensity;
  highp float baseA = src.a;
  src.a = min(src.a * flow, opacity);
  src.rgb *= src.a / baseA;
  
  highp vec3 rgb = src.rgb + (1.0 - src.a) * dst.rgb;
  highp float a = dst.a + (1.0 - dst.a) * src.a;
  
  gl_FragColor = vec4(rgb, a);
}
