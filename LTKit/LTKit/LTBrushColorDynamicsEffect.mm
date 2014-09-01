// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushColorDynamicsEffect.h"

#import "LTCGExtensions.h"
#import "LTTexture.h"
#import "LTRandom.h"
#import "LTRotatedRect.h"
#import "UIColor+Vector.h"

@implementation LTBrushColorDynamicsEffect

#pragma mark -
#pragma mark Effect
#pragma mark -

static const CGRect kNormalRect = CGRectMake(0, 0, 1, 1);

- (NSArray *)colorsFromRects:(NSArray *)rects baseColor:(UIColor *)baseColor {
  LTParameterAssert(rects);
  LTParameterAssert(baseColor);
  NSMutableArray *colors = [NSMutableArray array];
  NSArray *baseColorsFromTexture = [self baseColorsFromTextureForRects:rects];
  [rects enumerateObjectsUsingBlock:^(LTRotatedRect *rect, NSUInteger idx, BOOL *) {
    UIColor *color = baseColorsFromTexture ? baseColorsFromTexture[idx] : baseColor;
    [colors addObject:[self randomColorFromRect:rect baseColor:color]];
  }];
  return colors;
}

// TODO:(amit) the rect might be used when different control methods will be implemented, for
// example, based on the size of the rect, etc.
- (UIColor *)randomColorFromRect:(LTRotatedRect __unused *)rect baseColor:(UIColor *)color {
  CGFloat randomHueJitter = [self.random randomDoubleBetweenMin:-self.hueJitter max:self.hueJitter];
  CGFloat randomSaturationJitter =
      [self.random randomDoubleBetweenMin:-self.saturationJitter max:self.saturationJitter];
  CGFloat randomBrightnessJitter =
      [self.random randomDoubleBetweenMin:-self.brightnessJitter max:self.brightnessJitter];

  CGFloat h, s, b, a;
  if (![color getHue:&h saturation:&s brightness:&b alpha:&a]) {
    return color;
  }
  
  // Hue should be cyclic, while saturation and brightness are clamped in [0,1].
  CGFloat newHue = h + randomHueJitter;
  return [UIColor colorWithHue:(newHue >= 0) ? newHue - std::floor(newHue) : 1.0 + newHue
                    saturation:std::clamp(s + randomSaturationJitter, 0, 1)
                    brightness:std::clamp(b + randomBrightnessJitter, 0, 1)
                         alpha:a];
}

- (NSArray *)baseColorsFromTextureForRects:(NSArray *)rects {
  if (!self.baseColorTexture) {
    return nil;
  }
  
  // We're sampling at pixel centers, so size is multiplied by the texture size - 1.
  CGPoints targets;
  CGSize textureSize = self.baseColorTexture.size - CGSizeMakeUniform(1);
  for (LTRotatedRect *rect in rects) {
    targets.push_back(std::round(std::clamp(rect.center, kNormalRect) * textureSize));
  }
  return [self colorsFromGLKColors:[self.baseColorTexture pixelValues:targets]];
}

- (NSArray *)colorsFromGLKColors:(const LTVector4s &)glkColors {
  NSMutableArray *colors = [NSMutableArray array];
  for (const LTVector4 &glkColor : glkColors) {
    [colors addObject:[UIColor lt_colorWithLTVector:glkColor]];
  }
  return colors;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, hueJitter, HueJitter, 0, 1, 1);
LTProperty(CGFloat, saturationJitter, SaturationJitter, 0, 1, 1);
LTProperty(CGFloat, brightnessJitter, BrightnessJitter, 0, 1, 1);

- (void)setBaseColorTexture:(LTTexture *)baseColorTexture {
  LTParameterAssert(!baseColorTexture || baseColorTexture.format == LTTextureFormatRGBA);
  _baseColorTexture = baseColorTexture;
}

@end
