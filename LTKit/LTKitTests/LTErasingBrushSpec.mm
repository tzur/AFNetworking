// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTErasingBrush.h"

#import "LTBrushSpec.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTRoundBrushSpec.h"
#import "LTTexture+Factory.h"

SpecBegin(LTErasingBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTErasingBrush class]});

itShouldBehaveLike(kLTRoundBrushExamples, @{kLTRoundBrushClass: [LTErasingBrush class]});

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"drawing", ^{
  using half_float::half;
  
  __block cv::Mat4hf expected;
  __block LTErasingBrush *brush;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block LTPainterPoint *point;
  
  const cv::Vec4hf kBlack(half(0), half(0), half(0), half(0));
  const cv::Vec4hf kWhite(half(1), half(1), half(1), half(1));
  const CGFloat kBaseBrushDiameter = 4;
  const CGFloat kTargetBrushDiameter = 4;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    brush = [[LTErasingBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    output = [LTTexture textureWithSize:kOutputSize precision:LTTexturePrecisionHalfFloat
                                 format:LTTextureFormatRGBA allocateMemory:YES];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 0)];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected.setTo(kBlack);
    
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
    expected.rowRange(1, 3).setTo(-kWhite);
    expected.colRange(1, 3).setTo(-kWhite);
    expect($(output.image)).to.equalMat($(expected));
  });
  
  context(@"round brush properties", ^{
    it(@"should draw with updated hardness", ^{
      brush.hardness = 0.5;
      [brush startNewStrokeAtPoint:point];
      [brush drawPoint:point inFramebuffer:fbo];
      expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.14), half(0.14), half(0.14), half(0.14)));
      expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.14), half(0.14), half(0.14), half(0.14)));
      expected(cv::Rect(1, 1, 2, 2)).setTo(-cv::Vec4hf(half(0.67), half(0.67),
                                                       half(0.67), half(0.67)));
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
  
  context(@"brush properties related to the shader", ^{
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
  });
});

SpecEnd
