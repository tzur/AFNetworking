// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureExamples.h"

#import "LTTestUtils.h"
#import "LTTexture.h"

NSString * const kLTTextureExamples = @"LTTextureExamples";
NSString * const kLTTextureExamplesTextureClass = @"LTTextureExamplesTextureClass";

NSString * const kLTTextureDefaultValuesExamples = @"LTTextureDefaultValuesExamples";
NSString * const kLTTextureDefaultValuesExamplesTexture = @"LTTextureDefaultValuesExamplesTexture";

SharedExamplesBegin(LTTextureExamples)

sharedExamplesFor(kLTTextureExamples, ^(NSDictionary *data) {
  __block Class textureClass;

  beforeAll(^{
    textureClass = data[kLTTextureExamplesTextureClass];
  });

  context(@"init without an image", ^{
    it(@"should create an unallocated texture with size", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexturePrecision precision = LTTexturePrecisionByte;
      LTTextureChannels channels = LTTextureChannelsRGBA;

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                                 precision:precision
                                                                  channels:channels
                                                            allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.channels).to.equal(channels);
    });

    itShouldBehaveLike(kLTTextureDefaultValuesExamples, ^{
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMake(1, 1)
                                                                 precision:LTTexturePrecisionByte
                                                                  channels:LTTextureChannelsRGBA
                                                            allocateMemory:NO];
      return @{kLTTextureDefaultValuesExamplesTexture: texture};
    });
  });

  context(@"init with an image", ^{
    it(@"should load RGBA image", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, CV_8UC4);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(LTTexturePrecisionByte);
      expect(texture.channels).to.equal(LTTextureChannelsRGBA);
    });

    it(@"should load half-float RGBA image", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, CV_16UC4);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(LTTexturePrecisionHalfFloat);
      expect(texture.channels).to.equal(LTTextureChannelsRGBA);
    });

    it(@"should not load invalid image depth", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, CV_64FC4);

      expect(^{
        __unused LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      }).to.raise(kLTTextureUnsupportedFormatException);
    });

    it(@"should not load invalid image channel count", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, CV_32FC3);

      expect(^{
        __unused LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      }).to.raise(kLTTextureUnsupportedFormatException);
    });
  });

  context(@"texture with data", ^{
    __block LTTexture *texture;
    __block cv::Mat image;

    beforeEach(^{
      image.create(48, 67, CV_8UC4);
      for (int y = 0; y < image.rows; ++y) {
        for (int x = 0; x < image.cols; ++x) {
          image.at<cv::Vec4b>(y, x) = cv::Vec4b(x, y, 0, 255);
        }
      }

      texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
    });

    afterEach(^{
      texture = nil;
    });

    context(@"loading data from texture", ^{
      it(@"should read entire texture to image", ^{
        cv::Mat read = [texture image];

        expect(LTCompareMat(image, read)).to.beTruthy();
      });

      it(@"should read part of texture to image", ^{
        CGRect rect = CGRectMake(2, 2, 10, 15);

        cv::Mat read = [texture imageWithRect:rect];

        expect(read.cols).to.equal(rect.size.width);
        expect(read.rows).to.equal(rect.size.height);
        expect(LTCompareMat(image(LTCVRectWithCGRect(rect)), read)).to.beTruthy();
      });

      it(@"should return a correct pixel value", ^{
        CGPoint point = CGPointMake(1, 7);

        GLKVector4 actual = [texture pixelValue:point];
        GLKVector4 expected = LTCVVec4bToGLKVector4(image.at<cv::Vec4b>(point.y, point.x));

        expect(expected).to.equal(actual);
      });

      it(@"should return correct pixel values", ^{
        CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

        GLKVector4s actual = [texture pixelValues:points];
        GLKVector4s expected;
        for (const CGPoint &point : points) {
          expected.push_back(LTCVVec4bToGLKVector4(image.at<cv::Vec4b>(point.y, point.x)));
        }

        expect(expected == actual).to.equal(YES);
      });
    });

    context(@"cloning", ^{
      it(@"should clone itself to a new texture", ^{
        LTTexture *cloned = [texture clone];

        expect(cloned.name).toNot.equal(texture.name);

        cv::Mat read = [cloned image];
        expect(LTCompareMat(image, read)).to.beTruthy();
      });

      it(@"should clone itself to an existing texture", ^{
        LTTexture *cloned = [(LTTexture *)[textureClass alloc] initWithSize:texture.size
                                                                  precision:texture.precision
                                                                   channels:texture.channels
                                                             allocateMemory:YES];
        
        [texture cloneTo:cloned];
        
        cv::Mat read = [cloned image];
        expect(LTCompareMat(image, read)).to.beTruthy();
      });
    });
  });
});

sharedExamplesFor(kLTTextureDefaultValuesExamples, ^(NSDictionary *data) {
  it(@"should have default property values", ^{
    LTTexture *texture = data[kLTTextureDefaultValuesExamplesTexture];

    expect(texture.usingAlphaChannel).to.equal(NO);
    expect(texture.usingHighPrecisionByte).to.equal(NO);
    expect(texture.wrap).to.equal(LTTextureWrapClamp);
    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationLinear);
  });
});

SharedExamplesEnd
