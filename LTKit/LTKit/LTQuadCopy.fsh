// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform sampler2D sourceTexture;

uniform bool useAlphaValues;

varying highp vec2 vTexcoord;

void main() {
  if (useAlphaValues) {
    mediump vec4 back = gl_LastFragData[0];
    mediump vec4 front = texture2D(sourceTexture, vTexcoord);

    // Define variables as they appear in SVG spec. See http://www.w3.org/TR/SVGCompositing/.
    mediump vec3 Sca = front.rgb;
    mediump vec3 Dca = back.rgb;
    mediump float Sa = front.a;
    mediump float Da = back.a;

    // Use src-over composition.
    gl_FragColor.rgb = Sca + Dca * (1.0 - Sa);
    gl_FragColor.a = Sa + Da - Sa * Da;
  } else {
    gl_FragColor = texture2D(sourceTexture, vTexcoord);
  }
}
