// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform sampler2D sourceTexture;
uniform highp mat3 perspective;
uniform highp vec2 aspectFactor;
uniform highp vec2 distortionScaleCompensation;
uniform highp float distortion;

varying highp vec2 vTexcoord;

void main() {
  // Map the texture coordinates from [0,1]x[0,1] to [-1,1]x[-1,1].
  highp vec3 texcoord = vec3(vTexcoord, 1.0);
  texcoord.xy = texcoord.xy * 2.0 - 1.0;
  
  // Apply the perspective transformation.
  texcoord = perspective * texcoord;
  texcoord.xy /= texcoord.z;

  // Apply the barrel/pincushion distortion.
  texcoord.xy *= 0.5 * aspectFactor;
  texcoord.xy *= (1.0 + distortion * dot(texcoord.xy, texcoord.xy));
  texcoord.xy /= distortionScaleCompensation * aspectFactor;

  // Map back to texture coordindates.
  texcoord.xy += 0.5;
  gl_FragColor = texture2D(sourceTexture, texcoord.xy);
  
  // Every fragment mapped to a point outside the texture is set to transparent black.
  gl_FragColor *= float(all(bvec4(greaterThanEqual(texcoord.xy, vec2(0.0)),
                                    lessThanEqual(texcoord.xy, vec2(1.0)))));
}
