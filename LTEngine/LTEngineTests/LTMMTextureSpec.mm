// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTCVPixelBufferExtensions.h"
#import "LTFbo.h"
#import "LTFboAttachable.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+ColorizeFsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+ValueSetterFsh.h"
#import "LTTexture+Protected.h"
#import "LTTextureBasicExamples.h"

using half_float::half;

/// Uploads the given \c image to an \c LTMMTexture, draws it to an \c LTGLTexture and fetches the
/// resulting image.
static cv::Mat LTDrawFromMMTextureToGLTexture(const cv::Mat &image) {
  LTMMTexture *source = [[LTMMTexture alloc] initWithImage:image];
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                fragmentSource:[PassthroughFsh source]];
  LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:source];

  LTGLTexture *target = [[LTGLTexture alloc] initWithPropertiesOf:source];
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

  CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
  [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

  return [target image];
}

@interface LTMMTexture ()
@property (nonatomic) GLsync syncObject;
@end

SpecBegin(LTMMTexture)

static NSString * const kLTMMTextureExamples = @"LTMMTextureExamples";

sharedExamplesFor(kLTMMTextureExamples, ^(NSDictionary *contextInfo) {
  beforeEach(^{
    LTGLVersion version = (LTGLVersion)[contextInfo[@"version"] unsignedIntegerValue];
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil version:version];
    [LTGLContext setCurrentContext:context];
  });

  itShouldBehaveLike(kLTTextureBasicExamples, @{
    kLTTextureBasicExamplesTextureClass: [LTMMTexture class]
  });

  __block LTMMTexture *texture;

  beforeEach(^{
    texture = [[LTMMTexture alloc] initWithSize:CGSizeMake(2, 2)
                                    pixelFormat:$(LTGLPixelFormatRGBA8Unorm) allocateMemory:YES];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"host memory mapped texture", ^{
    __block LTFbo *fbo;
    __block LTRectDrawer *drawer;

    beforeEach(^{
      fbo = [[LTFbo alloc] initWithTexture:texture];

      LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                    fragmentSource:[ColorizeFsh source]];
      drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];
      drawer[[ColorizeFsh color]] = $(LTVector4(1.0, 0.0, 0.0, 1.0));
    });

    afterEach(^{
      fbo = nil;
      drawer = nil;
    });

    it(@"should require synchronization after draw", ^{
      CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      [[LTGLContext currentContext] executeForOpenGLES2:^{
        expect(glIsSyncAPPLE(texture.syncObject)).to.beTruthy();
      } openGLES3:^{
        expect(glIsSync(texture.syncObject)).to.beTruthy();
      }];
    });

    it(@"should map image without creating a copy", ^{
      [texture mappedImageForReading:^(const cv::Mat &, BOOL isCopy) {
        expect(isCopy).to.beFalsy();
      }];
    });

    it(@"should not require synchronization after mapping", ^{
      [texture mappedImageForReading:^(const cv::Mat &, BOOL) {
        [[LTGLContext currentContext] executeForOpenGLES2:^{
          expect(glIsSyncAPPLE(texture.syncObject)).to.beFalsy();
        } openGLES3:^{
          expect(glIsSync(texture.syncObject)).to.beFalsy();
        }];
      }];
    });

    dit(@"should read correct data after gpu draw", ^{
      cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
      CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
        expect($(mapped)).to.equalMat($(expected));
      }];
    });

    dit(@"should map correct data to core image after cpu write", ^{
      cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
      [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4b(255, 0, 0, 255));
      }];

      [texture mappedCIImage:^(CIImage *image) {
        cv::Mat4b mapped(texture.size.height, texture.size.width);

        CIContext *context = [CIContext contextWithOptions:@{
          kCIContextWorkingColorSpace: [NSNull null],
          kCIContextOutputColorSpace: [NSNull null]
        }];

        [context render:image toBitmap:mapped.data rowBytes:mapped.step[0] bounds:image.extent
                 format:kCIFormatRGBA8 colorSpace:NULL];

        expect($(mapped)).to.equalMat($(expected));
      }];
    });

    dit(@"should map correct data to core image after gpu draw", ^{
      cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
      CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      [texture mappedCIImage:^(CIImage *image) {
        cv::Mat4b mapped(texture.size.height, texture.size.width);

        CIContext *context = [CIContext contextWithOptions:@{
          kCIContextWorkingColorSpace: [NSNull null],
          kCIContextOutputColorSpace: [NSNull null]
        }];

        [context render:image toBitmap:mapped.data rowBytes:mapped.step[0] bounds:image.extent
                 format:kCIFormatRGBA8 colorSpace:NULL];

        expect($(mapped)).to.equalMat($(expected));
      }];
    });

    dit(@"should read correct data after core image draw", ^{
      cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
      [texture drawWithCoreImage:^CIImage *{
        return [CIImage imageWithColor:[CIColor colorWithRed:1 green:0 blue:0]];
      }];

      [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
        expect($(mapped)).to.equalMat($(expected));
      }];
    });
  });

  context(@"synchronization", ^{
    it(@"should not allow sampling while writing", ^{
      __block BOOL inRead = NO;

      [texture writeToAttachableWithBlock:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [texture sampleWithGPUWithBlock:^{
            inRead = YES;
          }];
        });
        expect(inRead).to.beFalsy();
      }];
      expect(inRead).will.beTruthy();
    });

    it(@"should not allow writing while reading", ^{
      __block BOOL inWrite = NO;

      [texture sampleWithGPUWithBlock:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [texture writeToAttachableWithBlock:^{
            inWrite = YES;
          }];
        });
        expect(inWrite).to.beFalsy();
      }];
      expect(inWrite).will.beTruthy();
    });
  });

  context(@"cpu gpu memory synchronization", ^{
    dit(@"should synchronize byte rgba texture", ^{
      cv::Mat4b image = cv::Mat4b(16, 16);
      image.setTo(cv::Vec4b(128));

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should synchronize byte red texture", ^{
      cv::Mat1b image(16, 16);
      image.setTo(128);

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should synchronize byte rg texture", ^{
      cv::Mat2b image(16, 16);
      image.setTo(cv::Vec2b(128, 255));

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should synchronize half-float rgba texture", ^{
      cv::Mat4hf image(16, 16);
      image.setTo(cv::Vec4hf(half(1), half(2), half(3), half(4)));

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should synchronize half-float red texture", ^{
      cv::Mat1hf image(16, 16);
      std::transform(image.begin(), image.end(), image.begin(), [](half) {
        return half(1);
      });

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should synchronize half-float rg texture", ^{
      cv::Mat2hf image(16, 16);
      image.setTo(cv::Vec2hf(half(1), half(2)));

      cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

      expect(LTCompareMat(image, actual)).to.beTruthy();
    });

    dit(@"should have fresh values on CPU after GPU rendering", ^{
      CGSize size = CGSizeMake(16, 16);
      LTMMTexture *source = [[LTMMTexture alloc] initWithSize:size
                                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                               allocateMemory:YES];
      LTMMTexture *target = [[LTMMTexture alloc] initWithSize:size
                                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                               allocateMemory:YES];
      LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                    fragmentSource:[ValueSetterFsh source]];
      LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:source];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

      CGRect rect = CGRectMake(0, 0, size.width, size.height);
      float values[] = {0, 0.25, 0.5, 0.75, 1.0};

      for (int i = 0; i < 5; ++i) {
        drawer[[ValueSetterFsh value]] = @(values[i]);
        [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

        float value = values[i];
        [target mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
          cv::Mat4b expected = cv::Mat4b(size.height, size.width);
          expected.setTo(cv::Vec4b(value * 255, value * 255, value * 255, value * 255));

          expect(LTFuzzyCompareMat(expected, mapped)).to.beTruthy();
        }];
      }
    });

    dit(@"should have fresh values on GPU after CPU rendering", ^{
      CGSize size = CGSizeMake(16, 16);
      LTMMTexture *source = [[LTMMTexture alloc] initWithSize:size
                                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                               allocateMemory:YES];
      LTGLTexture *target = [[LTGLTexture alloc] initWithSize:size
                                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                               allocateMemory:YES];

      float values[] = {0, 0.25, 0.5, 0.75, 1.0};

      for (int i = 0; i < 5; ++i) {
        __block float value = values[i];
        [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          mapped->setTo(cv::Vec4b(value, value, value, value));
        }];

        [source cloneTo:target];

        cv::Scalar scalar(value, value, value, value);
        expect(LTFuzzyCompareMatWithValue(scalar, [target image])).to.beTruthy();
      }
    });
  });

  context(@"pixel buffer", ^{
    it(@"should create texture from pixel buffer", ^{
      auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
      LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
      expect(texture).toNot.beNil();
      expect(texture.size).to.equal(CGSizeMake(1, 1));
    });

    it(@"should create texture from planes of planar pixel buffer", ^{
      auto pixelBuffer =
          LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

      LTMMTexture *plane0 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                           planeIndex:0];
      LTMMTexture *plane1 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                           planeIndex:1];
      expect(plane0).toNot.beNil();
      expect(plane0.size).to.equal(CGSizeMake(2, 2));

      expect(plane1).toNot.beNil();
      expect(plane1.size).to.equal(CGSizeMake(1, 1));
    });

    it(@"should raise when creating texture with invalid plane index", ^{
      __block auto pixelBuffer =
          LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

      expect(^{
        LTMMTexture __unused *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                              planeIndex:10];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when creating texture with plane index and non planar pixel buffer", ^{
      __block auto pixelBuffer = LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_32BGRA);

      expect(^{
        LTMMTexture __unused *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                                      planeIndex:0];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should preserve pixel buffer content", ^{
      static const cv::Vec4b kPixelValue{0, 20, 30, 40};

      auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
      LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
        image->at<cv::Vec4b>(0, 0) = kPixelValue;
      });

      LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
      LTVector4 expected = LTVector4(kPixelValue);
      LTVector4 actual = [texture pixelValue:CGPointMake(0, 0)];
      expect(actual).to.equal(expected);
    });

    dit(@"should make pixel buffer content visible to gpu", ^{
      static const cv::Vec4b kPixelValue{0, 20, 30, 40};

      auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
      LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
        image->at<cv::Vec4b>(0, 0) = kPixelValue;
      });

      // Cloning is done via GPU, thus clonned texture shows only data visible to GPU.
      LTTexture *cloned = [[[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()] clone];

      LTVector4 expected = LTVector4(kPixelValue);
      LTVector4 actual = [cloned pixelValue:CGPointMake(0, 0)];
      expect(actual).to.equal(expected);
    });

    it(@"should return pixel buffer that backs the texture", ^{
      auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
      LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
      auto returnedPixelBuffer = [texture pixelBuffer];

      CVPixelBufferRef expected = pixelBuffer.get();
      CVPixelBufferRef actual = returnedPixelBuffer.get();
      expect(expected).to.equal(actual);
    });

    it(@"should return planar pixel buffer that backs the texture", ^{
      auto pixelBuffer =
          LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

      LTMMTexture *plane0 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                          planeIndex:0];
      LTMMTexture *plane1 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                          planeIndex:1];

      __block auto pixelBufferPlane0 = [plane0 pixelBuffer];
      __block auto pixelBufferPlane1 = [plane1 pixelBuffer];

      expect(pixelBufferPlane0.get()).to.equal(pixelBuffer.get());
      expect(pixelBufferPlane1.get()).to.equal(pixelBuffer.get());
    });

    it(@"should wait for pending GPU writes before returning pixel bufer", ^{
      auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
      LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];

      [texture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];
      expect(texture.syncObject).notTo.beNil();

      auto returnedPixelBuffer = [texture pixelBuffer];
      expect(texture.syncObject).to.beNil();
    });
  });
});

itShouldBehaveLike(kLTMMTextureExamples, @{@"version": @(LTGLVersion2)});
itShouldBehaveLike(kLTMMTextureExamples, @{@"version": @(LTGLVersion3)});

SpecEnd
