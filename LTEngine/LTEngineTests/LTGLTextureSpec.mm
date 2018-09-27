// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "CVPixelBuffer+LTEngine.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTextureBasicExamples.h"

@interface LTGLTexture ()
- (void)readRect:(CGRect)rect toImage:(cv::Mat *)image;
@end

SpecBegin(LTGLTexture)

itShouldBehaveLike(kLTTextureBasicExamples, @{
  kLTTextureBasicExamplesTextureClass: [LTGLTexture class]
});

context(@"mipmapping", ^{
  context(@"construction from a single image", ^{
    it(@"should initialize with a single image", ^{
      cv::Mat4b image(128, 64);
      image.setTo(cv::Vec4b(255, 255, 255, 255));

      expect(^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
      }).toNot.raiseAny();
    });

    it(@"should set correct number of mipmap levels", ^{
      cv::Mat4b image(128, 64);
      image.setTo(cv::Vec4b(255, 255, 255, 255));

      LTGLTexture *texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];

      expect(texture.maxMipmapLevel).to.equal(7);
    });
  });

  context(@"construction from multiple images", ^{
    it(@"should initialize with an array of images", ^{
      expect((^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{
          cv::Mat4b(128, 64), cv::Mat4b(64, 32), cv::Mat4b(32, 16)
        }];
      })).toNot.raiseAny();
    });

    it(@"should not initialize with an empty array", ^{
      expect((^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{}];
      })).to.raise(NSInvalidArgumentException);
    });

    it(@"should not initialize with an empty array", ^{
      expect((^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{}];
      })).to.raise(NSInvalidArgumentException);
    });

    it(@"should not initialize with non dyadic downscaling of previous image", ^{
      expect((^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{
          cv::Mat4b(128, 64), cv::Mat4b(64, 31), cv::Mat4b(32, 15)
        }];
      })).to.raise(NSInvalidArgumentException);
    });

    it(@"should set correct number of mipmap levels", ^{
      LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{
        cv::Mat4b(128, 64), cv::Mat4b(64, 32), cv::Mat4b(32, 16)
      }];

      expect(texture.maxMipmapLevel).to.equal(2);
    });

    it(@"should initialize with properties of other texture", ^{
      LTGLTexture *texture = [[LTGLTexture alloc]
                              initWithMipmapImages:{cv::Mat4b(128, 64), cv::Mat4b(64, 32)}];
      LTGLTexture *other = [[LTGLTexture alloc] initWithPropertiesOf:texture];
      expect(other.size).to.equal(texture.size);
      expect(other.pixelFormat).to.equal(texture.pixelFormat);
      expect(other.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
      expect(^{
        [other clearColor:LTVector4::zeros()];
      }).notTo.raiseAny();
    });

    it(@"should initialize with properties", ^{
      LTGLTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(64, 128)
                                                   pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                                maxMipmapLevel:3];

      expect(texture.size).to.equal(CGSizeMake(64, 128));
      expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
      expect(texture.maxMipmapLevel).to.equal(3);
      expect(^{
        [texture clearColor:LTVector4::zeros()];
      }).notTo.raiseAny();
    });
  });

  context(@"drawing", ^{
    __block LTGLTexture *texture;
    __block LTGLTexture *target;
    __block LTProgram *program;
    __block LTRectDrawer *drawer;
    __block LTFbo *fbo;
    __block cv::Mat4b imageA;
    __block cv::Mat4b imageB;
    __block cv::Mat4b imageC;
    __block cv::Mat4b imageD;

    beforeEach(^{
      imageA.create(64, 64);
      imageA.setTo(cv::Vec4b(255, 0, 0, 255));

      imageB.create(32, 32);
      imageB.setTo(cv::Vec4b(0, 255, 0, 255));

      imageC.create(16, 16);
      imageC.setTo(cv::Vec4b(0, 0, 255, 255));

      imageD.create(8, 8);
      imageD.setTo(cv::Vec4b(255, 255, 255, 255));

      texture = [[LTGLTexture alloc] initWithMipmapImages:{imageA, imageB, imageC, imageD}];

      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:[PassthroughFsh source]];
      drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];
      target = [[LTGLTexture alloc] initWithSize:CGSizeMake(64, 64)
                                     pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                  allocateMemory:YES];
      fbo = [[LTFbo alloc] initWithTexture:target];
    });

    afterEach(^{
      texture = nil;
      target = nil;
      program = nil;
      drawer = nil;
      fbo = nil;
    });

    it(@"should return image at level", ^{
      expect($([texture imageAtLevel:0])).to.equalMat($(imageA));
      expect($([texture imageAtLevel:1])).to.equalMat($(imageB));
      expect($([texture imageAtLevel:2])).to.equalMat($(imageC));
      expect($([texture imageAtLevel:3])).to.equalMat($(imageD));
    });

    it(@"should clear all levels with color", ^{
      [texture clearColor:LTVector4(0.5, 0.5, 0.5, 1)];
      for (GLint i = 0; i < texture.maxMipmapLevel; ++i) {
        cv::Mat4b actual = [texture imageAtLevel:i];
        cv::Mat4b expected(actual.size(), cv::Vec4b(128, 128, 128, 255));
        expect($(actual)).to.equalMat($(expected));
      }
    });

    it(@"should clone texture", ^{
      LTGLTexture *cloned = (LTGLTexture *)[texture clone];
      expect(cloned).to.beKindOf(texture.class);
      expect(cloned.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
      for (GLint i = 0; i < texture.maxMipmapLevel; ++i) {
        cv::Mat4b actual = [cloned imageAtLevel:i];
        cv::Mat4b expected = [texture imageAtLevel:i];
        expect($(actual)).to.equalMat($(expected));
      }
    });

    it(@"should clone to texture", ^{
      LTGLTexture *cloned = (LTGLTexture *)[texture clone];
      [cloned clearColor:LTVector4::zeros()];
      [texture cloneTo:cloned];
      for (GLint i = 0; i < texture.maxMipmapLevel; ++i) {
        cv::Mat4b actual = [cloned imageAtLevel:i];
        cv::Mat4b expected = [texture imageAtLevel:i];
        expect($(actual)).to.equalMat($(expected));
      }
    });

    it(@"should raise if trying to clone to a texture with different number of mipmap levels", ^{
      LTGLTexture *other = [[LTGLTexture alloc] initWithMipmapImages:{imageA, imageB, imageC}];
      expect(^{
        [texture cloneTo:other];
      }).to.raise(NSInvalidArgumentException);
    });

    context(@"linear level interpolation", ^{
      beforeEach(^{
        texture.minFilterInterpolation = LTTextureInterpolationLinearMipmapLinear;
      });

      it(@"should draw base level", ^{
        [drawer drawRect:CGRectMake(0, 0, 64, 64) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, 64, 64)];

        expect(LTCompareMatWithValue(cv::Scalar(255, 0, 0, 255), [target image])).to.beTruthy();
      });

      it(@"should draw second level", ^{
        [drawer drawRect:CGRectMake(0, 0, 32, 32) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, 64, 64)];

        cv::Mat image([target image]);
        cv::Mat drawnPart = image(cv::Rect(0, 0, 32, 32));

        expect(LTCompareMatWithValue(cv::Scalar(0, 255, 0, 255), drawnPart)).to.beTruthy();
      });
    });

    context(@"nearest level interpolation", ^{
      beforeEach(^{
        texture.minFilterInterpolation = LTTextureInterpolationLinearMipmapNearest;
      });

      it(@"should draw base level", ^{
        [drawer drawRect:CGRectMake(0, 0, 64, 64) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, 64, 64)];

        expect(LTCompareMatWithValue(cv::Scalar(255, 0, 0, 255), [target image])).to.beTruthy();
      });

      it(@"should draw second level", ^{
        [drawer drawRect:CGRectMake(0, 0, 32, 32) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, 64, 64)];

        cv::Mat image([target image]);
        cv::Mat drawnPart = image(cv::Rect(0, 0, 32, 32));

        expect(LTCompareMatWithValue(cv::Scalar(0, 255, 0, 255), drawnPart)).to.beTruthy();
      });

      it(@"should select closest levels", ^{
        CGRect targetRect = CGRectMake(0, 0, 40, 40);
        [drawer drawRect:targetRect inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, 64, 64)];

        cv::Mat image([target image]);
        cv::Mat drawnPart = image(LTCVRectWithCGRect(targetRect));

        expect(LTCompareMatWithValue(cv::Scalar(0, 255, 0, 255), drawnPart)).to.beTruthy();
      });
    });
  });
});

context(@"pixel buffer", ^{
  it(@"should return pixel buffer with texture's content", ^{
    cv::Mat4b originalImage = cv::Mat4b(2, 1, cv::Vec4b(1, 2, 3, 4));
    LTGLTexture *texture = [[LTGLTexture alloc] initWithImage:originalImage];

    auto pixelBuffer = [texture pixelBuffer];
    LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
      expect($(image)).to.equalMat($(originalImage));
    });
  });

  // Power of two image tends to create continuous pixel buffers, which might trigger different
  // loading and storing behavious of a texture.
  it(@"should return pixel buffer with texture's content with large power of two image", ^{
    cv::Mat4b originalImage = cv::Mat4b(2048, 1024, cv::Vec4b(100, 150, 200, 250));
    LTGLTexture *texture = [[LTGLTexture alloc] initWithImage:originalImage];

    auto pixelBuffer = [texture pixelBuffer];
    LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
      expect($(image)).to.equalMat($(originalImage));
    });
  });

  it(@"should return pixel buffer of mipmap texture with content of the base level", ^{
    cv::Mat4b baseLevel = cv::Mat4b(2, 2, cv::Vec4b(1, 2, 3, 4));
    cv::Mat4b anotherLevel = cv::Mat4b(1, 1, cv::Vec4b(100, 101, 102, 103));

    LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{baseLevel, anotherLevel}];

    auto pixelBuffer = [texture pixelBuffer];
    LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
      expect($(image)).to.equalMat($(baseLevel));
    });
  });
});

context(@"non power of two mipmapping", ^{
  it(@"should initialize with a non-power-of-two single image", ^{
    cv::Mat4b image(127, 64);
    image.setTo(cv::Vec4b(255, 255, 255, 255));

    __block LTGLTexture *texture;
    expect(^{
      texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
    }).notTo.raiseAny();
    expect(texture).notTo.beNil();
  });

  it(@"should initialize with a non-power-of-two image", ^{
    cv::Mat4b image(127, 64);
    image.setTo(cv::Vec4b(255, 255, 255, 255));

    __block LTGLTexture *texture;
    expect((^{
      texture = [[LTGLTexture alloc] initWithMipmapImages:{image}];
    })).notTo.raiseAny();
    expect(texture).notTo.beNil();
  });
});

SpecEnd
