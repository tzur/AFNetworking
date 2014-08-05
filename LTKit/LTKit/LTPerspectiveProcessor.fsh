// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform sampler2D sourceTexture;
uniform highp mat3 perspective;
varying highp vec2 vTexcoord;

void main() {
  highp vec3 texcoord = vec3(vTexcoord, 1.0);
  texcoord.xy = texcoord.xy * 2.0 - 1.0;
  texcoord = perspective * texcoord;
  texcoord.xy /= texcoord.z;
  texcoord.xy = (texcoord.xy + 1.0) / 2.0;
  gl_FragColor = texture2D(sourceTexture, texcoord.xy);
  gl_FragColor *= float(all(bvec4(greaterThanEqual(texcoord.xy, vec2(0.0)),
                                    lessThanEqual(texcoord.xy, vec2(1.0)))));
}
