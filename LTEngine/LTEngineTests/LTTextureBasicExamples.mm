// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureBasicExamples.h"

#import "LTGLKitExtensions.h"
#import "LTTexture+Protected.h"

NSString * const kLTTextureBasicExamples = @"LTTextureBasicExamples";
NSString * const kLTTextureBasicExamplesTextureClass = @"TextureClass";

NSString * const kLTTextureDefaultValuesExamples = @"LTTextureDefaultValuesExamples";
NSString * const kLTTextureDefaultValuesTexture = @"Texture";

NSString * const kLTTextureBasicExamplesPrecisionAndFormat = @"PrecisionAndFormat";

SharedExamplesBegin(LTTextureExamples)

sharedExamplesFor(kLTTextureBasicExamples, ^(NSDictionary *data) {
  __block Class textureClass;

  beforeAll(^{
    textureClass = data[kLTTextureBasicExamplesTextureClass];
  });

  sharedExamplesFor(kLTTextureBasicExamplesPrecisionAndFormat, ^(NSDictionary *data) {
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

  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionByte),
                       @"format": @(LTTextureFormatRGBA)});

  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionHalfFloat),
                       @"format": @(LTTextureFormatRGBA)});

  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRed)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRG)});
  itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                     @{@"precision": @(LTTexturePrecisionFloat),
                       @"format": @(LTTextureFormatRGBA)});

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
        return @{kLTTextureDefaultValuesTexture:
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

      it(@"should return a correct pixel value inside texture", ^{
        CGPoint point = CGPointMake(1, 7);

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTCVVec4bToLTVector4(image(point.y, point.x));

        expect(expected).to.equal(actual);
      });

      it(@"should return a correct pixel value outside texture", ^{
        CGPoint point = CGPointMake(-1, 49);

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTCVVec4bToLTVector4(image(47, 1));

        expect(expected).to.equal(actual);
      });

      it(@"should return a correct pixel value on the boundary", ^{
        CGPoint point = CGPointMake(67, 48);

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTCVVec4bToLTVector4(image(47, 66));

        expect(expected).to.equal(actual);
      }); 

      it(@"should return correct pixel values inside texture", ^{
        CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected;
        for (const CGPoint &point : points) {
          expected.push_back(LTCVVec4bToLTVector4(image(point.y, point.x)));
        }

        expect(expected == actual).to.beTruthy();
      });

      it(@"should return correct pixel values outside texture", ^{
        CGPoints points{CGPointMake(-1, 2), CGPointMake(2, -5), CGPointMake(-1, 49)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected{
          LTCVVec4bToLTVector4(image(2, 1)),
          LTCVVec4bToLTVector4(image(5, 2)),
          LTCVVec4bToLTVector4(image(47, 1))
        };

        expect(expected == actual).to.beTruthy();
      });

      it(@"should return a correct pixel value on the boundary", ^{
        CGPoints points{CGPointMake(0, 0), CGPointMake(67, 48)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected{
          LTCVVec4bToLTVector4(image(0, 0)),
          LTCVVec4bToLTVector4(image(47, 66))
        };

        expect(expected == actual).to.beTruthy();
      });
    });

    context(@"cloning", ^{
      dit(@"should clone itself to a new texture", ^{
        LTTexture *cloned = [texture clone];

        expect(cloned.name).toNot.equal(texture.name);
        expect($([cloned image])).to.equalMat($(image));
        expect(cloned.generationID).to.equal(texture.generationID);
      });

      dit(@"should clone itself to an existing texture", ^{
        LTTexture *cloned = [(LTTexture *)[textureClass alloc] initWithPropertiesOf:texture];
        
        [texture cloneTo:cloned];
        
        expect($([cloned image])).to.equalMat($(image));
        expect(cloned.generationID).to.equal(texture.generationID);
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

    context(@"fill color", ^{
      __block LTTexture *texture;

      beforeEach(^{
        texture = [(LTTexture *)[textureClass alloc] initWithImage:cv::Mat4b(16, 16)];
      });

      afterEach(^{
        texture = nil;
      });

      it(@"should have initial fill color of null", ^{
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set fill color on clearWithColor", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor).to.equal(LTVector4::ones());
        [texture clearWithColor:LTVector4::zeros()];;
        expect(texture.fillColor).to.equal(LTVector4::zeros());
      });

      it(@"should set fill color to null on load", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture load:cv::Mat4b(16, 16)];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set fill color to null on loadRect:fromImage", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture loadRect:CGRectMake(0, 0, 8, 8) fromImage:cv::Mat4b(8, 8)];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set fill color to null on mappedForWriting", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          expect(mapped->rows).to.equal(texture.size.height);
          expect(mapped->cols).to.equal(texture.size.width);
        }];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should not set fill color to null on mappedForReading", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
          expect(mapped.rows).to.equal(texture.size.height);
          expect(mapped.cols).to.equal(texture.size.width);
        }];
        expect(texture.fillColor.isNull()).to.beFalsy();
      });

      it(@"should have initial fill color of null when initializing with properties of texture", ^{
        [texture clearWithColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        LTTexture *other = [[[texture class] alloc] initWithPropertiesOf:texture];
        expect(other.fillColor.isNull()).to.beTruthy();
      });

      it(@"should use clearWithColor when cloning a texture with fill color", ^{
        [texture clearWithColor:LTVector4::ones()];
        LTTexture *other = [[[texture class] alloc] initWithPropertiesOf:texture];
        id mock = OCMPartialMock(other);
        [texture cloneTo:other];
        OCMVerify([mock clearWithColor:LTVector4::ones()]);
        expect(other.fillColor).to.equal(texture.fillColor);
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

    context(@"reading contents as CGImageRef", ^{
      it(@"should generate CGImageRef for a red channel texture", ^{
        cv::Mat1b expected(48, 67, 128);
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:expected];

        __block BOOL mapped = NO;
        [texture mappedCGImage:^(CGImageRef imageRef, BOOL) {
          mapped = YES;

          CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
          CFDataRef data = CGDataProviderCopyData(provider);

          cv::Mat image((int)CGImageGetHeight(imageRef), (int)CGImageGetWidth(imageRef),
                        CV_8U, (void *)CFDataGetBytePtr(data), CGImageGetBytesPerRow(imageRef));

          expect($(image)).to.beCloseToMat($(expected));

          if (data) {
            CFRelease(data);
          }
        }];

        expect(mapped).to.beTruthy();
      });
    });

    context(@"generation ID", ^{
      __block id generationID;

      beforeEach(^{
        generationID = texture.generationID;
      });

      afterEach(^{
        generationID = nil;
      });

      it(@"should change generation ID after writing via writeToTexture", ^{
        [texture writeToTexture:^{
        }];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should change generation ID after writing via begin/end writeToTexture", ^{
        [texture beginWriteToTexture];
        [texture endWriteToTexture];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not change generation ID after reading via readFromTexture", ^{
        [texture readFromTexture:^{
        }];
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should not change generation ID after reading via begin/end readFromTexture", ^{
        [texture beginReadFromTexture];
        [texture endReadFromTexture];
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should not change generation ID after reading via OpenGL", ^{
        cv::Mat image(texture.image);
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should change generation ID after writing via mapping", ^{
        [texture mappedImageForWriting:^(cv::Mat *, BOOL) {
        }];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not change generation ID after reading via mapping", ^{
        [texture mappedImageForReading:^(const cv::Mat &, BOOL) {
        }];
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should change generation ID after load", ^{
        cv::Mat mat(texture.size.height, texture.size.width, texture.matType);
        [texture load:mat];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should change generation ID after loadRect", ^{
        cv::Mat mat(1, 1, texture.matType);
        [texture loadRect:CGRectFromSize(CGSizeMakeUniform(1)) fromImage:mat];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not change generation ID after storeRect", ^{
        cv::Mat mat(1, 1, texture.matType);
        [texture storeRect:CGRectFromSize(CGSizeMakeUniform(1)) toImage:&mat];
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should change generation ID after clearWithColor", ^{
        [texture clearWithColor:LTVector4::zeros()];
        expect(texture.generationID).notTo.equal(generationID);
      });

      it(@"should change generation ID after drawing with core graphics", ^{
        [texture drawWithCoreGraphics:^(CGContextRef __unused context) {
        }];
        expect(texture.generationID).notTo.equal(generationID);
      });

      it(@"should not change generation ID after reading via mappedCGImage", ^{
        [texture mappedCGImage:^(CGImageRef, BOOL) {
        }];
        expect(texture.generationID).to.equal(generationID);
      });
    });
  });
});

sharedExamplesFor(kLTTextureDefaultValuesExamples, ^(NSDictionary *data) {
  __block LTTexture *texture;

  beforeEach(^{
    texture = [data[kLTTextureDefaultValuesTexture] nonretainedObjectValue];
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should have default model property values", ^{
    expect(texture.usingAlphaChannel).to.equal(NO);
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
