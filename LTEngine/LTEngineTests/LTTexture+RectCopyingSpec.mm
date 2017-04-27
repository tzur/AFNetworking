// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTexture+RectCopying.h"

#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTexture_RectCopying)

__block LTTexture *texture;
__block LTTexture *targetTexture;
__block LTFbo *targetFBO;
__block cv::Mat4b expectedImage;

static const CGSize kTextureSize = CGSizeMake(8, 16);
static const CGSize kTargetTextureSize = CGSizeMake(32, 16);
static const int kBlockWidth = kTextureSize.width / 2;
static const int kBlockHeight = kTextureSize.height / 2;

beforeEach(^{
  cv::Mat image = cv::Mat(kTextureSize.height, kTextureSize.width, CV_8UC4);
  image(cv::Rect(0, 0, kBlockWidth, kBlockHeight)).setTo(cv::Vec4b(255, 0, 0, 255));
  image(cv::Rect(kBlockWidth, 0, kBlockWidth, kBlockHeight)).setTo(cv::Vec4b(0, 255, 0, 255));
  image(cv::Rect(0, kBlockHeight, kBlockWidth, kBlockHeight)).setTo(cv::Vec4b(0, 0, 255, 255));
  image(cv::Rect(kBlockWidth, kBlockHeight, kBlockWidth, kBlockHeight))
      .setTo(cv::Vec4b(255, 255, 0, 255));

  texture = [LTTexture textureWithImage:image];
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
  texture.minFilterInterpolation = LTTextureInterpolationNearest;
  targetTexture = [LTTexture byteRGBATextureWithSize:kTargetTextureSize];
  [targetTexture clearColor:LTVector4(0, 0, 0, 1)];
  targetFBO = [[LTFboPool currentPool] fboWithTexture:targetTexture];
  expectedImage = cv::Mat(kTargetTextureSize.height, kTargetTextureSize.width, CV_8UC4);
});

afterEach(^{
  targetFBO = nil;
  targetTexture = nil;
  texture = nil;
});

context(@"copying", ^{
  static const int kTargetBlockWidth = kTargetTextureSize.width / 2;
  static const int kTargetBlockHeight = kTargetTextureSize.height / 2;

  context(@"normalized coordinates", ^{
    static const CGRect kNormalizedRect = CGRectFromSize(CGSizeMakeUniform(0.5));
    static const CGRect kNormalizedTargetRect = CGRectMake(0.5, 0.5, 0.5, 0.5);

    it(@"should copy to a normalized rect", ^{
      [targetFBO bindAndDraw:^{
        [texture copyToNormalizedRect:kNormalizedTargetRect];
      }];

      int width = kTargetBlockWidth / 2;
      int height = kTargetBlockHeight / 2;

      expectedImage.setTo(cv::Vec4b(0, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight, width, height))
          .setTo(cv::Vec4b(255, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth + width, kTargetBlockHeight, width, height))
          .setTo(cv::Vec4b(0, 255, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight + height, width, height))
          .setTo(cv::Vec4b(0, 0, 255, 255));
      expectedImage(cv::Rect(kTargetBlockWidth + width, kTargetBlockHeight + height, width, height))
          .setTo(cv::Vec4b(255, 255, 0, 255));

      expect($(targetTexture.image)).to.equalMat($(expectedImage));
    });

    it(@"should copy a normalized rect to a normalized rect", ^{
      [targetFBO bindAndDraw:^{
        [texture copyNormalizedRect:kNormalizedRect toNormalizedRect:kNormalizedTargetRect];
      }];

      expectedImage.setTo(cv::Vec4b(0, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight, kTargetBlockWidth,
                             kTargetBlockHeight)).setTo(cv::Vec4b(255, 0, 0, 255));

      expect($(targetTexture.image)).to.equalMat($(expectedImage));
    });

    it(@"should copy a normalized rect to a normalized rect of a texture", ^{
      [texture copyNormalizedRect:kNormalizedRect toNormalizedRect:kNormalizedTargetRect
                        ofTexture:targetTexture];

      expectedImage.setTo(cv::Vec4b(0, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight, kTargetBlockWidth,
                             kTargetBlockHeight)).setTo(cv::Vec4b(255, 0, 0, 255));

      expect($(targetTexture.image)).to.equalMat($(expectedImage));
    });
  });

  context(@"unnormalized coordinates", ^{
    static const CGRect kRect = CGRectFromSize(0.5 * kTextureSize);
    static const CGRect kTargetRect =
        CGRectFromOriginAndSize(CGPointFromSize(0.5 * kTargetTextureSize),
                                0.5 * kTargetTextureSize);

    it(@"should copy to a rect of a texture", ^{
      [texture copyToRect:kTargetRect ofTexture:targetTexture];

      int width = kTargetBlockWidth / 2;
      int height = kTargetBlockHeight / 2;

      expectedImage.setTo(cv::Vec4b(0, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight, width, height))
          .setTo(cv::Vec4b(255, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth + width, kTargetBlockHeight, width, height))
          .setTo(cv::Vec4b(0, 255, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight + height, width, height))
          .setTo(cv::Vec4b(0, 0, 255, 255));
      expectedImage(cv::Rect(kTargetBlockWidth + width, kTargetBlockHeight + height, width, height))
          .setTo(cv::Vec4b(255, 255, 0, 255));

      expect($(targetTexture.image)).to.equalMat($(expectedImage));
    });

    it(@"should copy a rect to a rect of a texture", ^{
      [texture copyRect:kRect toRect:kTargetRect ofTexture:targetTexture];

      expectedImage.setTo(cv::Vec4b(0, 0, 0, 255));
      expectedImage(cv::Rect(kTargetBlockWidth, kTargetBlockHeight, kTargetBlockWidth,
                             kTargetBlockHeight)).setTo(cv::Vec4b(255, 0, 0, 255));

      expect($(targetTexture.image)).to.equalMat($(expectedImage));
    });
  });
});

SpecEnd
