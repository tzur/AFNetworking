// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushEffectExamples.h"

#import "LTBrushColorDynamicsEffect.h"
#import "LTBrushScatterEffect.h"
#import "LTBrushShapeDynamicsEffect.h"
#import "LTCGExtensions.h"
#import "LTDegenerateInterpolationRoutine.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTPainterStrokeSegment.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

NSString * const kLTBrushEffectExamples = @"LTBrushEffectExamples";

@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

SharedExamplesBegin(LTBrushEffectExamples)

sharedExamplesFor(kLTBrushEffectExamples, ^(NSDictionary *data) {
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
      [brush.texture clearWithColor:GLKVector4Make(1, 1, 1, 1)];
      brush.baseDiameter = kBaseBrushDiameter;
      brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
      
      output = [LTTexture byteRGBATextureWithSize:kOutputSize];
      fbo = [[LTFbo alloc] initWithTexture:output];
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      
      expected.create(kOutputSize.height, kOutputSize.width);
      expected = cv::Vec4b(0, 0, 0, 255);
      
      point = [[LTPainterPoint alloc] init];
      point.zoomScale = 1;
      point.contentPosition = kOutputCenter;
      spline = [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:@[point]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:0 zoomScale:1
                                                   distanceFromStart:0
                                             andInterpolationRoutine:spline];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      brush = nil;
    });

    it(@"should not apply effects when drawing a point", ^{
      brush.scatterEffect = [[LTBrushScatterEffect alloc] init];
      brush.shapeDynamicsEffect = [[LTBrushShapeDynamicsEffect alloc] init];
      brush.colorDynamicsEffect = [[LTBrushColorDynamicsEffect alloc] init];
      
      [brush drawPoint:point inFramebuffer:fbo];
      CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
      expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
      expect($(output.image)).to.equalMat($(expected));
    });
    
    it(@"should apply scatter effect when drawing a segment", ^{
      brush.scatterEffect = [[LTBrushScatterEffect alloc] init];
      brush.scatterEffect.count = 10;
      brush.scatterEffect.scatter = 0;
      brush.scatterEffect.countJitter = 0;
      brush.flow = 0.5;
      
      [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
          saveLastDrawnPointTo:nil];
      CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
      expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
      expect($(output.image)).to.equalMat($(expected));
    });
    
    it(@"should apply shapeDynamics effect when drawing a segment", ^{
      brush.shapeDynamicsEffect = [[LTBrushShapeDynamicsEffect alloc] init];
      brush.shapeDynamicsEffect.sizeJitter = 0;
      brush.shapeDynamicsEffect.angleJitter = 0;
      brush.shapeDynamicsEffect.roundnessJitter = 1;
      brush.shapeDynamicsEffect.minimumRoundness = 0;

      // This is performed multiple times since the random jitter might be small enough to leave the
      // target rectangle at the same number pixels. The chances of this happening more 100 times
      // are < 1/2^100.
      const GLKVector4 kBlack = GLKVector4Make(0, 0, 0, 1);
      const CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
      NSUInteger numBlack = 0;
      for (NSUInteger i = 0; i < 100; ++i) {
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
            saveLastDrawnPointTo:nil];
        
        GLKVector4 color = [output pixelValue:targetRect.origin];
        if (color == kBlack) {
          numBlack++;
        }
      }
      expect(numBlack).to.beGreaterThan(0);
    });
    
    it(@"should apply colorDynamics effect when drawing a segment", ^{
      brush.colorDynamicsEffect = [[LTBrushColorDynamicsEffect alloc] init];
      brush.colorDynamicsEffect.brightnessJitter = 1;
      
      // This is performed multiple times, since the jitter might increase the brightness (which is
      // already at the maximum value). This will fail if this happens 100 times (1/2^100 chance).
      __block CGFloat minBrightness = 1;
      for (NSUInteger i = 0; i < 100; ++i) {
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        [brush drawStrokeSegment:segment fromPreviousPoint:nil inFramebuffer:fbo
            saveLastDrawnPointTo:nil];
        
        __block UIColor *color = [UIColor colorWithGLKVector:[output pixelValue:kOutputCenter]];
        __block CGFloat brightness;
        expect([color getHue:nil saturation:nil brightness:&brightness alpha:nil]).to.beTruthy();
        minBrightness = MIN(minBrightness, brightness);
      }
      expect(minBrightness).notTo.beCloseToWithin(1, 1e-2);
    });
  });
});

SharedExamplesEnd