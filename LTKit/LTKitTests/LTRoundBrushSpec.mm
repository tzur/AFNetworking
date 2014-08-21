// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRoundBrushSpec.h"

#import "LTBrushEffectExamples.h"
#import "LTBrushSpec.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTTexture+Factory.h"

NSString * const kLTRoundBrushExamples = @"LTRoundBrushExamples";
NSString * const kLTRoundBrushClass = @"LTRoundBrushClass";

SharedExamplesBegin(LTRoundBrushExamples)

sharedExamplesFor(kLTRoundBrushExamples, ^(NSDictionary *data) {
  __block Class brushClass;

  beforeEach(^{
    brushClass = data[kLTRoundBrushClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  context(@"properties", ^{
    const CGFloat kEpsilon = 1e-6;
    __block LTRoundBrush *brush;
    
    beforeEach(^{
      brush = [[LTRoundBrush alloc] init];
    });
    
    afterEach(^{
      brush = nil;
    });
    
    it(@"should set hardness", ^{
      const CGFloat newValue = 0.5;
      expect(brush.hardness).notTo.equal(newValue);
      brush.hardness = newValue;
      expect(brush.hardness).to.equal(newValue);
      
      expect(^{
        brush.hardness = brush.minHardness - kEpsilon;
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        brush.hardness = brush.maxHardness + kEpsilon;
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

SharedExamplesEnd

LTSpecBegin(LTRoundBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTRoundBrush class]});

itShouldBehaveLike(kLTBrushEffectLTBrushExamples, @{kLTBrushClass: [LTBrush class]});

itShouldBehaveLike(kLTRoundBrushExamples, @{kLTRoundBrushClass: [LTRoundBrush class]});

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"properties", ^{
  __block LTRoundBrush *brush;
  
  beforeEach(^{
    brush = [[LTRoundBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    expect(brush.hardness).to.equal(1);
  });
});

context(@"drawing", ^{
  __block cv::Mat4b expected;
  __block LTRoundBrush *brush;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block LTPainterPoint *point;

  const CGFloat kBaseBrushDiameter = 4;
  const CGFloat kTargetBrushDiameter = 4;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    brush = [[LTRoundBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:GLKVector4Zero];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected = cv::Vec4b(0, 0, 0, 0);
    
    point = [[LTPainterPoint alloc] init];
    point.zoomScale = 1;
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
    expected.rowRange(1, 3).setTo(255);
    expected.colRange(1, 3).setTo(255);
    expect($(output.image)).to.equalMat($(expected));
  });

  context(@"round brush properties", ^{
    it(@"should draw with updated hardness", ^{
      brush.hardness = 0.5;
      [brush startNewStrokeAtPoint:point];
      [brush drawPoint:point inFramebuffer:fbo];
      expected.rowRange(1, 3).setTo(36);
      expected.colRange(1, 3).setTo(36);
      expected(cv::Rect(1, 1, 2, 2)).setTo(171);
      expect($(output.image)).to.beCloseToMat($(expected));
    });
  });
  
  context(@"brush properties related to the shader", ^{
    context(@"painting mode", ^{
      it(@"drawing should be additive", ^{
        brush.hardness = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(72);
        expected.colRange(1, 3).setTo(72);
        expected(cv::Rect(1, 1, 2, 2)).setTo(255);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(26);
        expected.colRange(1, 3).setTo(26);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated flow", ^{
        brush.flow = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(26);
        expected.colRange(1, 3).setTo(26);
        expect($(output.image)).to.beCloseToMat($(expected));
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(52);
        expected.colRange(1, 3).setTo(52);
        expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
      });
      
      it(@"should draw with updated intensity", ^{
        const GLKVector4 kIntensity = GLKVector4Make(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTGLKVector4ToVec4b(kIntensity));
        expected.colRange(1, 3).setTo(LTGLKVector4ToVec4b(kIntensity));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
    
    context(@"direct erasing mode", ^{
      beforeEach(^{
        [fbo clearWithColor:GLKVector4One];
        expected.setTo(cv::Vec4b(255, 255, 255, 255));
        brush.mode = LTRoundBrushModeEraseDirect;
      });
      
      it(@"drawing should be additive", ^{
        brush.hardness = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(255 - 72);
        expected.colRange(1, 3).setTo(255 - 72);
        expected(cv::Rect(1, 1, 2, 2)).setTo(0);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(255 - 26);
        expected.colRange(1, 3).setTo(255 - 26);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated flow", ^{
        brush.flow = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(255 - 26);
        expected.colRange(1, 3).setTo(255 - 26);
        expect($(output.image)).to.beCloseToMat($(expected));
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(255 - 52);
        expected.colRange(1, 3).setTo(255 - 52);
        expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
      });
      
      it(@"should draw with updated intensity", ^{
        const GLKVector4 kIntensity = GLKVector4Make(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTGLKVector4ToVec4b(GLKVector4One - kIntensity));
        expected.colRange(1, 3).setTo(LTGLKVector4ToVec4b(GLKVector4One - kIntensity));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
    
    context(@"indirect erasing mode", ^{
      using half_float::half;
      
      const cv::Vec4hf kBlack(half(0), half(0), half(0), half(0));
      const cv::Vec4hf kWhite(half(1), half(1), half(1), half(1));

      __block cv::Mat4hf expected;
      
      beforeEach(^{
        output = [LTTexture textureWithSize:kOutputSize precision:LTTexturePrecisionHalfFloat
                                     format:LTTextureFormatRGBA allocateMemory:YES];
        fbo = [[LTFbo alloc] initWithTexture:output];
        [fbo clearWithColor:GLKVector4Zero];
        
        expected.create(kOutputSize.height, kOutputSize.width);
        expected.setTo(kBlack);
        
        brush.mode = LTRoundBrushModeEraseIndirect;
      });
      
      it(@"drawing should be additive", ^{
        brush.hardness = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.28), half(0.28), half(0.28), half(0.28)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.28), half(0.28), half(0.28), half(0.28)));
        expected(cv::Rect(1, 1, 2, 2)).setTo(-kWhite);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.1), half(0.1), half(0.1)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.1), half(0.1), half(0.1)));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated flow", ^{
        brush.flow = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.1), half(0.1), half(0.1)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.1), half(0.1), half(0.1)));
        expect($(output.image)).to.beCloseToMat($(expected));
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.2), half(0.2), half(0.2), half(0.2)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.2), half(0.2), half(0.2), half(0.2)));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated intensity", ^{
        const GLKVector4 kIntensity = GLKVector4Make(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.2), half(0.3), half(0.4)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.2), half(0.3), half(0.4)));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
  });
});

LTSpecEnd
