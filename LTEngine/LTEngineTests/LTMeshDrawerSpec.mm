// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMeshDrawer.h"

#import <LTKit/LTRandom.h>

#import "LTFbo.h"
#import "LTTextureDrawerExamples.h"
#import "LTTexture+Factory.h"

SpecBegin(LTMeshDrawer)

static NSString * const kFragmentWithUniformSource =
    @"uniform sampler2D sourceTexture;"
    "uniform highp vec4 outputColor;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  sourceTexture;"
    "  gl_FragColor = outputColor;"
    "}";

static const CGSize kInputSize = CGSizeMake(32, 64);
static const CGSize kMeshSize = CGSizeMake(4, 8);

__block LTMeshDrawer *drawer;
__block LTTexture *inputTexture;
__block LTTexture *meshTexture;

beforeEach(^{
  inputTexture = [LTTexture byteRGBATextureWithSize:kInputSize];
  inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
  
  meshTexture = [LTTexture textureWithSize:kMeshSize + CGSizeMakeUniform(1)
                                 precision:LTTexturePrecisionHalfFloat
                                    format:LTTextureFormatRG allocateMemory:YES];
  [meshTexture clearWithColor:LTVector4Zero];
  
  drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture];
});

afterEach(^{
  drawer = nil;
  inputTexture = nil;
  meshTexture = nil;
});

context(@"initialization", ^{
  context(@"passthrough", ^{
    it(@"should initialize with a valid mesh texture", ^{
      drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture];
    });
    
    it(@"should raise when initializing without a source texture", ^{
      expect(^{
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:nil meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing without a mesh texture", ^{
      expect(^{
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:nil];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      expect(^{
        meshTexture = [LTTexture textureWithSize:kMeshSize precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRed allocateMemory:YES];
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      expect(^{
        meshTexture = [LTTexture textureWithSize:kMeshSize precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRG allocateMemory:YES];
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });
  });
  
  context(@"custom fragment shader", ^{
    it(@"should initialize with a valid mesh texture", ^{
      drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                            fragmentSource:kFragmentWithUniformSource];
    });
    
    it(@"should raise when initializing without a source texture", ^{
      expect(^{
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:nil meshTexture:meshTexture
                                              fragmentSource:kFragmentWithUniformSource];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing without a mesh texture", ^{
      expect(^{
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:nil
                                              fragmentSource:kFragmentWithUniformSource];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      expect(^{
        meshTexture = [LTTexture textureWithSize:kMeshSize precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRed allocateMemory:YES];
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                              fragmentSource:kFragmentWithUniformSource];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      expect(^{
        meshTexture = [LTTexture textureWithSize:kMeshSize precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRG allocateMemory:YES];
        drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                              fragmentSource:kFragmentWithUniformSource];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"properties", ^{
  it(@"should have default properties", ^{
    expect(drawer.drawWireframe).to.beFalsy();
  });
  
  it(@"should set drawWireframe", ^{
    drawer.drawWireframe = YES;
    expect(drawer.drawWireframe).to.beTruthy();
  });
});

context(@"drawing", ^{
  using half_float::half;

  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b expected;
  __block cv::Mat4b wireframe;
  __block cv::Mat4b warped;
  
  beforeEach(^{
    output = [LTTexture byteRGBATextureWithSize:inputTexture.size];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:LTVector4Zero];
    
    cellSize = kInputSize / kMeshSize;
    cellRadius = cellSize / 2;
    
    wireframe.create(inputTexture.size.height, inputTexture.size.width);
    wireframe.setTo(0);
    [inputTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      LTRandom *random = [[LTRandom alloc] initWithSeed:0];
      cv::Mat4b mat = *mapped;
      for (int i = 0; i < kMeshSize.height; ++i) {
        for (int j = 0; j < kMeshSize.width; ++j) {
          cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
          cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256], 255);
          mat(rect).setTo(color);
          wireframe(rect).setTo(color);
          CGSize sizeDelta = CGSizeMake(j < kMeshSize.width - 1 ? 1 : 2,
                                        i < kMeshSize.height - 1 ? 1 : 2);
          rect = cv::Rect(j * cellSize.width + 1, i * cellSize.height + 1,
                          cellSize.width - sizeDelta.width, cellSize.height - sizeDelta.height);
          wireframe(rect).setTo(0);
        }
      }
    }];
    
    expected.create(inputTexture.size.height, inputTexture.size.width);
    expected.setTo(cv::Vec4b(0, 0, 0, 255));
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
  });
  
  it(@"should draw displaced texture", ^{
    [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec2hf(half(0)));
      mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
      mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
    }];
    [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
            fromRect:CGRectFromSize(inputTexture.size)];

    expected = inputTexture.image;
    expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
        .copyTo(expected.colRange(cellRadius.width, cellSize.width));
    cv::flip(expected, expected, 1);
    expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
        .copyTo(expected.colRange(cellRadius.width, cellSize.width));
    cv::flip(expected, expected, 1);
    expect($(output.image)).to.equalMat($(expected));
    
    [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec2hf(half(0)));
      mapped->row(1).setTo(cv::Vec2hf(half(0), half(-0.5 / kMeshSize.height)));
      mapped->row(mapped->rows - 2).setTo(cv::Vec2hf(half(0), half(0.5 / kMeshSize.height)));
    }];
    [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
            fromRect:CGRectFromSize(inputTexture.size)];

    expected = inputTexture.image;
    expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
        .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
    cv::flip(expected, expected, 0);
    expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
        .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
    cv::flip(expected, expected, 0);
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw displaced wireframe", ^{
    drawer.drawWireframe = YES;
    [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec2hf(half(0)));
      mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
    }];
    [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
            fromRect:CGRectFromSize(inputTexture.size)];

    wireframe.copyTo(expected);
    expected.colRange(cellSize.width, cellSize.width + cellRadius.width + 1)
        .copyTo(expected.colRange(cellRadius.width, cellSize.width + 1));
    expect($(output.image)).to.equalMat($(expected));
    
    [output clearWithColor:LTVector4Zero];
    [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec2hf(half(0)));
      mapped->row(1).setTo(cv::Vec2hf(half(0), half(-0.5 / kMeshSize.height)));
    }];
    [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
            fromRect:CGRectFromSize(inputTexture.size)];

    wireframe.copyTo(expected);
    expected.rowRange(cellSize.height, cellSize.height + cellRadius.height + 1)
        .copyTo(expected.rowRange(cellRadius.height, cellSize.height + 1));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  context(@"subrects", ^{
    beforeEach(^{
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];
      warped = output.image;
      [output clearWithColor:LTVector4Zero];
    });
    
    context(@"framebuffer", ^{
      it(@"should draw subrect of input to entire output", ^{
        CGRect targetRect = CGRectFromSize(fbo.size);
        CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                    inputTexture.size / 2);
        [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
        
        cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
        cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw all input to subrect of output", ^{
        CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
        CGRect sourceRect = CGRectFromSize(inputTexture.size);
        [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
        
        cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
        cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
        expected.setTo(0);
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw subrect of input to subrect of output", ^{
        CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
        CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                    inputTexture.size / 2);
        [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
        
        cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
        expected.setTo(0);
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        expect($(output.image)).to.equalMat($(expected));
      });
    });
    
    context(@"screen framebuffer", ^{
      it(@"should draw subrect of input to entire output", ^{
        CGRect targetRect = CGRectFromSize(fbo.size);
        CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                    inputTexture.size / 2);
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
        }];
        
        cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
        cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
        cv::flip(expected, expected, 0);
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw all input to subrect of output", ^{
        CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
        CGRect sourceRect = CGRectFromSize(inputTexture.size);
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
        }];
        
        cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
        cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
        expected.setTo(0);
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        cv::flip(expected, expected, 0);
        expect($(output.image)).to.equalMat($(expected));
      });
      
      it(@"should draw subrect of input to subrect of output", ^{
        CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
        CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                    inputTexture.size / 2);
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
        }];
        
        cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
        expected.setTo(0);
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        cv::flip(expected, expected, 0);
        expect($(output.image)).to.equalMat($(expected));
      });
    });
  });
});

SpecEnd
