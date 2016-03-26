// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;

uniform highp float amplitude;
uniform highp float horizontalSeed;
uniform highp float verticalSeed;
uniform highp float velocitySeed;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  // For the oldest know reference to this formula see: http://web.archive.org/web/20080211204527/http://lumina.sourceforge.net/Tutorials/Noise.html
  highp float noise = fract(sin(dot(vTexcoord, vec2(9.0 + horizontalSeed, 99.0 + verticalSeed))) *
                            91390.0 + velocitySeed);
  noise = 0.5 + amplitude * (noise - 0.5);
  
  gl_FragColor = vec4(noise, noise, noise, 1.0);
}
