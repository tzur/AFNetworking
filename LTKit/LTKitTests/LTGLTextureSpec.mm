// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTFbo.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTextureExamples.h"

SpecGLBegin(LTGLTexture)

itShouldBehaveLike(kLTTextureExamples, @{kLTTextureExamplesTextureClass: [LTGLTexture class]});

context(@"mipmapping", ^{
  context(@"construction from a single image", ^{
    it(@"should initialize with a single image", ^{
      cv::Mat4b image(128, 64);
      image.setTo(cv::Vec4b(255, 255, 255, 255));

      expect(^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
      }).toNot.raiseAny();
    });

    it(@"should not initialize with a non-power-of-two single image", ^{
      cv::Mat4b image(127, 64);
      image.setTo(cv::Vec4b(255, 255, 255, 255));

      expect(^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
      }).to.raise(NSInvalidArgumentException);
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
    
    it(@"should not initialize with a non-power-of-two image", ^{
      cv::Mat4b image(127, 64);
      image.setTo(cv::Vec4b(255, 255, 255, 255));

      expect((^{
        __unused LTGLTexture *texture = [[LTGLTexture alloc] initWithMipmapImages:{image}];
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
  });

  context(@"drawing", ^{
    __block LTGLTexture *texture;
    __block LTGLTexture *target;
    __block LTProgram *program;
    __block LTRectDrawer *drawer;
    __block LTFbo *fbo;

    beforeEach(^{
      cv::Mat4b imageA(64, 64);
      imageA.setTo(cv::Vec4b(255, 0, 0, 255));

      cv::Mat4b imageB(32, 32);
      imageB.setTo(cv::Vec4b(0, 255, 0, 255));

      cv::Mat4b imageC(16, 16);
      imageC.setTo(cv::Vec4b(0, 0, 255, 255));

      cv::Mat4b imageD(8, 8);
      imageD.setTo(cv::Vec4b(255, 255, 255, 255));

      texture = [[LTGLTexture alloc] initWithMipmapImages:{imageA, imageB, imageC, imageD}];

      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:[PassthroughFsh source]];
      drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];
      target = [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(64, 64)];
      fbo = [[LTFbo alloc] initWithTexture:target];
    });

    afterEach(^{
      texture = nil;
      target = nil;
      program = nil;
      drawer = nil;
      fbo = nil;
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

SpecGLEnd
