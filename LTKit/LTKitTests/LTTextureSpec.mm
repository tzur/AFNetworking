// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTGLException.h"
#import "LTTestUtils.h"

// LTTexture spec is tested by the concrete class LTGLTexture.

SpecBegin(LTTexture)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

context(@"init without an image", ^{
  it(@"should create an unallocated texture with size", ^{
    CGSize size = CGSizeMake(42, 42);
    LTTexturePrecision precision = LTTexturePrecisionByte;
    LTTextureChannels channels = LTTextureChannelsRGBA;

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:size precision:precision
                                                  channels:channels allocateMemory:NO];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(precision);
    expect(texture.channels).to.equal(channels);
  });

  it(@"should have default property values", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:NO];

    expect(texture.usingAlphaChannel).to.equal(NO);
    expect(texture.usingHighPrecisionByte).to.equal(NO);
    expect(texture.wrap).to.equal(LTTextureWrapClamp);
    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationLinear);
  });
});

context(@"init with an image", ^{
  it(@"should load RGBA image", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_8UC4);

    LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(LTTexturePrecisionByte);
    expect(texture.channels).to.equal(LTTextureChannelsRGBA);
  });

  it(@"should load float intensity image", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_32F);

    LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(LTTexturePrecisionFloat);
    expect(texture.channels).to.equal(LTTextureChannelsLuminance);
  });

  it(@"should load half-float RGBA image", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_16UC4);

    LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(LTTexturePrecisionHalfFloat);
    expect(texture.channels).to.equal(LTTextureChannelsRGBA);
  });

  it(@"should not load invalid image depth", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_64FC4);

    expect(^{
      __unused LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];
    }).to.raise(kLTTextureUnsupportedFormatException);
  });

  it(@"should not load invalid image channel count", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_32FC3);

    expect(^{
      __unused LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];
    }).to.raise(kLTTextureUnsupportedFormatException);
  });
});

context(@"properties", ^{
  it(@"will not set wrap to repeat on NPOT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 3)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).toNot.equal(LTTextureWrapRepeat);
  });

  it(@"will set the warp to repeat on POT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).to.equal(LTTextureWrapRepeat);
  });

  it(@"will set min and mag filters", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationNearest);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationNearest);
  });
});

context(@"binding and unbinding", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1) precision:LTTexturePrecisionByte
                                       channels:LTTextureChannelsRGBA allocateMemory:NO];
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should bind to texture", ^{
    [texture bind];

    GLint currentTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);

    expect(currentTexture).to.equal(texture.name);
  });

  it(@"should cause no effect on second bind", ^{
    [texture bind];
    [texture bind];

    GLint currentTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);

    expect(currentTexture).to.equal(texture.name);
  });

  it(@"should unbind from texture", ^{
    [texture bind];
    [texture unbind];

    GLint currentTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);

    expect(currentTexture).to.equal(0);
  });

  it(@"should cause no effect on second unbind", ^{
    [texture bind];
    [texture unbind];
    [texture unbind];

    GLint currentTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);

    expect(currentTexture).to.equal(0);
  });

  it(@"should bind and unbind", ^{
    __block GLint currentTexture;

    [texture bindAndExecute:^{
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(texture.name);
    }];

    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
    expect(currentTexture).to.equal(0);
  });

  it(@"should bind and unbind from the same texture unit", ^{
    glActiveTexture(GL_TEXTURE0);
    [texture bind];
    glActiveTexture(GL_TEXTURE1);
    [texture unbind];

    glActiveTexture(GL_TEXTURE0);
    GLint currentTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
    expect(currentTexture).to.equal(0);
  });
});

context(@"loading data from texture", ^{
  __block LTTexture *texture;
  __block cv::Mat image;

  beforeEach(^{
    image.create(48, 67, CV_8UC4);
    for (int y = 0; y < image.rows; ++y) {
      for (int x = 0; x < image.cols; ++x) {
        image.at<cv::Vec4b>(y, x) = cv::Vec4b(x, y, 0, 255);
      }
    }

    texture = [[LTGLTexture alloc] initWithImage:image];
  });

  afterEach(^{
    texture = nil;
  });

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
  pending(@"should clone itself to a new texture");

  pending(@"should clone itself to an existing texture");
});

SpecEnd
