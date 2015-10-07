// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

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

static NSString * const kLTGLTextureExamples = @"LTGLTextureExamples";

sharedExamplesFor(kLTGLTextureExamples, ^(NSDictionary *contextInfo) {
  beforeEach(^{
    LTGLContextAPIVersion version = (LTGLContextAPIVersion)[contextInfo[@"version"]
                                                            unsignedIntegerValue];
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil version:version];
    [LTGLContext setCurrentContext:context];
  });

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

      it(@"should initialize with properties of other texture", ^{
        LTGLTexture *texture = [[LTGLTexture alloc]
                                initWithMipmapImages:{cv::Mat4b(128, 64), cv::Mat4b(64, 32)}];
        LTGLTexture *other = [[LTGLTexture alloc] initWithPropertiesOf:texture];
        expect(other.size).to.equal(texture.size);
        expect(other.precision).to.equal(texture.precision);
        expect(other.format).to.equal(texture.format);
        expect(other.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
        expect(^{
          [other clearWithColor:LTVector4Zero];
        }).notTo.raiseAny();
      });

      it(@"should initialize with properties", ^{
        LTGLTexture *texture = [[LTGLTexture alloc]
                                initWithSize:CGSizeMake(64, 128) precision:LTTexturePrecisionByte
                                format:LTTextureFormatRGBA maxMipmapLevel:3];

        expect(texture.size).to.equal(CGSizeMake(64, 128));
        expect(texture.precision).to.equal(LTTexturePrecisionByte);
        expect(texture.format).to.equal(LTTextureFormatRGBA);
        expect(texture.maxMipmapLevel).to.equal(3);
        expect(^{
          [texture clearWithColor:LTVector4Zero];
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

      it(@"should return image at level", ^{
        expect($([texture imageAtLevel:0])).to.equalMat($(imageA));
        expect($([texture imageAtLevel:1])).to.equalMat($(imageB));
        expect($([texture imageAtLevel:2])).to.equalMat($(imageC));
        expect($([texture imageAtLevel:3])).to.equalMat($(imageD));
      });

      it(@"should clear all levels with color", ^{
        [texture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];
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
        [cloned clearWithColor:LTVector4Zero];
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
});

itShouldBehaveLike(kLTGLTextureExamples, @{@"version": @(LTGLContextAPIVersion2)});
itShouldBehaveLike(kLTGLTextureExamples, @{@"version": @(LTGLContextAPIVersion3)});

SpecEnd
