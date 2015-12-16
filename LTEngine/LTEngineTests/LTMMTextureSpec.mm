// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+ColorizeFsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+ValueSetterFsh.h"
#import "LTTextureBasicExamples.h"

using half_float::half;

/// Uploads the given \c image to an \c LTMMTexture, draws it to an \c LTGLTexture and fetches the
/// resulting image.
cv::Mat LTDrawFromMMTextureToGLTexture(const cv::Mat &image) {
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
    texture = [[LTMMTexture alloc] initByteRGBAWithSize:CGSizeMake(2, 2)];
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
      CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
        expect(LTCompareMatWithValue(cv::Scalar(255, 0, 0, 255), mapped)).to.beTruthy();
      }];
    });
  });

  context(@"synchronization", ^{
    it(@"should not allow reading while writing", ^{
      __block BOOL inRead = NO;

      [texture writeToTexture:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [texture readFromTexture:^{
            inRead = YES;
          }];
        });
        expect(inRead).to.beFalsy();
      }];
      expect(inRead).will.beTruthy();
    });

    it(@"should not allow writing while reading", ^{
      __block BOOL inWrite = NO;

      [texture readFromTexture:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [texture writeToTexture:^{
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
      LTMMTexture *source = [[LTMMTexture alloc] initByteRGBAWithSize:size];
      LTMMTexture *target = [[LTMMTexture alloc] initByteRGBAWithSize:size];
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
      LTMMTexture *source = [[LTMMTexture alloc] initByteRGBAWithSize:size];
      LTGLTexture *target = [[LTGLTexture alloc] initByteRGBAWithSize:size];

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
});

itShouldBehaveLike(kLTMMTextureExamples, @{@"version": @(LTGLVersion2)});
itShouldBehaveLike(kLTMMTextureExamples, @{@"version": @(LTGLVersion3)});

SpecEnd
