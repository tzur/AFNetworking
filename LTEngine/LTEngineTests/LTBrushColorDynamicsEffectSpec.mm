// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushColorDynamicsEffect.h"

#import <LTKit/LTRandom.h>

#import "LTBrushEffectExamples.h"
#import "LTTexture+Factory.h"
#import "LTRotatedRect.h"
#import "UIColor+Vector.h"

SpecBegin(LTBrushColorDynamicsEffect)

itShouldBehaveLike(kLTBrushEffectSubclassExamples,
                   @{kLTBrushEffectClass: [LTBrushColorDynamicsEffect class]});

__block LTBrushColorDynamicsEffect *effect;

context(@"initialization", ^{
  it(@"should initialize with default initializer", ^{
    expect(^{
      effect = [[LTBrushColorDynamicsEffect alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  beforeEach(^{
    effect = [[LTBrushColorDynamicsEffect alloc] init];
  });
  
  it(@"should have default properties", ^{
    expect(effect.hueJitter).to.equal(0);
    expect(effect.saturationJitter).to.equal(0);
    expect(effect.brightnessJitter).to.equal(0);
    expect(effect.secondaryColorJitter).to.equal(0);
    expect(effect.secondaryColor).to.beNil();
    expect(effect.baseColorTexture).beNil();
  });
  
  it(@"should set hueJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.hueJitter).notTo.equal(newValue);
    effect.hueJitter = newValue;
    expect(effect.hueJitter).to.equal(newValue);
  });
  
  it(@"should set saturationJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.saturationJitter).notTo.equal(newValue);
    effect.saturationJitter = newValue;
    expect(effect.saturationJitter).to.equal(newValue);
  });

  it(@"should set brightnessJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.brightnessJitter).notTo.equal(newValue);
    effect.brightnessJitter = newValue;
    expect(effect.brightnessJitter).to.equal(newValue);
  });

  it(@"should set secondaryColorJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.secondaryColorJitter).notTo.equal(newValue);
    effect.secondaryColorJitter = newValue;
    expect(effect.secondaryColorJitter).to.equal(newValue);
  });

  it(@"should set secondaryColor", ^{
    UIColor *newColor = [UIColor redColor];
    effect.secondaryColor = newColor;
    expect(effect.secondaryColor).to.equal(newColor);
    effect.secondaryColor = nil;
    expect(effect.secondaryColor).to.beNil();
  });

  it(@"should set baseColorTexture", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    effect.baseColorTexture = texture;
    expect(effect.baseColorTexture).to.beIdenticalTo(texture);
    
    effect.baseColorTexture = nil;
    expect(effect.baseColorTexture).to.beNil();
    
    expect(^{
      effect.baseColorTexture= [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRed allocateMemory:YES];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      effect.baseColorTexture= [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                                precision:LTTexturePrecisionByte
                                                   format:LTTextureFormatRG allocateMemory:YES];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"effect", ^{
  __block NSMutableArray *sourceRects;
  __block NSArray *colors;
  __block UIColor *baseColor;
  __block CGFloat baseHue, baseSaturation, baseBrightness, baseAlpha;
  
  beforeEach(^{
    LTRandom *random = [JSObjection defaultInjector][[LTRandom class]];
    effect = [[LTBrushColorDynamicsEffect alloc] initWithRandom:random];
    sourceRects = [NSMutableArray array];
    for (NSUInteger i = 0; i < 5000; ++i) {
      [sourceRects addObject:[LTRotatedRect
                              rectWithCenter:CGPointMake([random randomDouble],
                                                         [random randomDouble])
                              size:CGSizeMakeUniform([random randomDouble])
                              angle:[random randomDoubleBetweenMin:0 max:2 * M_PI]]];
    }
    
    baseHue = 0.75;
    baseSaturation = 0.5;
    baseBrightness = 0.5;
    baseAlpha = 0.5;
    baseColor = [UIColor colorWithHue:baseHue saturation:baseSaturation
                           brightness:baseBrightness alpha:baseAlpha];
  });
  
  it(@"should return an empty array if the input is an empty array", ^{
    expect([effect colorsFromRects:@[] baseColor:baseColor].count).to.equal(0);
  });
  
  it(@"should return the baseColor when hueJitter, saturationJitter, brightnessJitter are all 0", ^{
    colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
    expect(colors.count).to.equal(sourceRects.count);
    for (UIColor *color in colors) {
      expect(color).to.equal(baseColor);
    }
  });
  
  it(@"should return colors according to the hueJitter property", ^{
    effect.hueJitter = 0.5;
    colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
    expect(colors.count).to.equal(sourceRects.count);
    CGFloat maxDistance = 0;
    CGFloat sumDistance = 0;
    for (UIColor *color in colors) {
      __block CGFloat h, s, b, a;
      expect([color getHue:&h saturation:&s brightness:&b alpha:&a]).to.beTruthy();
      expect(h).notTo.equal(baseHue);
      expect(s).to.beCloseToWithin(baseSaturation, 1e-2);
      expect(b).to.beCloseToWithin(baseBrightness, 1e-2);
      expect(a).to.beCloseToWithin(baseAlpha, 1e-2);
      CGFloat distance = MIN(std::abs(h - baseHue), std::abs(1 + h - baseHue));
      maxDistance = MAX(maxDistance, distance);
      sumDistance += distance;
    }
    expect(maxDistance).to.beCloseToWithin(effect.hueJitter, 1e-2);
    expect(sumDistance / sourceRects.count).to.beCloseToWithin(effect.hueJitter / 2, 5e-2);
  });
  
  it(@"should return colors according to the saturationJitter property", ^{
    effect.saturationJitter = 0.5;
    colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
    expect(colors.count).to.equal(sourceRects.count);
    CGFloat maxDistance = 0;
    CGFloat sumDistance = 0;
    for (UIColor *color in colors) {
      __block CGFloat h, s, b, a;
      expect([color getHue:&h saturation:&s brightness:&b alpha:&a]).to.beTruthy();
      expect(h).to.beCloseToWithin(baseHue, 1e-2);
      expect(s).notTo.equal(baseSaturation);
      expect(b).to.beCloseToWithin(baseBrightness, 1e-2);
      expect(a).to.beCloseToWithin(baseAlpha, 1e-2);
      maxDistance = MAX(maxDistance, std::abs(s - baseSaturation));
      sumDistance += std::abs(s - baseSaturation);
    }
    expect(maxDistance).to.beCloseToWithin(effect.saturationJitter, 1e-2);
    expect(sumDistance / sourceRects.count).to.beCloseToWithin(effect.saturationJitter / 2, 5e-2);
  });
  
  it(@"should return colors according to the brightnessJitter property", ^{
    effect.brightnessJitter = 0.5;
    colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
    expect(colors.count).to.equal(sourceRects.count);
    CGFloat maxDistance = 0;
    CGFloat sumDistance = 0;
    for (UIColor *color in colors) {
      __block CGFloat h, s, b, a;
      expect([color getHue:&h saturation:&s brightness:&b alpha:&a]).to.beTruthy();
      expect(h).to.beCloseToWithin(baseHue, 1e-2);
      expect(s).to.beCloseToWithin(baseSaturation, 1e-2);
      expect(b).notTo.equal(baseBrightness);
      expect(a).to.beCloseToWithin(baseAlpha, 1e-2);
      maxDistance = MAX(maxDistance, std::abs(b - baseBrightness));
      sumDistance += std::abs(b - baseBrightness);
    }
    expect(maxDistance).to.beCloseToWithin(effect.brightnessJitter, 1e-2);
    expect(sumDistance / sourceRects.count).to.beCloseToWithin(effect.brightnessJitter / 2, 5e-2);
  });

  context(@"secondary color", ^{
    it(@"should always use base color when secondaryColor is nil", ^{
      effect.secondaryColor = nil;
      effect.secondaryColorJitter = 1;
      colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
      expect(colors.count).to.equal(sourceRects.count);
      for (UIColor *color in colors) {
        expect(color).to.equal(baseColor);
      }
    });

    it(@"should always use base color when secondaryColorJitter is 0", ^{
      effect.secondaryColor = [UIColor greenColor];;
      effect.secondaryColorJitter = 0;
      colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
      expect(colors.count).to.equal(sourceRects.count);
      for (UIColor *color in colors) {
        expect(color).to.equal(baseColor);
      }
    });

    it(@"should use secondary color according to secondaryColorJitter", ^{
      effect.secondaryColor = [UIColor greenColor];;
      effect.secondaryColorJitter = 0.5;
      colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
      expect(colors.count).to.equal(sourceRects.count);
      NSUInteger numBase = 0;
      NSUInteger numSecondary = 0;
      for (UIColor *color in colors) {
        if ([color isEqual:baseColor]) {
          numBase++;
        } else if ([color isEqual:effect.secondaryColor]) {
          numSecondary++;
        }
      }
      expect(numBase + numSecondary).to.equal(colors.count);
      expect(numSecondary).to.beCloseToWithin(colors.count / 4, 1e-2 * colors.count);
    });

    it(@"should apply additional color dynamics on secondary color", ^{
      effect.secondaryColor = [UIColor greenColor];;
      effect.secondaryColorJitter = 0.5;
      effect.hueJitter = 0.1;
      colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
      expect(colors.count).to.equal(sourceRects.count);
      NSUInteger numBase = 0;
      NSUInteger numSecondary = 0;
      for (UIColor *color in colors) {
        if ([color isEqual:baseColor]) {
          numBase++;
        } else if ([color isEqual:effect.secondaryColor]) {
          numSecondary++;
        }
      }
      expect(numSecondary).notTo.beCloseToWithin(colors.count / 4, 1e-2 * colors.count);
    });
  });

  it(@"should sample the base color from the baseColorTexture when set", ^{
    const CGFloat kRedHue = 0;
    const CGFloat kGreenHue = 1.0 / 3;
    const CGFloat kBlueHue = 2.0 / 3;
    const CGFloat kYellowHue = 1.0 / 6;
    
    effect.baseColorTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(2)];
    [effect.baseColorTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->at<cv::Vec4b>(0,0) = [UIColor redColor].lt_cvVector;
      mapped->at<cv::Vec4b>(0,1) = [UIColor greenColor].lt_cvVector;
      mapped->at<cv::Vec4b>(1,0) = [UIColor blueColor].lt_cvVector;
      mapped->at<cv::Vec4b>(1,1) = [UIColor yellowColor].lt_cvVector;
    }];
    
    colors = [effect colorsFromRects:sourceRects baseColor:baseColor];
    expect(colors.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < colors.count; ++i) {
      __block CGFloat hue;
      [colors[i] getHue:&hue saturation:nil brightness:nil alpha:nil];
      LTRotatedRect *rect = sourceRects[i];
      
      if (CGRectContainsPoint(CGRectMake(0, 0, 0.5, 0.5), rect.center)) {
        expect(MIN(hue, 1 - hue)).to.beCloseToWithin(kRedHue, 1e-4);
      } else if (CGRectContainsPoint(CGRectMake(0.5, 0, 0.5, 0.5), rect.center)) {
        expect(hue).to.beCloseToWithin(kGreenHue, 1e-4);
      } else if (CGRectContainsPoint(CGRectMake(0, 0.5, 0.5, 0.5), rect.center)) {
        expect(hue).to.beCloseToWithin(kBlueHue, 1e-4);
      } else if (CGRectContainsPoint(CGRectMake(0.5, 0.5, 0.5, 0.5), rect.center)) {
        expect(hue).to.beCloseToWithin(kYellowHue, 1e-4);
      } else {
        LTAssert(NO);
      }
    }
  });
});

SpecEnd
