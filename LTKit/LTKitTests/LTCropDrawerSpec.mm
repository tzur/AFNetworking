// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCropDrawer.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTCropDrawer)

__block LTCropDrawer *drawer;
__block LTTexture *inputTexture;

const cv::Vec4b kBlack(0, 0, 0, 255);
const cv::Vec4b kRed(255, 0, 0, 255);
const cv::Vec4b kBlue(0, 0, 255, 255);

beforeEach(^{
  cv::Mat4b input(32, 32, kBlack);
  input(cv::Rect(0, 0, input.cols / 2, input.rows / 2)).setTo(kRed);
  input(cv::Rect(input.cols / 2, 0, input.cols / 2, input.rows / 2)).setTo(kBlue);
  inputTexture = [LTTexture textureWithImage:input];
  inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
});

afterEach(^{
  drawer = nil;
  inputTexture = nil;
});

context(@"initialization", ^{
  it(@"should initialize with a valid texture", ^{
    expect(^{
      drawer = [[LTCropDrawer alloc] initWithTexture:inputTexture];
    }).notTo.raiseAny();
  });
  
  it(@"should raise when initializing without a texture", ^{
    expect(^{
      drawer = [[LTCropDrawer alloc] initWithTexture:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"drawing", ^{
  __block cv::Mat4b expected;
  __block LTFbo *fbo;
  __block LTTexture *outputTexture;
  __block LTCropDrawerRect targetRect;
  __block LTCropDrawerRect sourceRect;
  
  beforeEach(^{
    drawer = [[LTCropDrawer alloc] initWithTexture:inputTexture];
  });
  
  afterEach(^{
    fbo = nil;
    outputTexture = nil;
  });
  
  context(@"target texture of the same size", ^{
    beforeEach(^{
      outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
      fbo = [[LTFbo alloc] initWithTexture:outputTexture];
      targetRect = CGRectFromSize(fbo.size);
      sourceRect = CGRectFromSize(inputTexture.size);
    });
    
    it(@"should draw", ^{
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected = inputTexture.image;
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw horizontally flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.topLeft,
                                    sourceRect.bottomRight, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected = inputTexture.image;
      cv::flip(expected, expected, 1);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw vertically flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.bottomLeft, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.topRight);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected = inputTexture.image;
      cv::flip(expected, expected, 0);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw rotated source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected = inputTexture.image;
      cv::transpose(expected, expected);
      cv::flip(expected, expected, 0);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
  });
  
  context(@"should draw subrect of input to entire output", ^{
    beforeEach(^{
      outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
      fbo = [[LTFbo alloc] initWithTexture:outputTexture];
      targetRect = CGRectFromSize(fbo.size);
      sourceRect = CGRectFromSize(CGSizeMake(inputTexture.size.width / 2,
                                             inputTexture.size.height));
      expected.create(outputTexture.size.height, outputTexture.size.height);
      expected.setTo(kBlack);
    });
    
    it(@"should draw", ^{
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.rowRange(0, expected.rows / 2).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw horizontally flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.topLeft,
                                    sourceRect.bottomRight, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.rowRange(0, expected.rows / 2).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw vertically flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.bottomLeft, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.topRight);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.rowRange(expected.rows / 2, expected.rows).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw rotated source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.colRange(0, expected.cols / 2).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
  });
  
  context(@"should draw all input to subrect of output", ^{
    beforeEach(^{
      outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
      fbo = [[LTFbo alloc] initWithTexture:outputTexture];
      targetRect = CGRectFromSize(CGSizeMake(fbo.size.width / 2, fbo.size.height));
      sourceRect = CGRectFromSize(inputTexture.size);
      expected.create(outputTexture.size.height, outputTexture.size.height);
      [fbo clearWithColor:GLKVector4Zero];
      expected.setTo(0);
    });
    
    it(@"should draw", ^{
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.colRange(0, expected.cols / 2).setTo(kBlack);
      expected(cv::Rect(0, 0, expected.cols / 4, expected.rows / 2)).setTo(kRed);
      expected(cv::Rect(expected.cols / 4, 0, expected.cols / 4, expected.rows / 2)).setTo(kBlue);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw horizontally flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.topLeft,
                                    sourceRect.bottomRight, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.colRange(0, expected.cols / 2).setTo(kBlack);
      expected(cv::Rect(0, 0, expected.cols / 4, expected.rows / 2)).setTo(kBlue);
      expected(cv::Rect(expected.cols / 4, 0, expected.cols / 4, expected.rows / 2)).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw vertically flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.bottomLeft, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.topRight);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.colRange(0, expected.cols / 2).setTo(kBlack);
      expected(cv::Rect(0, expected.rows / 2, expected.cols / 4, expected.rows / 2)).setTo(kRed);
      expected(cv::Rect(expected.cols / 4, expected.rows / 2,
                        expected.cols / 4, expected.rows / 2)).setTo(kBlue);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw rotated source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.colRange(0, expected.cols / 2).setTo(kBlack);
      expected(cv::Rect(0, 0, expected.cols / 4, expected.rows / 2)).setTo(kBlue);
      expected(cv::Rect(0, expected.rows / 2, expected.cols / 4, expected.rows / 2)).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
  });
  
  context(@"should draw subrect of input to subrect of output", ^{
    beforeEach(^{
      outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
      fbo = [[LTFbo alloc] initWithTexture:outputTexture];
      targetRect = CGRectFromSize(CGSizeMake(fbo.size.width, fbo.size.height / 2));
      sourceRect = CGRectFromSize(CGSizeMake(inputTexture.size.width,
                                             inputTexture.size.height / 2));
      expected.create(outputTexture.size.height, outputTexture.size.height);
      [fbo clearWithColor:GLKVector4Zero];
      expected.setTo(0);
    });
    
    it(@"should draw", ^{
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected(cv::Rect(0, 0, expected.cols / 2, expected.rows / 2)).setTo(kRed);
      expected(cv::Rect(expected.cols / 2, 0, expected.cols / 2, expected.rows / 2)).setTo(kBlue);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw horizontally flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.topLeft,
                                    sourceRect.bottomRight, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected(cv::Rect(0, 0, expected.cols / 2, expected.rows / 2)).setTo(kBlue);
      expected(cv::Rect(expected.cols / 2, 0, expected.cols / 2, expected.rows / 2)).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw vertically flipped source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.bottomLeft, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.topRight);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected(cv::Rect(0, 0, expected.cols / 2, expected.rows / 2)).setTo(kRed);
      expected(cv::Rect(expected.cols / 2, 0, expected.cols / 2, expected.rows / 2)).setTo(kBlue);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw rotated source", ^{
      sourceRect = LTCropDrawerRect(sourceRect.topRight, sourceRect.bottomRight,
                                    sourceRect.topLeft, sourceRect.bottomLeft);
      [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
      expected.rowRange(0, expected.rows / 4).setTo(kBlue);
      expected.rowRange(expected.rows / 4, expected.rows / 2).setTo(kRed);
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
  });
  
  context(@"should draw to bound framebuffer", ^{
    beforeEach(^{
      outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
      fbo = [[LTFbo alloc] initWithTexture:outputTexture];
      targetRect = CGRectFromSize(fbo.size);
      sourceRect = CGRectFromSize(inputTexture.size);
    });
    
    it(@"should draw to framebuffer", ^{
      [fbo bindAndDraw:^{
        [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
        expected = inputTexture.image;
      }];
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should draw to screen", ^{
      [fbo bindAndDrawOnScreen:^{
        [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
        expected = inputTexture.image;
        cv::flip(expected, expected, 0);
      }];
      expect($(outputTexture.image)).to.equalMat($(expected));
    });
  });
});

LTSpecEnd
