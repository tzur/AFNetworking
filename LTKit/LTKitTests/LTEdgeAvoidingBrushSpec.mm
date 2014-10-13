// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTEdgeAvoidingBrush.h"

#import "LTBrushSpec.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTRoundBrushSpec.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTEdgeAvoidingBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTEdgeAvoidingBrush class]});

itShouldBehaveLike(kLTRoundBrushExamples, @{kLTRoundBrushClass: [LTEdgeAvoidingBrush class]});

context(@"properties", ^{
  const CGFloat kEpsilon = 1e-6;
  __block LTEdgeAvoidingBrush *brush;
  
  beforeEach(^{
    brush = [[LTEdgeAvoidingBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    expect(brush.sigma).to.equal(0.5);
    cv::Mat4b expectedInputTexture(1, 1);
    expectedInputTexture = cv::Vec4b(0, 0, 0, 0);
    expect($(brush.inputTexture.image)).to.equalMat($(expectedInputTexture));
  });
  
  it(@"should set sigma", ^{
    const CGFloat newValue = 1;
    expect(brush.sigma).notTo.equal(newValue);
    brush.sigma = newValue;
    expect(brush.sigma).to.equal(newValue);
    
    expect(^{
      brush.sigma = brush.minSigma - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      brush.sigma = brush.maxSigma + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set inputTexture", ^{
    cv::Mat4b newInputTexture(1, 1);
    newInputTexture = cv::Vec4b(1, 2, 3, 4);
    expect($(brush.inputTexture.image)).notTo.equalMat($(newInputTexture));
    brush.inputTexture = [LTTexture textureWithImage:newInputTexture];
    expect($(brush.inputTexture.image)).to.equalMat($(newInputTexture));
  });
});

context(@"non-edge avoiding drawing", ^{
  __block cv::Mat4b expected;
  __block LTEdgeAvoidingBrush *brush;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block LTPainterPoint *point;
  
  const CGFloat kBaseBrushDiameter = 4;
  const CGFloat kTargetBrushDiameter = 4;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    brush = [[LTEdgeAvoidingBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    brush.hardness = 1;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:LTVector4Zero];
    
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
        const LTVector4 kIntensity = LTVector4(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTLTVector4ToVec4b(kIntensity));
        expected.colRange(1, 3).setTo(LTLTVector4ToVec4b(kIntensity));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
    
    context(@"direct erasing mode", ^{
      beforeEach(^{
        [fbo clearWithColor:LTVector4One];
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
        const LTVector4 kIntensity = LTVector4(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTLTVector4ToVec4b(LTVector4One - kIntensity));
        expected.colRange(1, 3).setTo(LTLTVector4ToVec4b(LTVector4One - kIntensity));
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
        [fbo clearWithColor:LTVector4Zero];
        
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
        const LTVector4 kIntensity = LTVector4(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.2), half(0.3), half(0.4)));
        expected.colRange(1, 3).setTo(-cv::Vec4hf(half(0.1), half(0.2), half(0.3), half(0.4)));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });

    context(@"blending mode", ^{
      const LTVector4 kColor(0.25, 0.5, 0.75, 1);
      const cv::Vec4b kCvColor = LTLTVector4ToVec4b(kColor);
      
      beforeEach(^{
        [fbo clearWithColor:kColor];
        expected.setTo(kCvColor);
        brush.mode = LTRoundBrushModeBlend;
      });

      it(@"drawing should be additive", ^{
        brush.hardness = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 36), NO));
        expected.colRange(1, 3).setTo(LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 36), NO));
        expected(cv::Rect(1, 1, 2, 2)).setTo(LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 172), NO));
        expect($(output.image)).to.beCloseToMat($(expected));
      });

      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        expected.rowRange(1, 3).setTo(LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 26), NO));
        expected.colRange(1, 3).setTo(LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 26), NO));
        expect($(output.image)).to.beCloseToMat($(expected));
      });

      it(@"should draw with updated flow", ^{
        brush.flow = 0.1;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        cv::Vec4b blendedOnce = LTBlend(kCvColor, cv::Vec4b(255, 255, 255, 26), NO);
        expected.rowRange(1, 3).setTo(blendedOnce);
        expected.colRange(1, 3).setTo(blendedOnce);
        expect($(output.image)).to.beCloseToMat($(expected));
        [brush drawPoint:point inFramebuffer:fbo];
        cv::Vec4b blendedTwice = LTBlend(blendedOnce, cv::Vec4b(255, 255, 255, 26), NO);
        expected.rowRange(1, 3).setTo(blendedTwice);
        expected.colRange(1, 3).setTo(blendedTwice);
        expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
      });

      it(@"should draw with updated intensity", ^{
        const LTVector4 kIntensity = LTVector4(0.1, 0.2, 0.3, 0.4);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        cv::Vec4b blended = LTBlend(kCvColor, LTLTVector4ToVec4b(kIntensity), NO);
        expected.rowRange(1, 3).setTo(blended);
        expected.colRange(1, 3).setTo(blended);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
  });
});

context(@"edge avoiding drawing", ^{
  __block cv::Mat4b expected;
  __block CGRect similarSubrect;
  __block LTEdgeAvoidingBrush *brush;
  __block LTTexture *output;
  __block LTTexture *inputTexture;
  __block LTFbo *fbo;
  __block LTPainterPoint *point;
  
  const LTVector4 kBackgroundColor = LTVector4(0, 0, 0, 0);
  const CGFloat kBaseBrushDiameter = 16;
  const CGFloat kTargetBrushDiameter = 16;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    cv::Mat4b inputMat(kOutputSize.height, kOutputSize.width);
    inputMat = cv::Vec4b(0, 0, 0, 255);
    similarSubrect = CGRectMake(kOutputSize.width / 4, kOutputSize.height / 4,
                                kOutputSize.width / 2, kOutputSize.height / 2);
    inputMat(LTCVRectWithCGRect(similarSubrect)).setTo(255);
    inputTexture = [LTTexture textureWithImage:inputMat];
    
    brush = [[LTEdgeAvoidingBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    brush.inputTexture = inputTexture;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackgroundColor];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected = cv::Scalar(0);
    
    point = [[LTPainterPoint alloc] init];
    point.zoomScale = 1;
    point.contentPosition = kOutputCenter;
  });
  
  afterEach(^{
    inputTexture = nil;
    fbo = nil;
    output = nil;
    brush = nil;
  });
  
  it(@"should have edge avoiding effect", ^{
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = output.image;
    expected.rowRange(0, kOutputSize.height / 4).setTo(0);
    expected.colRange(0, kOutputSize.width / 4).setTo(0);
    expected.rowRange(kOutputSize.height * 0.75, kOutputSize.height).setTo(0);
    expected.colRange(kOutputSize.width * 0.75, kOutputSize.width).setTo(0);
    
    [fbo clearWithColor:kBackgroundColor];
    brush.sigma = brush.minSigma;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"setting the inputTexture to nil should disable the edge-avoiding effect", ^{
    LTRoundBrush *roundBrush = [[LTRoundBrush alloc] init];
    roundBrush.baseDiameter = brush.baseDiameter;
    roundBrush.scale = brush.scale;;
    roundBrush.hardness = brush.hardness;
    [roundBrush startNewStrokeAtPoint:point];
    [roundBrush drawPoint:point inFramebuffer:fbo];
    cv::Mat4b roundBrushOutput = output.image;
    
    [fbo clearWithColor:kBackgroundColor];
    brush.inputTexture = nil;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expect($(output.image)).to.beCloseToMat($(roundBrushOutput));
  });
  
  it(@"bigger sigma should weaken the edge avoiding effect", ^{
    brush.sigma = brush.minSigma;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    cv::Mat4b minSigma = output.image;
    
    [fbo clearWithColor:kBackgroundColor];
    brush.sigma = 0.5;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    cv::Mat4b midSigma = output.image;
    expect($(midSigma)).notTo.beCloseToMat($(minSigma));
    expect($(midSigma(LTCVRectWithCGRect(similarSubrect))))
        .to.beCloseToMat($(minSigma(LTCVRectWithCGRect(similarSubrect))));
    
    [fbo clearWithColor:kBackgroundColor];
    brush.sigma = brush.maxSigma;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    cv::Mat4b maxSigma = output.image;
    
    expect($(maxSigma)).notTo.beCloseToMat($(minSigma));
    expect($(maxSigma(LTCVRectWithCGRect(similarSubrect))))
        .to.beCloseToMat($(minSigma(LTCVRectWithCGRect(similarSubrect))));

    [fbo clearWithColor:kBackgroundColor];
    brush.inputTexture = nil;
    brush.sigma = brush.maxSigma;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expect($(output.image)).to.beCloseToMatWithin($(maxSigma), 5);
  });
});

LTSpecEnd
