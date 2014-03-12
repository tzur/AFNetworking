// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// The goal of this shader is to tonally adjust the image. The adjustments can be categorized into
// the three following categories: luminance, levels, color and details. The luminance / color
// separation is done with YIQ color space.

// Source texture and its smoothed versions.
uniform sampler2D sourceTexture;
uniform sampler2D fineTexture;
uniform sampler2D coarseTexture;

// Tone and details LUTs.
uniform sampler2D toneLUT;
uniform sampler2D detailsLUT;

// Details control.
uniform highp float details;

// Color control.
uniform highp float saturation;
uniform highp float temperature;
uniform highp float tint;

varying highp vec2 vTexcoord;

void main() {
  // TODO:(zeev) Improve the details mapping using multiscale decomposition (coarse and fine) during
  // the next fine-tuning pass.
  fineTexture;
  
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  
  const mediump mat3 RGBtoYIQ = mat3(0.299, 0.596, 0.212,
                                     0.587, -0.274, -0.523,
                                     0.114, -0.322, 0.311);
  const mediump mat3 YIQtoRGB = mat3(1.0, 1.0, 1.0,
                                     0.9563, -0.2721, -1.107,
                                     0.621, -0.6474, 1.7046);
  const highp float kIMax = 0.596;
  const highp float kQMax = 0.523;
  const highp float kEps = 0.01;
  
  // Read textures and compute YIQ values.
  // Attention: since coarse texture chroma values are not needed in the process, this is a great
  // place to start optimizing the shader.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 fineColor = texture2D(fineTexture, vTexcoord);
  mediump vec4 coarseColor = texture2D(coarseTexture, vTexcoord);
  
  mediump vec3 yiq = RGBtoYIQ * color.rgb;
  mediump float lum = dot(color.rgb, kRGBToYPrime);
  mediump float coarse = dot(coarseColor.rgb, kRGBToYPrime) + kEps;
  
  // Details, shadows, highlights and fillLight.
  mediump float baseLayer = texture2D(detailsLUT, vec2(coarse, 0.0)).r;
  yiq.r = clamp(baseLayer * lum / coarse + (lum - coarse) * details, 0.0, 1.0);
  
  // Color: saturation, temperature and tint.
  yiq.g = clamp((yiq.g + temperature) * saturation, -kIMax, kIMax);
  yiq.b = clamp((yiq.b + tint) * saturation, -kQMax, kQMax);
  color.rgb = YIQtoRGB * yiq;
  
  // Tone, Levels and Curves.
  color.r = texture2D(toneLUT, vec2(color.r, 0.0)).r;
  color.g = texture2D(toneLUT, vec2(color.g, 0.0)).r;
  color.b = texture2D(toneLUT, vec2(color.b, 0.0)).r;
  
  gl_FragColor = color;
}
