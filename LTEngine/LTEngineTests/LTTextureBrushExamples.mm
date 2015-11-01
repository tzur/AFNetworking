// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrushExamples.h"

#import <LTEngine/LTFbo.h>
#import <LTEngine/LTGLContext.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTPainterPoint.h>
#import <LTEngine/LTTexture+Factory.h>

#import "LTBrushEffectExamples.h"
#import "LTBrushSpec.h"

NSString * const kLTTextureBrushExamples = @"LTTextureBrushExamples";
NSString * const kLTTextureBrushClass = @"LTTextureBrushClass";

SharedExamplesBegin(LTTextureBrushExamples)

sharedExamplesFor(kLTTextureBrushExamples, ^(NSDictionary *data) {
  __block Class brushClass;
  __block LTTextureBrush *brush;

  beforeEach(^{
    brushClass = data[kLTTextureBrushClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });
  
  context(@"properties", ^{
    beforeEach(^{
      brush = [[brushClass alloc] init];
    });
    
    afterEach(^{
      brush = nil;
    });
    
    it(@"should have default properties", ^{
      expect(brush.premultipliedAlpha).to.beFalsy();
      expect(brush.spacing).to.equal(2);
    });
    
    it(@"should set premultipliedAlpha", ^{
      BOOL oldValue = brush.premultipliedAlpha;
      brush.premultipliedAlpha = !oldValue;
      expect(brush.premultipliedAlpha).to.equal(!oldValue);
    });
  });

  context(@"drawing", ^{
    __block cv::Mat4b expected;
    __block LTTextureBrush *brush;
    __block LTTexture *output;
    __block LTFbo *fbo;
    __block LTPainterPoint *point;
    
    const CGFloat kBaseBrushDiameter = 4;
    const CGFloat kTargetBrushDiameter = 4;
    const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
    const CGSize kOutputSize = kBaseBrushSize;
    const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
    
    beforeEach(^{
      brush = [[brushClass alloc] init];
      brush.baseDiameter = kBaseBrushDiameter;
      brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
      output = [LTTexture byteRGBATextureWithSize:kOutputSize];
      fbo = [[LTFbo alloc] initWithTexture:output];
      [fbo clearWithColor:LTVector4(0, 0, 0, 0)];
      
      expected.create(kOutputSize.height, kOutputSize.width);
      expected = cv::Vec4b(0, 0, 0, 0);
      
      point = [[LTPainterPoint alloc] init];
      point.contentPosition = kOutputCenter;
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      brush = nil;
    });
    
    it(@"should draw a point", ^{
      [brush startNewStrokeAtPoint:point];
      [brush drawPoint:point inFramebuffer:fbo];
      expected.setTo(cv::Vec4b(255, 255, 255, 255));
      expect($(output.image)).to.equalMat($(expected));
    });
    
    context(@"texture brush properties", ^{
      it(@"should draw with replaced texture", ^{
        const CGSize kSize = CGSizeMakeUniform(kTargetBrushDiameter);
        const CGSize kHalf = kSize / 2;
        cv::Mat4b newTexture(kSize.height, kSize.width);
        newTexture(cv::Rect(0, 0, kHalf.width, kHalf.height)) = cv::Vec4b(255, 0, 0, 255);
        newTexture(cv::Rect(kHalf.width, 0, kHalf.width, kHalf.height)) = cv::Vec4b(0, 255, 0, 255);
        newTexture(cv::Rect(0, kHalf.height, kHalf.width, kHalf.height)) =
            cv::Vec4b(0, 0, 255, 255);
        newTexture(cv::Rect(kHalf.width, kHalf.height, kHalf.width, kHalf.height)) =
            cv::Vec4b(255, 255, 0, 255);
        
        LTTexture *texture = [LTTexture textureWithImage:newTexture];
        texture.minFilterInterpolation = LTTextureInterpolationNearest;
        texture.magFilterInterpolation = LTTextureInterpolationNearest;
        [brush setSingleTexture:texture];
        [brush drawPoint:point inFramebuffer:fbo];
        CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
        newTexture.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw with premultipliedAlpha set to YES", ^{
        brush.premultipliedAlpha = YES;
        [brush drawPoint:point inFramebuffer:fbo];
        expected.setTo(cv::Vec4b(255, 255, 255, 255));
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw with premultipliedAlpha set to NO", ^{
        brush.premultipliedAlpha = NO;
        [brush drawPoint:point inFramebuffer:fbo];
        expected.setTo(cv::Vec4b(255, 255, 255, 255));
        expect($(output.image)).to.equalMat($(expected));
      });
    });
    
    context(@"brush properties related to the shader", ^{
      const CGFloat kWidth = kOutputSize.width / 2;
      const CGFloat kHeight = kOutputSize.height / 2;
      const cv::Rect kTopLeft = cv::Rect(0, 0, kWidth, kHeight);
      const cv::Rect kTopRight = cv::Rect(kWidth, 0, kWidth, kHeight);
      const cv::Rect kBottomLeft = cv::Rect(0, kHeight, kWidth, kHeight);
      const cv::Rect kBottomRight = cv::Rect(kWidth, kHeight, kWidth, kHeight);
      
      __block cv::Mat4b brushMat;
      
      context(@"premultipliedAlpha is NO", ^{
        const cv::Vec4b kTopLeftColor(64, 0, 0, 64);
        const cv::Vec4b kTopRightColor(0, 64, 0, 191);
        const cv::Vec4b kBottomLeftColor(0, 0, 64, 64);
        const cv::Vec4b kBottomRightColor(64, 64, 0, 191);
        const cv::Vec4b kTopBrushColor(32, 32, 32, 32);
        const cv::Vec4b kBottomBrushColor(32, 64, 128, 128);
        const cv::Vec4b kTopBrushColorPremultiplied(4, 4, 4, 32);
        const cv::Vec4b kBottomBrushColorPremultiplied(16, 32, 64, 128);

        beforeEach(^{
          brushMat.create(output.size.height, output.size.width);
          brushMat.rowRange(0, kHeight).setTo(kTopBrushColorPremultiplied);
          brushMat.rowRange(kHeight, kOutputSize.height).setTo(kBottomBrushColorPremultiplied);
          brush.premultipliedAlpha = NO;
          [brush setSingleTexture:[LTTexture textureWithImage:brushMat]];
          
          expected(kTopLeft).setTo(kTopLeftColor);
          expected(kTopRight).setTo(kTopRightColor);
          expected(kBottomLeft).setTo(kBottomLeftColor);
          expected(kBottomRight).setTo(kBottomRightColor);
          [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
            expected.copyTo(*mapped);
          }];
        });
        
        it(@"drawing should blend with previous target", ^{
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];

          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, kTopBrushColor, NO));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, kTopBrushColor, NO));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, kBottomBrushColor, NO));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, kBottomBrushColor, NO));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated opacity", ^{
          brush.opacity = 0.25;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];

          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, kTopBrushColor, NO));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, kTopBrushColor, NO));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(32, 64, 128, 64), NO));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(32, 64, 128, 64), NO));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated flow", ^{
          brush.flow = 0.5;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];

          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, cv::Vec4b(32, 32, 32, 16), NO));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, cv::Vec4b(32, 32, 32, 16), NO));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(32, 64, 128, 64), NO));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(32, 64, 128, 64), NO));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated intensity", ^{
          const LTVector4 kIntensity = LTVector4(0.25, 0.25, 0.25, 0.5);
          brush.intensity = kIntensity;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];

          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, cv::Vec4b(16, 16, 16, 16), NO));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, cv::Vec4b(16, 16, 16, 16), NO));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(16, 32, 64, 64), NO));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(16, 32, 64, 64), NO));
          expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
        });
        
        it(@"blending with zero result opacity should result in zero rgb as well", ^{
          [fbo clearWithColor:LTVector4(1, 1, 1, 0)];
          brush.intensity = LTVector4(1, 1, 1, 0);
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          expected.setTo(0);
          expect($(output.image)).to.equalMat($(expected));
        });
        
        it(@"should blend with single channel target", ^{
          LTTexture *singleOutput = [LTTexture byteRedTextureWithSize:output.size];
          LTFbo *singleFbo = [[LTFbo alloc] initWithTexture:singleOutput];
          [singleFbo clearWithColor:LTVector4(0.5)];

          cv::Mat4b brushTexture(1, 1, cv::Vec4b(128, 128, 128, 128));
          [brush setSingleTexture:[LTTexture textureWithImage:brushTexture]];
          brush.intensity = LTVector4::ones();
          brush.flow = 0.2;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:singleFbo];

          cv::Mat1b expected(output.size.height, output.size.width);
          expected.setTo(128 * 0.9 + 255 * 0.1);
          expect($(singleOutput.image)).to.beCloseToMat($(expected));
        });
      });
      
      context(@"premultipliedAlpha is YES", ^{
        const cv::Vec4b kTopLeftColor(16, 0, 0, 64);
        const cv::Vec4b kTopRightColor(0, 48, 0, 191);
        const cv::Vec4b kBottomLeftColor(0, 0, 16, 64);
        const cv::Vec4b kBottomRightColor(48, 48, 0, 191);
        const cv::Vec4b kTopBrushColor(4, 4, 4, 32);
        const cv::Vec4b kBottomBrushColor(16, 32, 64, 128);

        beforeEach(^{
          brushMat.create(output.size.height, output.size.width);
          brushMat.rowRange(0, kHeight).setTo(kTopBrushColor);
          brushMat.rowRange(kHeight, kOutputSize.height).setTo(kBottomBrushColor);
          brush.premultipliedAlpha = YES;
          [brush setSingleTexture:[LTTexture textureWithImage:brushMat]];
          
          expected(kTopLeft).setTo(kTopLeftColor);
          expected(kTopRight).setTo(kTopRightColor);
          expected(kBottomLeft).setTo(kBottomLeftColor);
          expected(kBottomRight).setTo(kBottomRightColor);
          [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
            expected.copyTo(*mapped);
          }];
        });
        
        it(@"drawing should blend with previous target", ^{
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, kTopBrushColor, YES));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, kTopBrushColor, YES));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, kBottomBrushColor, YES));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, kBottomBrushColor, YES));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated opacity", ^{
          brush.opacity = 0.25;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, kTopBrushColor, YES));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, kTopBrushColor, YES));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(8, 16, 32, 64), YES));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(8, 16, 32, 64), YES));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated flow", ^{
          brush.flow = 0.5;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, cv::Vec4b(2, 2, 2, 16), YES));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, cv::Vec4b(2, 2, 2, 16), YES));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(8, 16, 32, 64), YES));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(8, 16, 32, 64), YES));
          expect($(output.image)).to.beCloseToMat($(expected));
        });
        
        it(@"should draw with updated intensity", ^{
          const LTVector4 kIntensity = LTVector4(0.25, 0.25, 0.25, 0.5);
          brush.intensity = kIntensity;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          
          expected(kTopLeft).setTo(LTBlend(kTopLeftColor, cv::Vec4b(1, 1, 1, 16), YES));
          expected(kTopRight).setTo(LTBlend(kTopRightColor, cv::Vec4b(1, 1, 1, 16), YES));
          expected(kBottomLeft).setTo(LTBlend(kBottomLeftColor, cv::Vec4b(4, 8, 16, 64), YES));
          expected(kBottomRight).setTo(LTBlend(kBottomRightColor, cv::Vec4b(4, 8, 16, 64), YES));
          expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
        });
        
        it(@"blending with zero result opacity should result in zero rgb as well", ^{
          [fbo clearWithColor:LTVector4(0, 0, 0, 0)];
          brush.intensity = LTVector4(1, 1, 1, 0);
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:fbo];
          expected.setTo(0);
          expect($(output.image)).to.equalMat($(expected));
        });

        it(@"should blend with single channel target", ^{
          LTTexture *singleOutput = [LTTexture byteRedTextureWithSize:output.size];
          LTFbo *singleFbo = [[LTFbo alloc] initWithTexture:singleOutput];
          [singleFbo clearWithColor:LTVector4(0.5)];

          cv::Mat4b brushTexture(1, 1, cv::Vec4b(128, 128, 128, 128));
          [brush setSingleTexture:[LTTexture textureWithImage:brushTexture]];
          brush.intensity = LTVector4::ones();
          brush.flow = 0.2;
          [brush startNewStrokeAtPoint:point];
          [brush drawPoint:point inFramebuffer:singleFbo];

          cv::Mat1b expected(output.size.height, output.size.width);
          expected.setTo(128 * 0.9 + 255 * 0.1);
          expect($(singleOutput.image)).to.beCloseToMat($(expected));
        });
      });
    });
  });
});

SharedExamplesEnd
