// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushEffectExamples.h"

#import <LTEngine/LTBrushColorDynamicsEffect.h>
#import <LTEngine/LTBrushScatterEffect.h>
#import <LTEngine/LTBrushShapeDynamicsEffect.h>
#import <LTEngine/LTDegenerateInterpolationRoutine.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTGLKitExtensions.h>
#import <LTEngine/LTPainterPoint.h>
#import <LTEngine/LTPainterStrokeSegment.h>
#import <LTEngine/LTTexture+Factory.h>
#import <LTEngine/UIColor+Vector.h>
#import <LTKit/LTRandom.h>

NSString * const kLTBrushEffectLTBrushExamples = @"LTBrushEffectLTBrushExamples";
NSString * const kLTBrushEffectSubclassExamples = @"LTBrushEffectSubclassExamples";
NSString * const kLTBrushEffectClass = @"LTBrushEffectClass";

/// Shared group name for testing subclasses of LTBrushEffect.
extern NSString * const kLTBrushEffectExamples;
@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

SharedExamplesBegin(LTBrushEffectExamples)

sharedExamplesFor(kLTBrushEffectSubclassExamples, ^(NSDictionary *data) {
  __block Class effectClass;
  __block LTBrushEffect *effect;
  
  beforeEach(^{
    effectClass = data[kLTBrushEffectClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });
  
  context(@"initialization", ^{
    it(@"should initialize with default initializer", ^{
      effect = [[effectClass alloc] init];
      expect(effect.random).notTo.beNil();
    });
    
    it(@"should initialize with a given random generator", ^{
      LTRandom *random = [[LTRandom alloc] init];
      effect = [[effectClass alloc] initWithRandom:random];
      expect(effect.random).to.beIdenticalTo(random);
    });
  });
});

sharedExamplesFor(kLTBrushEffectLTBrushExamples, ^(NSDictionary *data) {
  __block Class brushClass;
  
  beforeEach(^{
    brushClass = data[kLTBrushClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });
  
  context(@"properties", ^{
    __block LTBrush *brush;
    
    beforeEach(^{
      brush = [[brushClass alloc] init];
    });
    
    afterEach(^{
      brush = nil;
    });
    
    it(@"should set scatter effect", ^{
      LTBrushScatterEffect *effect = [[LTBrushScatterEffect alloc] init];
      brush.scatterEffect = effect;
      expect(brush.scatterEffect).to.beIdenticalTo(effect);
    });
    
    it(@"should set shapeDynamics effect", ^{
      LTBrushShapeDynamicsEffect *effect = [[LTBrushShapeDynamicsEffect alloc] init];
      brush.shapeDynamicsEffect = effect;
      expect(brush.shapeDynamicsEffect).to.beIdenticalTo(effect);
    });
    
    it(@"should set colorDynamics effect", ^{
      LTBrushColorDynamicsEffect *effect = [[LTBrushColorDynamicsEffect alloc] init];
      brush.colorDynamicsEffect = effect;
      expect(brush.colorDynamicsEffect).to.beIdenticalTo(effect);
    });
  });
  
  context(@"drawing", ^{
    __block cv::Mat4b expected;
    __block LTBrush *brush;
    __block LTTexture *output;
    __block LTFbo *fbo;
    __block LTInterpolationRoutine *spline;
    __block LTPainterPoint *point;
    __block LTPainterStrokeSegment *segment;
    
    const CGFloat kBaseBrushDiameter = 100;
    const CGFloat kTargetBrushDiameter = 10;
    const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
    const CGSize kOutputSize = 2 * kBaseBrushSize;
    const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
    
    beforeEach(^{
      brush = [[brushClass alloc] init];
      brush.baseDiameter = kBaseBrushDiameter;
      brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
      
      output = [LTTexture byteRGBATextureWithSize:kOutputSize];
      fbo = [[LTFbo alloc] initWithTexture:output];
      [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
      
      expected.create(kOutputSize.height, kOutputSize.width);
      expected = cv::Vec4b(0, 0, 0, 255);
      
      point = [[LTPainterPoint alloc] init];
      point.contentPosition = kOutputCenter;
      spline = [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:@[point]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:0 distanceFromStart:0
                                             andInterpolationRoutine:spline];
      
      [brush startNewStrokeAtPoint:point];
      [brush.texture clearWithColor:LTVector4(1, 1, 1, 1)];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      brush = nil;
    });

    context(@"scatter effect", ^{
      beforeEach(^{
        brush.scatterEffect = [[LTBrushScatterEffect alloc] init];
        brush.scatterEffect.count = 10;
        brush.scatterEffect.scatter = 0;
        brush.scatterEffect.countJitter = 0;
        brush.flow = 0.5;

        CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
        expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
      });
      
      it(@"should apply when drawing a point", ^{
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should apply when drawing a segment", ^{
        [brush startNewStrokeAtPoint:point];
        [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
            saveLastDrawnPointTo:nil];
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
    
    context(@"shapeDynamics effect", ^{
      const LTVector4 kBlack = LTVector4(0, 0, 0, 1);
      const CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);

      beforeEach(^{
        brush.shapeDynamicsEffect = [[LTBrushShapeDynamicsEffect alloc] init];
        brush.shapeDynamicsEffect.sizeJitter = 0;
        brush.shapeDynamicsEffect.angleJitter = 0;
        brush.shapeDynamicsEffect.roundnessJitter = 1;
        brush.shapeDynamicsEffect.minimumRoundness = 0;
      });
      
      it(@"should apply when drawing a point", ^{
        // This is performed multiple times since the random jitter might be small enough to leave
        // the target rectangle at the same number pixels. The chances of this happening more 100
        // times are < 1/2^100.
        NSUInteger numBlack = 0;
        for (NSUInteger i = 0; i < 100; ++i) {
          [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          LTVector4 color = [output pixelValue:targetRect.origin];
          if (color == kBlack) {
            numBlack++;
          }
        }
        expect(numBlack).to.beGreaterThan(0);
      });
      
      it(@"should apply when drawing a segment", ^{
        // This is performed multiple times since the random jitter might be small enough to leave
        // the target rectangle at the same number pixels. The chances of this happening more 100
        // times are < 1/2^100.
        NSUInteger numBlack = 0;
        for (NSUInteger i = 0; i < 100; ++i) {
          [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
          [brush startNewStrokeAtPoint:point];
          [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
              saveLastDrawnPointTo:nil];
          
          LTVector4 color = [output pixelValue:targetRect.origin];
          if (color == kBlack) {
            numBlack++;
          }
        }
        expect(numBlack).to.beGreaterThan(0);
      });
    });
    
    context(@"colorDynamics effect", ^{
      beforeEach(^{
        brush.colorDynamicsEffect = [[LTBrushColorDynamicsEffect alloc] init];
        brush.colorDynamicsEffect.brightnessJitter = 1;
      });
      
      it(@"should apply when drawing a point", ^{
        // This is performed multiple times, since the jitter might increase the brightness (which
        // is already at the maximum value). This will fail if this happens 100 times (1/2^100).
        __block CGFloat minBrightness = 1;
        for (NSUInteger i = 0; i < 100; ++i) {
          [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          __block UIColor *color = [UIColor lt_colorWithLTVector:[output pixelValue:kOutputCenter]];
          __block CGFloat brightness;
          expect([color getHue:nil saturation:nil brightness:&brightness alpha:nil]).to.beTruthy();
          minBrightness = MIN(minBrightness, brightness);
        }
        expect(minBrightness).notTo.beCloseToWithin(1, 1e-2);
      });

      it(@"should apply when drawing a segment", ^{
        // This is performed multiple times, since the jitter might increase the brightness (which
        // is already at the maximum value). This will fail if this happens 100 times (1/2^100).
        __block CGFloat minBrightness = 1;
        for (NSUInteger i = 0; i < 100; ++i) {
          [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
          [brush startNewStrokeAtPoint:point];
          [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
              saveLastDrawnPointTo:nil];
          
          __block UIColor *color = [UIColor lt_colorWithLTVector:[output pixelValue:kOutputCenter]];
          __block CGFloat brightness;
          expect([color getHue:nil saturation:nil brightness:&brightness alpha:nil]).to.beTruthy();
          minBrightness = MIN(minBrightness, brightness);
        }
        expect(minBrightness).notTo.beCloseToWithin(1, 1e-2);
      });
    });
  });
});

SharedExamplesEnd
