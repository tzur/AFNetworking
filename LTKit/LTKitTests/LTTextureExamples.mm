// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureExamples.h"

#import "LTGLKitExtensions.h"
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

  sharedExamplesFor(@"LTTexture precision and channels", ^(NSDictionary *data) {
    __block LTTexturePrecision precision;
    __block LTTextureChannels channels;
    __block int matType;
    __block cv::Mat image;

    beforeAll(^{
      precision = (LTTexturePrecision)[data[@"precision"] unsignedIntValue];
      channels = (LTTextureChannels)[data[@"channels"] unsignedIntValue];
      NSUInteger numChannels = LTNumberOfChannelsForChannels(channels);

      switch (precision) {
        case LTTexturePrecisionByte:
          matType = (int)CV_MAKETYPE(CV_8U, numChannels);
          break;
        case LTTexturePrecisionHalfFloat:
          matType = (int)CV_MAKETYPE(CV_16U, numChannels);
          break;
        case LTTexturePrecisionFloat:
          matType = (int)CV_MAKETYPE(CV_32F, numChannels);
          break;
      }
    });

    it(@"should create texture", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                                 precision:precision
                                                                  channels:channels
                                                            allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.channels).to.equal(channels);
    });

    it(@"should load image from mat", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, matType);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.channels).to.equal(channels);
    });
  });

  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"channels": @(LTTextureChannelsR)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"channels": @(LTTextureChannelsRG)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"channels": @(LTTextureChannelsRGBA)});

  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"channels": @(LTTextureChannelsR)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"channels": @(LTTextureChannelsRG)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"channels": @(LTTextureChannelsRGBA)});

  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"channels": @(LTTextureChannelsR)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"channels": @(LTTextureChannelsRG)});
  itShouldBehaveLike(@"LTTexture precision and channels",
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"channels": @(LTTextureChannelsRGBA)});

  context(@"red and rg textures", ^{
    it(@"should read red channel data", ^{
      cv::Mat1b image(16, 16);
      image.setTo(128);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      cv::Mat read = [texture image];

      std::vector<cv::Mat> channels;
      cv::split(read, channels);

      expect(CV_MAT_DEPTH(read.type())).to.equal(CV_8U);
      expect(LTCompareMat(image, channels[0])).to.beTruthy();
    });

    it(@"should read rg channel data", ^{
      cv::Mat2b image(16, 16);
      image.setTo(cv::Vec2b(128, 64));

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      cv::Mat read = [texture image];

      std::vector<cv::Mat> channels;
      cv::split(read, channels);

      cv::Mat joined;
      cv::merge(&channels[0], 2, joined);

      expect(CV_MAT_DEPTH(read.type())).to.equal(CV_8U);
      expect(LTCompareMat(image, joined)).to.beTruthy();
    });
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

    it(@"should create a texture with similar properties", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initByteRGBAWithSize:size];
      LTTexture *similar = [(LTTexture *)[textureClass alloc] initWithPropertiesOf:texture];

      expect(similar.size).to.equal(texture.size);
      expect(similar.precision).to.equal(texture.precision);
      expect(similar.channels).to.equal(texture.channels);
    });

    context(@"default values", ^{
      __block LTTexture *texture;

      beforeEach(^{
        texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMake(1, 1)
                                                        precision:LTTexturePrecisionByte
                                                         channels:LTTextureChannelsRGBA
                                                   allocateMemory:NO];
      });

      afterEach(^{
        texture = nil;
      });

      itShouldBehaveLike(kLTTextureDefaultValuesExamples, ^{
        return @{kLTTextureDefaultValuesExamplesTexture:
                   [NSValue valueWithNonretainedObject:texture]};
      });
    });
  });

  context(@"init with an image", ^{
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
    __block cv::Mat4b image;

    beforeEach(^{
      image.create(48, 67);
      for (int y = 0; y < image.rows; ++y) {
        for (int x = 0; x < image.cols; ++x) {
          image(y, x) = cv::Vec4b(x, y, 0, 255);
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
        GLKVector4 expected = LTCVVec4bToGLKVector4(image(point.y, point.x));

        expect(expected).to.equal(actual);
      });

      it(@"should return correct pixel values", ^{
        CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

        GLKVector4s actual = [texture pixelValues:points];
        GLKVector4s expected;
        for (const CGPoint &point : points) {
          expected.push_back(LTCVVec4bToGLKVector4(image(point.y, point.x)));
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

    context(@"memory mapping texture", ^{
      it(@"should map correct texture data", ^{
        [texture mappedImage:^(cv::Mat mapped, BOOL) {
          expect(LTCompareMat(image, mapped)).to.beTruthy();
        }];
      });

      it(@"should reflect changes on texture", ^{
        cv::Scalar value(0, 0, 255, 255);
        [texture mappedImage:^(cv::Mat mapped, BOOL) {
          mapped.setTo(value);
        }];
        expect(LTCompareMatWithValue(value, [texture image])).to.beTruthy();
      });
    });
  });
});

sharedExamplesFor(kLTTextureDefaultValuesExamples, ^(NSDictionary *data) {
  __block LTTexture *texture;

  beforeEach(^{
    texture = [data[kLTTextureDefaultValuesExamplesTexture] nonretainedObjectValue];
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should have default model property values", ^{
    expect(texture.usingAlphaChannel).to.equal(NO);
    expect(texture.usingHighPrecisionByte).to.equal(NO);
    expect(texture.wrap).to.equal(LTTextureWrapClamp);
    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(texture.maxMipmapLevel).to.equal(0);
  });

  it(@"should have default opengl property values", ^{
    __block GLint textureWrapS, textureWrapT;
    __block GLint minFilterInterpolation, magFilterInterpolation;
    __block GLint maxMipmapLevels;

    [texture bindAndExecute:^{
      glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, &textureWrapS);
      glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, &textureWrapT);

      glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, &minFilterInterpolation);
      glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, &magFilterInterpolation);

      glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL_APPLE, &maxMipmapLevels);
    }];

    expect(textureWrapS).to.equal(texture.wrap);
    expect(textureWrapT).to.equal(texture.wrap);

    expect(minFilterInterpolation).to.equal(texture.minFilterInterpolation);
    expect(magFilterInterpolation).to.equal(texture.magFilterInterpolation);

    expect(maxMipmapLevels).to.equal(texture.maxMipmapLevel);
  });
});

SharedExamplesEnd
