// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTEdgeAvoidingMultiTextureBrush.h"

#import "LTBrushEffectExamples.h"
#import "LTTextureBrushExamples.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTEdgeAvoidingMultiTextureBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTEdgeAvoidingMultiTextureBrush class]});

itShouldBehaveLike(kLTBrushEffectLTBrushExamples,
                   @{kLTBrushClass: [LTEdgeAvoidingMultiTextureBrush class]});

itShouldBehaveLike(kLTTextureBrushExamples,
                   @{kLTTextureBrushClass: [LTEdgeAvoidingMultiTextureBrush class]});

__block LTEdgeAvoidingMultiTextureBrush *brush;

context(@"properties", ^{
  const CGFloat kEpsilon = 1e-6;
  const CGSize kSize = CGSizeMakeUniform(2);
  
  beforeEach(^{
    brush = [[LTEdgeAvoidingMultiTextureBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    cv::Mat4b expectedTexture(1, 1);
    cv::Mat4b expectedInputTexture(1, 1);
    expectedTexture.setTo(cv::Vec4b(255, 255, 255, 255));
    expectedInputTexture.setTo(cv::Vec4b(0, 0, 0, 0));
    expect(brush.textures.count).to.equal(1);
    expect($([(LTTexture *)brush.textures.firstObject image])).to.equalMat($(expectedTexture));
    expect(brush.sigma).to.equal(1.0);
    expect(brush.inputTexture).to.beNil();
  });
  
  it(@"should set textures", ^{
    LTTexture *byteTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *halfTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionHalfFloat
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *floatTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionFloat
                                                  format:LTTextureFormatRGBA allocateMemory:YES];
    NSArray *textures = [@[byteTexture, halfTexture, floatTexture] mutableCopy];
    brush.textures = textures;
    expect(brush.textures).notTo.beIdenticalTo(textures);
    expect(brush.textures.count).to.equal(textures.count);
    for (NSUInteger i = 0; i < textures.count; ++i) {
      expect(brush.textures[i]).to.beIdenticalTo(textures[i]);
    }
  });
  
  it(@"should not set non rgba textures", ^{
    expect(^{
      LTTexture *redTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                  format:LTTextureFormatRed allocateMemory:YES];
      brush.textures = @[redTexture];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      LTTexture *rgTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRG allocateMemory:YES];
      brush.textures = @[rgTexture];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set sigma", ^{
    const CGFloat newValue = 0.5;
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
    expect(brush.inputTexture).to.beNil();
    brush.inputTexture = [LTTexture textureWithImage:newInputTexture];
    expect($(brush.inputTexture.image)).to.equalMat($(newInputTexture));
    brush.inputTexture = nil;
    expect(brush.inputTexture).to.beNil();
  });
});

context(@"edge avoiding drawing", ^{
  __block cv::Mat4b expected;
  __block CGRect similarSubrect;
  __block LTEdgeAvoidingMultiTextureBrush *brush;
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
    
    brush = [[LTEdgeAvoidingMultiTextureBrush alloc] init];
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
  
  it(@"should disable the edge-avoiding effect when setting sigma to 1.0", ^{
    brush.intensity = LTVector4One;
    brush.sigma = 1.0;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected.setTo(255);
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should have edge avoiding effect when sigma < 1.0", ^{
    brush.intensity = LTVector4One;
    brush.sigma = 1.0;
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

  it(@"should use the target framebuffer instead when setting the inputTexture to nil", ^{
    brush.sigma = brush.minSigma;
    brush.intensity = LTVector4(0.5, 0.5, 0.5, 1.0);
    brush.inputTexture = nil;

    [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec4b(0, 0, 0, 255));
      (*mapped)(LTCVRectWithCGRect(similarSubrect)).setTo(cv::Vec4b(128, 128, 128, 255));
    }];

    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected.setTo(cv::Vec4b(0, 0, 0, 255));
    expected(LTCVRectWithCGRect(similarSubrect)).setTo(cv::Vec4b(128, 128, 128, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
    
    expected.setTo(cv::Vec4b(128, 128, 128, 255));
    brush.sigma = 1.0;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
