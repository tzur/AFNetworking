// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies an effect that mimics an appearance of vintage camera.
// Many concepts here are similar to LTBWProcessorFsh, since big part of the conversion is built
// upon applying a color gradient on the luminance of the input.

uniform sampler2D sourceTexture;
// Details texures is assumed to be luminance.
uniform sampler2D detailsTexture;
// Tileable texture or texture of the size of the image.
uniform sampler2D grainTexture;
// Texture with the aspect ratio of the image.
uniform sampler2D vignettingTexture;
// Square texture, RGB channels of this texture are blended using screen mode and thus is neutral to
// black. Alpha channel of this texture is blended in overlay mode and this is neutral to grey. The
// mapping is an aspect fill of the texture image to the content image, where origins of both images
// are mapped one to another.
uniform sampler2D assetTexture;
// RGB channels hold luminance-to-color mapping, while alpha channel hold luminance-to-luminance
// mapping.
uniform sampler2D colorGradientTexture;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform mediump float structure;
uniform mediump float saturation;
uniform mediump float vignetteIntensity;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;
uniform mediump float colorGradientIntensity;
uniform mediump float colorGradientFade;
uniform mediump float lightLeakIntensity;
uniform mediump vec2 frameWidth;
// Width / Height.
uniform mediump float aspectRatio;

// Sca - scource, top.
// Dca - destination, bottom.
mediump float overlay(in mediump float Sca, in mediump float Dca) {
  mediump float below = 2.0 * Sca * Dca;
  mediump float above = Sca * 2.0 + Dca * 2.0 - 2.0 * Dca * Sca - 1.0;
  
  return mix(below, above, step(0.5, Dca));
}

mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca) {
  mediump vec3 below = 2.0 * Sca * Dca;
  mediump vec3 above = Sca * 2.0 + Dca * 2.0 - 2.0 * Dca * Sca - 1.0;
  
  return mix(below, above, step(0.5, Dca));
}

mediump vec3 softLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  // safeX = (x <= 0) ? 1 : x;
  mediump float safeDa = Da + step(Da, 0.0);

  mediump vec3 below = 2.0 * Sca * Dca + Dca * (Dca / safeDa) * (Sa - 2.0 * Sca) + Sca * (1.0 - Da)
      + Dca * (1.0 - Sa);
  mediump vec3 above = 2.0 * Dca * (Sa - Sca) + sqrt(Dca * Da) * (2.0 * Sca - Sa) + Sca * (1.0 - Da)
      + Dca * (1.0 - Sa);

  return mix(below, above, step(0.5, Sca));
}

mediump vec3 screen(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return Sca + Dca - Sca * Dca;
}

mediump vec2 getLightCoordinates(in mediump vec2 coords, in mediump float ratio) {
  return coords * vec2(ratio, 1.0);
}

mediump vec2 getFrameCoordinates(in mediump vec2 coords, in mediump vec2 width,
                                 in mediump float ratio) {
  highp vec2 frameCoords;
  frameCoords.y = mix(coords.y - width.y, coords.y + width.y, step(0.5, coords.y));
  frameCoords.x = mix((coords.x - width.x) * ratio,
                      1.0 - (1.0 - coords.x - width.x) * ratio, step(0.5, coords.x));
  return frameCoords;
}

const mediump mat3 kRGBtoYIQ = mat3(0.299, 0.596, 0.212,
                                    0.587, -0.274, -0.523,
                                    0.114, -0.322, 0.311);
const mediump mat3 kYIQtoRGB = mat3(1.0, 1.0, 1.0,
                                    0.9563, -0.2721, -1.107,
                                    0.621, -0.6474, 1.7046);

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec3 outputColor = color.rgb;

  // 1. Textures: light leak and frame.
  mediump vec2 frameCoords = mix(getFrameCoordinates(vTexcoord, frameWidth, aspectRatio),
      getFrameCoordinates(vTexcoord.yx, frameWidth.yx, 1.0 / aspectRatio).yx,
      step(1.0, aspectRatio));

  mediump vec2 lightCoords = mix(getLightCoordinates(vTexcoord, aspectRatio),
      getLightCoordinates(vTexcoord.yx, 1.0 / aspectRatio).yx,
      step(1.0, aspectRatio));

  mediump float frame = texture2D(assetTexture, frameCoords).a;
  mediump vec3 lightLeak = texture2D(assetTexture, lightCoords).rgb;

  // 2. Local contrast.
  // For positive structure values, details textures is interpolated with original image. For
  // negative values, a smooth layer is created assuming the following identity:
  // details = smooth + boost * (original - smooth)
  // For CLAHE process that is used to create the details texture, boost = 3.5 is a reasonable
  // value.
  mediump vec3 yiq = kRGBtoYIQ * outputColor.rgb;
  mediump float details = texture2D(detailsTexture, vTexcoord).r;
  mediump float lum = mix(yiq.r, mix(-0.4 * (details - 3.5 * yiq.r), details, step(0.0, structure)),
                          abs(structure));

  // 3. Saturation.
  outputColor = clamp(kYIQtoRGB * vec3(lum, yiq.gb * saturation), 0.0, 1.0);

  // 4. Vignetting.
  mediump float vignette = texture2D(vignettingTexture, vTexcoord).r;
  mediump vec3 vignetteRGB = vec3(mix(0.5, 0.5 + 1.0 * (vignetteIntensity - 0.5), vignette));
  mediump vec3 soft = overlay(vignetteRGB, outputColor);
  mediump vec3 harsh = overlay(outputColor, vignetteRGB);
  outputColor = mix(soft, harsh, 0.5);
  outputColor = clamp(outputColor, 0.0, 1.0);

  // 5. Frame.
  // Frame is applied on both color and luminance, so it is completely transparent for any
  // configuration of colorGradient.
  lum = overlay(lum, frame);
  outputColor = overlay(outputColor, vec3(frame));

  // 6. Color gradient.
  // Suggested method to fine-tune the color gradient mapping is to create an appropriate adjustment
  // layers in Adobe Photoshop.
  mediump vec3 colorGradient = texture2D(colorGradientTexture, vec2(lum)).rgb;
  outputColor = mix(outputColor, clamp(outputColor, vec3(0.3), vec3(0.7)), colorGradientFade);
  outputColor = softLight(colorGradient * colorGradientIntensity, outputColor,
                          colorGradientIntensity, 1.0);

  // 7. Tonal adjustment.
  outputColor.r = texture2D(colorGradientTexture, vec2(outputColor.r, 0.0)).a;
  outputColor.g = texture2D(colorGradientTexture, vec2(outputColor.g, 0.0)).a;
  outputColor.b = texture2D(colorGradientTexture, vec2(outputColor.b, 0.0)).a;
  outputColor = clamp(outputColor, 0.0, 1.0);

  // 8. Grain.
  mediump float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  outputColor = overlay(vec3(mix(0.5, grain, grainAmplitude)), outputColor);

  // 9. Light Leak
  outputColor = screen(lightLeak * lightLeakIntensity, outputColor, lightLeakIntensity, 1.0);

  gl_FragColor = vec4(outputColor, color.a);
}
