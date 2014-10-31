// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader perform a rich BW conversion. The conversion has the following steps:
// 1. Color filter effect applied on the image. Color filter effect mimics an actual physical filter
// that can be mounted on the camera lens, by weighting contribution of the RGB channels in the
// conversion process. An additional degree of creative freedom is added, by allowing a negative
// contribution from the channels, which creates a stronger contrast between the regions of
// different color. Details texture undergoes conversion compensation process, in order to simulate
// how it would look with the current color filter, without actually passing RGB values.
//
// 2. Local contrast is boosted by linearly interpolating between the luminance and the details
// texture. The details texture is created with Contrast Limited Adaptive Histogram Equalization,
// for more details: Zuiderveld, Karel. "Contrast Limited Adaptive Histogram Equalization." Graphic
// Gems IV. San Diego: Academic Press Professional, 1994. 474–485.
//
// 3. Tonal adjustments are added. Tonal LUT is typically a combination of brightness, contrast,
// exposure and other functions which together can be represented as a single curve on the
// luminance channel.
//
// 4. Vignetting pattern is added to the image. The values in vignettingTexture indicate how strong
// the vignetting effect should be, 0 no effect and all and 1 for a maximum effect. Vignetting can
// be dark or bright: this is set by vignetteIntensity, 0 for the dark vignetting and 1 for bright
// vignetting. In order to create a realistic appearance of the vignetting overlay blending mode is
// used. Prior to blending, the vignette values are remapped around 0.5, which is neutral value of
// the overlay mode. Combination of the two blending operations is used: vignetting pattern above
// the image and vignetting pattern bellow the image. The former creates a soft vignetting pattern,
// almost invisible in black/white regions. The later creates more harsh pattern. It is left for a
// future work to try and simplify the combined blending operation in order to make it more
// efficient. An interesting direction suggested by Alger is to think about blending in terms of
// abstract algebra, for example the above blending in a sense measures the non-commutativity of the
// overlay blending operation.
//
// 5. Frame is mapped using a "throw-cut" algorithm. This algorithm linearly maps the large
// dimension of the image to the texture. For the smaller dimension it cuts the central part, so for
// example if the width is one-third of the height, two-third central columns of the image are
// "thrown" and not used in the mapping process. This mapping strategy is valuable in the situation
// where frame exhibit little variation in the central parts. One practical advantage of this method
// is that the size of the frame insets on the square texture and the mapped rectangular images
// appear similar, making the frame design process easier.
//
// 6. Grain is added to the image. In order to simulate a visually appealing grain, a blurred
// gaussian noise is used in overlay mode. The noise is precomputed with 3 radii: 0.1, 0.6, 1.2.
// The grain value is computed by averaging the channels grainChannelMixer.
//
// 7. Color gradient, which is used to tint the luminance is added to the image. In order to make
// the color to appear more faded, colorGradientFade parameter is used to to move the luminance
// values closed to the midpoint.

uniform sampler2D sourceTexture;
// Details texures is assumed to be luminance.
uniform sampler2D detailsTexture;
// Tileable texture or texture of the size of the image.
uniform sampler2D grainTexture;
// Texture with the aspect ration of the image.
uniform sampler2D vignettingTexture;
// Square texture that is mapped with "throw-cut" algorithm.
uniform sampler2D frameTexture;
// RGB channels hold luminance-to-color mapping, while alpha channel hold luminance-to-luminance
// mapping.
uniform sampler2D colorGradient;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform mediump float structure;
uniform mediump vec3 colorFilter;
uniform mediump float vignetteIntensity;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;
uniform mediump float colorGradientFade;
uniform mediump vec2 frameWidth;
// Combined aspect ratio takes into the account both aspect ratio of the image and of the frame. See
// LTBWProcessor for the details.
uniform mediump float combinedAspectRatio;
uniform mediump float flipFrameCoordinates;

// Sc - scource, top.
// Dc - destination, bottom.
mediump float overlay(in mediump float Sca, in mediump float Dca, in mediump float Sa,
                      in mediump float Da) {
  mediump float below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump float above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;
  
  return mix(below, above, step(0.5 * Da, Dca));
}

mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                     in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;
  
  return mix(below, above, step(0.5 * Da, Dca));
}

mediump vec2 getFrameCoordinates(in mediump vec2 coords, in mediump vec2 width,
                                 in mediump float ratio) {
  highp vec2 frameCoords;
  frameCoords.y = mix(coords.y - width.y, coords.y + width.y, step(0.5, coords.y));
  frameCoords.x = mix((coords.x - width.x) * ratio,
                      1.0 - (1.0 - coords.x - width.x) * ratio, step(0.5, coords.x));
  return frameCoords;
}

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  
  // 1. Color filter.
  mediump float lum = dot(color.rgb, colorFilter);
  
  // 2. Local contrast.
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  mediump float neutral = dot(color.rgb, kRGBToYPrime) + 0.01;
  // For positive detailsBoost values, details textures is interpolated with original image. For
  // negative values, a smooth layer is created assuming the following identity:
  // details = smooth + boost * (original - smooth)
  // For CLAHE process that is used to create the details texture, boost = 3.5 is a reasonable
  // value.
  mediump float details = texture2D(detailsTexture, vTexcoord).r * (lum / neutral);
  lum = mix(lum, mix(-0.4 * (details - 3.5 * lum), details, step(0.0, structure)),
            abs(structure));
  
  // 3. Tonal adjustment.
  lum = texture2D(colorGradient, vec2(lum, 0.0)).a;
  
  // 4. Vignetting.
  mediump float vignette = texture2D(vignettingTexture, vTexcoord).r;
  mediump float soft = overlay(mix(0.5, vignetteIntensity, vignette), lum, 1.0, 1.0);
  mediump float harsh = overlay(lum, mix(0.5, vignetteIntensity, vignette), 1.0, 1.0);
  lum = mix(soft, harsh, 0.3);
  
  // 5. Frame.
  mediump vec2 coords =
      mix(getFrameCoordinates(vTexcoord, frameWidth, combinedAspectRatio),
          getFrameCoordinates(vTexcoord.yx, frameWidth.yx, 1.0 / combinedAspectRatio).yx,
          step(1.0, combinedAspectRatio));
  coords = mix(coords, coords.yx, flipFrameCoordinates);
  lum = overlay(lum, texture2D(frameTexture, coords).r, 1.0, 1.0);
  
  // 6. Grain.
  mediump float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  lum = overlay(mix(0.5, grain, grainAmplitude), lum, 1.0, 1.0);
  
  // 7. Apply color gradient.
  mediump vec4 outputColor = texture2D(colorGradient, vec2(mix(lum, 0.5, colorGradientFade), 0.0));
  
  gl_FragColor = vec4(outputColor.rgb, 1.0);
}
