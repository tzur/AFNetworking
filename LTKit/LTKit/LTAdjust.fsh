// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// The goal of this shader is to tonally adjust the image. The adjustments can be categorized into
// the three following categories: luminance, levels, color and details. The luminance / color
// separation is done with YIQ color space.

uniform sampler2D sourceTexture;
uniform sampler2D fineTexture;
uniform sampler2D coarseTexture;

// Luminance control.
uniform highp float brightness;
uniform highp float contrast;
uniform highp float exposure;
uniform highp float offset;
// Levels control.
uniform highp vec3 whitePoint;
uniform highp vec3 blackPoint;
// Color control.
uniform highp float saturation;
uniform highp float temperature;
uniform highp float tint;
// Luminance control.
uniform highp float shadows;
uniform highp float fillLight;
uniform highp float highlights;
uniform highp float details;

varying highp vec2 vTexcoord;

void main() {
  brightness;
  contrast;
  exposure;
  offset;
  whitePoint;
  blackPoint;
  saturation;
  temperature;
  tint;
  shadows;
  fillLight;
  highlights;
  details;
  
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  
  const mediump mat3 RGBtoYIQ = mat3(0.299, 0.596, 0.212, 0.587, -0.274, -0.523, 0.114, -0.322,
                                     0.311);
  const mediump mat3 YIQtoRGB = mat3(1.0, 1.0, 1.0, 0.9563, -0.2721, -1.107, 0.621, -0.6474,
                                     1.7046);
  const mediump float kYIQChromaAbsMax = 0.5226;
  
  // Read textures and compute YIQ values.
  // Attention: since fine and coarse texture chroma values do not needed in the process, this is
  // a great place to start optimizing the shader.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 fineColor = texture2D(fineTexture, vTexcoord);
  mediump vec4 coarseColor = texture2D(coarseTexture, vTexcoord);
  
  mediump vec3 yiq = RGBtoYIQ * color.rgb;
  mediump float lum = dot(color.rgb, kRGBToYPrime);
  mediump float yFine = dot(fineColor.rgb, kRGBToYPrime);
  mediump float yCoarse = dot(coarseColor.rgb, kRGBToYPrime);
  
  // Color: saturation, temperature and tint.
  yiq.g = clamp((yiq.g + temperature) * saturation, -kYIQChromaAbsMax, kYIQChromaAbsMax);
  yiq.b = clamp((yiq.b + tint) * saturation, -kYIQChromaAbsMax, kYIQChromaAbsMax);
  color.rgb = YIQtoRGB * yiq;
  
  // Tone, Levels and Curves
  color.rgb = color.rgb * exposure + offset;
  color.rgb = (color.rgb - blackPoint) / (whitePoint - blackPoint);
  
  //  lum = smoothLum + structure * (lum - smoothLum);
  //  lum = brightness + 0.5 + contrast * (exposure * lum - 0.5);
  
  //  color.rgb = texture2D(colorGradient, vec2(lum, 0.0)).rgb;
  
  //  gl_FragColor = vec4(vec3(abs(yiq.r-lum)), color.a);
  gl_FragColor = color;
}
