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

NSString * const kLTTexturePrecisionAndFormatExamples = @"LTTexturePrecisionAndFormatExamples";

SharedExamplesBegin(LTTextureExamples)

sharedExamplesFor(kLTTextureExamples, ^(NSDictionary *data) {
  __block Class textureClass;

  beforeAll(^{
    textureClass = data[kLTTextureExamplesTextureClass];
  });

  sharedExamplesFor(kLTTexturePrecisionAndFormatExamples, ^(NSDictionary *data) {
    __block LTTexturePrecision precision;
    __block LTTextureFormat format;
    __block int matType;
    __block cv::Mat image;

    beforeAll(^{
      precision = (LTTexturePrecision)[data[@"precision"] unsignedIntValue];
      format = (LTTextureFormat)[data[@"format"] unsignedIntValue];
      matType = LTMatTypeForPrecisionAndFormat(precision, format);
    });

    it(@"should create texture", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                                 precision:precision
                                                                    format:format
                                                            allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.format).to.equal(format);
    });

    it(@"should load image from mat", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, matType);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.channels).to.equal(image.channels());
    });
  });

  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRGBA)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatLuminance)});

  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRGBA)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatLuminance)});

  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRGBA)});
  itShouldBehaveLike(kLTTexturePrecisionAndFormatExamples,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatLuminance)});

  context(@"red and rg textures", ^{
    it(@"should read 4-byte aligned red channel data", ^{
      cv::Mat1b image(16, 16);
      image.setTo(128);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      cv::Mat read = [texture image];

      expect(read.type()).to.equal(CV_8U);
      expect(LTCompareMat(image, read)).to.beTruthy();
    });

    it(@"should read 4-byte aligned rg channel data", ^{
      cv::Mat2b image(16, 16);
      image.setTo(cv::Vec2b(128, 64));

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      cv::Mat read = [texture image];

      expect(read.type()).to.equal(CV_8UC2);
      expect(LTCompareMat(image, read)).to.beTruthy();
    });

    it(@"should read non-4-byte aligned red channel data", ^{
      cv::Mat1b image(10, 10);
      image(cv::Rect(0, 0, 5, 10)).setTo(128);
      image(cv::Rect(5, 0, 5, 10)).setTo(64);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      cv::Mat read = [texture image];

      expect(read.type()).to.equal(CV_8U);
      expect(LTCompareMat(image, read)).to.beTruthy();
    });
  });

  context(@"init without an image", ^{
    it(@"should create an unallocated texture with size", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexturePrecision precision = LTTexturePrecisionByte;
      LTTextureFormat format = LTTextureFormatRGBA;

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                                 precision:precision
                                                                    format:format
                                                            allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.precision).to.equal(precision);
      expect(texture.format).to.equal(format);
    });

    it(@"should create a texture with similar properties", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initByteRGBAWithSize:size];
      LTTexture *similar = [(LTTexture *)[textureClass alloc] initWithPropertiesOf:texture];

      expect(similar.size).to.equal(texture.size);
      expect(similar.precision).to.equal(texture.precision);
      expect(similar.channels).to.equal(texture.channels);
    });

    it(@"should not initialize with zero sized texture", ^{
      expect(^{
        LTTexture __unused *texture = [(LTTexture *)[textureClass alloc]
                                       initWithSize:CGSizeZero
                                       precision:LTTexturePrecisionByte
                                       format:LTTextureFormatRGBA
                                       allocateMemory:YES];
      }).to.raise(NSInvalidArgumentException);
    });

    context(@"default values", ^{
      __block LTTexture *texture;

      beforeEach(^{
        texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMake(1, 1)
                                                        precision:LTTexturePrecisionByte
                                                           format:LTTextureFormatRGBA
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

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTCVVec4bToLTVector4(image(point.y, point.x));

        expect(expected).to.equal(actual);
      });

      it(@"should return correct pixel values", ^{
        CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected;
        for (const CGPoint &point : points) {
          expected.push_back(LTCVVec4bToLTVector4(image(point.y, point.x)));
        }

        expect(expected == actual).to.equal(YES);
      });
    });

    context(@"cloning", ^{
      dit(@"should clone itself to a new texture", ^{
        LTTexture *cloned = [texture clone];

        expect(cloned.name).toNot.equal(texture.name);
        expect($([cloned image])).to.equalMat($(image));
      });

      dit(@"should clone itself to an existing texture", ^{
        LTTexture *cloned = [(LTTexture *)[textureClass alloc] initWithPropertiesOf:texture];
        
        [texture cloneTo:cloned];
        
        expect($([cloned image])).to.equalMat($(image));
      });

      it(@"should not clone to a texture with a different size", ^{
        CGSize size = CGSizeMake(texture.size.width - 1, texture.size.height - 1);
        LTTexture *cloned = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                                  precision:texture.precision
                                                                     format:texture.format
                                                             allocateMemory:YES];

        expect(^{
          [texture cloneTo:cloned];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"clearing texture", ^{
      dit(@"should clear texture with color", ^{
        LTVector4 color = LTVector4(1.0, 0.0, 0.0, 1.0);
        [texture clearWithColor:color];

        cv::Scalar expected(color.r() * 255, color.g() * 255, color.b() * 255, color.a() * 255);
        expect($([texture image])).to.equalScalar($(expected));
      });
    });

    context(@"memory mapping texture", ^{
      it(@"should map correct texture data", ^{
        [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
          expect(LTCompareMat(image, mapped)).to.beTruthy();
        }];
      });

      it(@"should reflect changes on texture", ^{
        cv::Scalar value(0, 0, 255, 255);
        [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          mapped->setTo(value);
        }];
        expect(LTCompareMatWithValue(value, [texture image])).to.beTruthy();
      });
    });

    context(@"drawing with coregraphics", ^{
      it(@"should draw with coregraphics to red channel texture", ^{
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMake(67, 48)
                                                                   precision:LTTexturePrecisionByte
                                                                      format:LTTextureFormatRed
                                                              allocateMemory:YES];

        [texture drawWithCoreGraphics:^(CGContextRef context) {
          UIGraphicsPushContext(context); {
            [[UIColor blackColor] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, texture.size));
            [[UIColor whiteColor] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, CGSizeMake(4, 4)));
          } UIGraphicsPopContext();
        }];

        cv::Mat1b expected(image.size(), 0);
        expected(cv::Rect(0, 0, 4, 4)).setTo(255);
        expect($([texture image])).to.equalMat($(expected));
      });

      it(@"should draw with coregraphics to 4 channel texture", ^{
        [texture drawWithCoreGraphics:^(CGContextRef context) {
          UIGraphicsPushContext(context); {
            [[UIColor blackColor] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, texture.size));
            [[UIColor redColor] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, CGSizeMake(4, 4)));
          } UIGraphicsPopContext();
        }];

        cv::Mat4b expected(image.size(), cv::Vec4b(0, 0, 0, 255));
        expected(cv::Rect(0, 0, 4, 4)).setTo(cv::Vec4b(255, 0, 0, 255));
        expect($([texture image])).to.equalMat($(expected));
      });
    });

    context(@"generation ID", ^{
      it(@"should produce different generation ID after writing via OpenGL", ^{
        NSUInteger generationID = texture.generationID;
        [texture clearWithColor:LTVector4Zero];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not produce different generation ID after reading via OpenGL", ^{
        NSUInteger generationID = texture.generationID;
        cv::Mat image(texture.image);
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should produce different generation ID after writing via mapping", ^{
        NSUInteger generationID = texture.generationID;
        [texture mappedImageForWriting:^(cv::Mat *, BOOL) {
        }];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not produce different generation ID after reading via mapping", ^{
        NSUInteger generationID = texture.generationID;
        [texture mappedImageForReading:^(const cv::Mat &, BOOL) {
        }];
        expect(texture.generationID).to.equal(generationID);
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
