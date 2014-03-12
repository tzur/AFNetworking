// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

#import "LTBrushSpec.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTPainterPoint.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTextureBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTTextureBrush class]});

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

__block LTTextureBrush *brush;

beforeEach(^{
  brush = [[LTTextureBrush alloc] init];
});

afterEach(^{
  brush = nil;
});

context(@"properties", ^{
  const CGSize kSize = CGSizeMakeUniform(2);

  it(@"should have default properties", ^{
    cv::Mat4b expected(1, 1);
    expected.setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(brush.texture.image)).to.equalMat($(expected));
    expect(brush.premultipliedAlpha).to.beFalsy();
    expect(brush.spacing).to.equal(2);
  });
  
  it(@"should set premultipliedAlpha", ^{
    BOOL oldValue = brush.premultipliedAlpha;
    brush.premultipliedAlpha = !oldValue;
    expect(brush.premultipliedAlpha).to.equal(!oldValue);
  });
  
  it(@"should set texture", ^{
    LTTexture *byteTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *halfTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionHalfFloat
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *floatTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionFloat
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    brush.texture = byteTexture;
    expect(brush.texture).to.beIdenticalTo(byteTexture);
    brush.texture = halfTexture;
    expect(brush.texture).to.beIdenticalTo(halfTexture);
    brush.texture = floatTexture;
    expect(brush.texture).to.beIdenticalTo(floatTexture);
  });
  
  it(@"should not set non rgba textures", ^{
    expect(^{
      LTTexture *redTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                  format:LTTextureFormatRed allocateMemory:YES];
      brush.texture = redTexture;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      LTTexture *rgTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRG allocateMemory:YES];
      brush.texture = rgTexture;
    }).to.raise(NSInvalidArgumentException);
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
    brush = [[LTTextureBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 0)];
    
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
      newTexture(cv::Rect(0, kHalf.height, kHalf.width, kHalf.height)) = cv::Vec4b(0, 0, 255, 255);
      newTexture(cv::Rect(kHalf.width, kHalf.height, kHalf.width, kHalf.height)) =
          cv::Vec4b(255, 255, 0, 255);
      brush.texture = [LTTexture textureWithImage:newTexture];
      brush.texture.minFilterInterpolation = LTTextureInterpolationNearest;
      brush.texture.magFilterInterpolation = LTTextureInterpolationNearest;
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
      beforeEach(^{
        brushMat.create(output.size.height, output.size.width);
        brushMat.rowRange(0, kHeight).setTo(cv::Vec4b(32, 32, 32, 32));
        brushMat.rowRange(kHeight, kOutputSize.height).setTo(cv::Vec4b(32, 64, 128, 128));
        brush.premultipliedAlpha = NO;
        brush.texture = [LTTexture textureWithImage:brushMat];
        
        expected(kTopLeft).setTo(cv::Vec4b(64, 0, 0, 64));
        expected(kTopRight).setTo(cv::Vec4b(0, 64, 0, 191));
        expected(kBottomLeft).setTo(cv::Vec4b(0, 0, 64, 64));
        expected(kBottomRight).setTo(cv::Vec4b(64, 64, 0, 191));
        [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          expected.copyTo(*mapped);
        }];
      });
      
      it(@"drawing should blend with previous target", ^{
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];

        expected(kTopLeft).setTo(cv::Vec4b(52, 12, 12, 0.35 * 255));
        expected(kTopRight).setTo(cv::Vec4b(5, 59, 5, 0.78 * 255));
        expected(kBottomLeft).setTo(cv::Vec4b(26, 51, 115, 0.63 * 255));
        expected(kBottomRight).setTo(cv::Vec4b(46, 64, 73, 0.88 * 255));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.25;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(52, 12, 12, 0.35 * 255));
        expected(kTopRight).setTo(cv::Vec4b(5, 59, 5, 0.78 * 255));
        expected(kBottomLeft).setTo(cv::Vec4b(18, 37, 101, 0.44 * 255));
        expected(kBottomRight).setTo(cv::Vec4b(54, 64, 40, 0.81 * 255));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated flow", ^{
        brush.flow = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(58, 6, 6, 0.3 * 255));
        expected(kTopRight).setTo(cv::Vec4b(3, 61, 3, 0.77 * 255));
        expected(kBottomLeft).setTo(cv::Vec4b(18, 37, 101, 0.44 * 255));
        expected(kBottomRight).setTo(cv::Vec4b(54, 64, 40, 0.81 * 255));
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated intensity", ^{
        const GLKVector4 kIntensity = GLKVector4Make(0.3125, 0.4375, 0.5625, 0.8);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(49, 4, 5, 0.32 * 255));
        expected(kTopRight).setTo(cv::Vec4b(1, 58, 2, 0.77 * 255));
        expected(kBottomLeft).setTo(cv::Vec4b(7, 20, 70, 0.55 * 255));
        expected(kBottomRight).setTo(cv::Vec4b(39, 47, 34, 0.85 * 255));
        
        expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
      });
    });
            
    context(@"premultipliedAlpha is YES", ^{
      beforeEach(^{
        brushMat.create(output.size.height, output.size.width);
        brushMat.rowRange(0, kHeight).setTo(cv::Vec4b(4, 4, 4, 32));
        brushMat.rowRange(kHeight, kOutputSize.height).setTo(cv::Vec4b(16, 32, 64, 128));
        brush.premultipliedAlpha = YES;
        brush.texture = [LTTexture textureWithImage:brushMat];
        
        expected(kTopLeft).setTo(cv::Vec4b(16, 0, 0, 64));
        expected(kTopRight).setTo(cv::Vec4b(0, 48, 0, 191));
        expected(kBottomLeft).setTo(cv::Vec4b(0, 0, 16, 64));
        expected(kBottomRight).setTo(cv::Vec4b(48, 48, 0, 191));
        [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          expected.copyTo(*mapped);
        }];
      });
      
      it(@"drawing should blend with previous target", ^{
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(52, 12, 12, 255) * 0.35);
        expected(kTopRight).setTo(cv::Vec4b(5, 59, 5, 255) * 0.78);
        expected(kBottomLeft).setTo(cv::Vec4b(26, 51, 115, 255) * 0.63);
        expected(kBottomRight).setTo(cv::Vec4b(46, 64, 73, 255) * 0.88);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated opacity", ^{
        brush.opacity = 0.25;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(52, 12, 12, 255) * 0.35);
        expected(kTopRight).setTo(cv::Vec4b(5, 59, 5, 255) * 0.78);
        expected(kBottomLeft).setTo(cv::Vec4b(18, 37, 101, 255) * 0.44);
        expected(kBottomRight).setTo(cv::Vec4b(54, 64, 40, 255) * 0.81);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated flow", ^{
        brush.flow = 0.5;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(58, 6, 6, 255) * 0.3);
        expected(kTopRight).setTo(cv::Vec4b(3, 61, 3, 255) * 0.77);
        expected(kBottomLeft).setTo(cv::Vec4b(18, 37, 101, 255) * 0.44);
        expected(kBottomRight).setTo(cv::Vec4b(54, 64, 40, 255) * 0.81);
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should draw with updated intensity", ^{
        const GLKVector4 kIntensity = GLKVector4Make(0.5, 0.75, 0.5, 1.0);
        brush.intensity = kIntensity;
        [brush startNewStrokeAtPoint:point];
        [brush drawPoint:point inFramebuffer:fbo];
        
        expected(kTopLeft).setTo(cv::Vec4b(47, 9, 6, 255) * 0.34);
        expected(kTopRight).setTo(cv::Vec4b(3, 58, 3, 255) * 0.78);
        expected(kBottomLeft).setTo(cv::Vec4b(13, 38, 64, 255) * 0.63);
        expected(kBottomRight).setTo(cv::Vec4b(37, 55, 37, 255) * 0.87);
        
        expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
      });
    });
  });
});

SpecEnd
