// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureBasicExamples.h"

#import "CVPixelBuffer+LTEngine.h"
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
    __block LTGLPixelFormat *pixelFormat;
    __block int matType;
    __block cv::Mat image;

    beforeAll(^{
      pixelFormat = data[@"pixelFormat"];
      matType = pixelFormat.matType;
    });

    it(@"should create texture", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:size
                                                               pixelFormat:pixelFormat
                                                            allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.pixelFormat).to.equal(pixelFormat);
    });

    it(@"should load image from mat", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, matType);

      LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];

      expect(texture.size).to.equal(size);
      expect(texture.pixelFormat).to.equal(pixelFormat);
    });
  });

  // This will be executed when the test suite runs and generate execution of the shared examples
  // for each for the pixel formats.
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    // Note: \c LTGLPixelFormatDepth16Unorm format is not supported when creating memory mapped
    // textures, or OpenGL ES 2 textures.
    if (pixelFormat.value == LTGLPixelFormatDepth16Unorm) {
      return;
    }
    itShouldBehaveLike(kLTTextureBasicExamplesPrecisionAndFormat,
                       @{@"pixelFormat": pixelFormat});
  }];

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
      LTGLPixelFormat *pixelFormat = $(LTGLPixelFormatRGBA8Unorm);

      LTTexture *texture = [(LTTexture *)[textureClass alloc]
                            initWithSize:size pixelFormat:pixelFormat allocateMemory:NO];

      expect(texture.size).to.equal(size);
      expect(texture.pixelFormat).to.equal(pixelFormat);
    });

    it(@"should create a texture with similar properties", ^{
      CGSize size = CGSizeMake(42, 42);
      LTTexture *texture = [(LTTexture *)[textureClass alloc]
                            initWithSize:size pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                            maxMipmapLevel:0
                            allocateMemory:YES];
      LTTexture *similar = [(LTTexture *)[textureClass alloc] initWithPropertiesOf:texture];

      expect(similar.size).to.equal(texture.size);
      expect(similar.pixelFormat).to.equal(texture.pixelFormat);
      expect(similar.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
    });

    it(@"should not initialize with zero sized texture", ^{
      expect(^{
        LTTexture __unused *texture = [(LTTexture *)[textureClass alloc]
                                       initWithSize:CGSizeZero
                                       pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                       allocateMemory:YES];
      }).to.raise(NSInvalidArgumentException);
    });

    context(@"default values", ^{
      __block LTTexture *texture;

      beforeEach(^{
        texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMakeUniform(1)
                                                      pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
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
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should not load invalid image channel count", ^{
      CGSize size = CGSizeMake(42, 67);
      cv::Mat image(size.height, size.width, CV_32FC3);

      expect(^{
        __unused LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:image];
      }).to.raise(NSInvalidArgumentException);
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
        LTVector4 expected = LTVector4(image(point.y, point.x));

        expect(expected).to.equal(actual);
      });

      it(@"should return a correct pixel value outside texture", ^{
        CGPoint point = CGPointMake(-1, 49);

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTVector4(image(47, 1));

        expect(expected).to.equal(actual);
      });

      it(@"should return a correct pixel value on the boundary", ^{
        CGPoint point = CGPointMake(67, 48);

        LTVector4 actual = [texture pixelValue:point];
        LTVector4 expected = LTVector4(image(47, 66));

        expect(expected).to.equal(actual);
      });

      it(@"should return correct pixel values inside texture", ^{
        CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected;
        for (const CGPoint &point : points) {
          expected.push_back(LTVector4(image(point.y, point.x)));
        }

        expect(expected == actual).to.beTruthy();
      });

      it(@"should return correct pixel values outside texture", ^{
        CGPoints points{CGPointMake(-1, 2), CGPointMake(2, -5), CGPointMake(-1, 49)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected{
          LTVector4(image(2, 1)),
          LTVector4(image(5, 2)),
          LTVector4(image(47, 1))
        };

        expect(expected == actual).to.beTruthy();
      });

      it(@"should return a correct pixel value on the boundary", ^{
        CGPoints points{CGPointMake(0, 0), CGPointMake(67, 48)};

        LTVector4s actual = [texture pixelValues:points];
        LTVector4s expected{
          LTVector4(image(0, 0)),
          LTVector4(image(47, 66))
        };

        expect(expected == actual).to.beTruthy();
      });
    });

    context(@"texture with non continuous image", ^{
      __block LTTexture *texture;
      __block cv::Mat4b continuousImage;
      __block cv::Mat4b nonContinuousImage;

      beforeEach(^{
        continuousImage.create(100, 100);
        continuousImage.setTo(cv::Vec4b(0, 0, 255, 0));

        nonContinuousImage = continuousImage(cv::Rect(17, 29, 48, 67));
        for (int y = 0; y < nonContinuousImage.rows; ++y) {
          for (int x = 0; x < nonContinuousImage.cols; ++x) {
            nonContinuousImage(y, x) = cv::Vec4b(x, y, 0, 255);
          }
        }
        expect(nonContinuousImage.isContinuous()).to.beFalsy();

        texture = [(LTTexture *)[textureClass alloc] initWithImage:nonContinuousImage];
      });

      afterEach(^{
        texture = nil;
      });

      it(@"should read entire texture to image", ^{
        cv::Mat read = [texture image];

        expect(LTCompareMat(nonContinuousImage, read)).to.beTruthy();
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
                                                                pixelFormat:texture.pixelFormat
                                                             allocateMemory:YES];

        expect(^{
          [texture cloneTo:cloned];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"clearing texture", ^{
      dit(@"should clear texture with color", ^{
        LTVector4 color = LTVector4(1.0, 0.0, 0.0, 1.0);
        [texture clearColor:color];

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

      it(@"should set fill color on clearColor", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor).to.equal(LTVector4::ones());
        [texture clearColor:LTVector4::zeros()];;
        expect(texture.fillColor).to.equal(LTVector4::zeros());
      });

      it(@"should set fill color to null on load", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture load:cv::Mat4b(16, 16)];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set fill color to null on loadRect:fromImage", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture loadRect:CGRectMake(0, 0, 8, 8) fromImage:cv::Mat4b(8, 8)];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set fill color to null on mappedForWriting", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          expect(mapped->rows).to.equal(texture.size.height);
          expect(mapped->cols).to.equal(texture.size.width);
        }];
        expect(texture.fillColor.isNull()).to.beTruthy();
      });

      it(@"should not set fill color to null on mappedForReading", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
          expect(mapped.rows).to.equal(texture.size.height);
          expect(mapped.cols).to.equal(texture.size.width);
        }];
        expect(texture.fillColor.isNull()).to.beFalsy();
      });

      it(@"should have initial fill color of null when initializing with properties of texture", ^{
        [texture clearColor:LTVector4::ones()];
        expect(texture.fillColor.isNull()).to.beFalsy();
        LTTexture *other = [[[texture class] alloc] initWithPropertiesOf:texture];
        expect(other.fillColor.isNull()).to.beTruthy();
      });

      it(@"should set the fill color when cloning a texture with fill color", ^{
        [texture clearColor:LTVector4::ones()];
        LTTexture *other = [[[texture class] alloc] initWithPropertiesOf:texture];
        [texture cloneTo:other];
        expect(other.fillColor).to.equal(texture.fillColor);
      });
    });

    context(@"drawing with core graphics", ^{
      it(@"should draw with core graphics to red channel texture", ^{
        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(67, 48) pixelFormat:$(LTGLPixelFormatR8Unorm)
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

      it(@"should draw with core graphics to 4 channel texture", ^{
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

      it(@"should draw with core graphics to 4 channel half float premultiplied texture", ^{
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithSize:CGSizeMake(2, 2)
                              pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];

        [texture drawWithCoreGraphics:^(CGContextRef context) {
          UIGraphicsPushContext(context); {
            [[UIColor colorWithRed:0 green:0 blue:0 alpha:1] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, texture.size));
            [[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5] setFill];
            CGContextFillRect(context, CGRectFromOriginAndSize(CGPointZero, CGSizeMake(1, 1)));
          } UIGraphicsPopContext();
        }];
        auto gray = LTCVVec4hf(0.25, 0.25, 0.25, 1);
        auto black = LTCVVec4hf(0, 0, 0, 1);
        cv::Mat4hf expected = (cv::Mat4hf(texture.size.height, texture.size.width) << gray, black,
                               black, black);
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

    context(@"drawing with core image", ^{
      it(@"should leave texture unchanged in case block returns nil", ^{
        NSString *expectedGenerationID = texture.generationID;
        cv::Mat expected = texture.image;

        [texture drawWithCoreImage:^CIImage *{
          return nil;
        }];

        expect(texture.generationID).to.equal(expectedGenerationID);
        expect($(texture.image)).to.equalMat($(expected));
      });

      it(@"should draw to red channel byte texture", ^{
        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(65, 47)
                              pixelFormat:$(LTGLPixelFormatR8Unorm) allocateMemory:YES];

        cv::Mat1b expected = cv::Mat1b::zeros(texture.size.height, texture.size.width);
        expected(cv::Rect(0, 0, 4, 4)).setTo(255);
        auto pixelBuffer = LTCVPixelBufferCreate(expected.cols, expected.rows,
                                                 kCVPixelFormatType_OneComponent8);
        LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
          expected.copyTo(*image);
        });

        CIImage *expectedCIImage = [CIImage imageWithCVPixelBuffer:pixelBuffer.get() options:@{
          kCIImageColorSpace: [NSNull null]
        }];

        [texture drawWithCoreImage:^CIImage *{
          return expectedCIImage;
        }];

        expect($([texture image])).to.equalMat($(expected));
      });

      dit(@"should draw to red channel half float texture", ^{
        using half_float::half;

        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(65, 47)
                              pixelFormat:$(LTGLPixelFormatR16Float) allocateMemory:YES];

        cv::Mat1hf expected = cv::Mat1hf::zeros(texture.size.height, texture.size.width);
        cv::Mat1hf roi = expected(cv::Rect(0, 0, 4, 4));
        std::fill(roi.begin(), roi.end(), half(1));

        auto pixelBuffer = LTCVPixelBufferCreate(expected.cols, expected.rows,
                                                 kCVPixelFormatType_OneComponent16Half);
        LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
          expected.copyTo(*image);
        });

        CIImage *expectedCIImage = [CIImage imageWithCVPixelBuffer:pixelBuffer.get() options:@{
          kCIImageColorSpace: [NSNull null]
        }];

        [texture drawWithCoreImage:^CIImage *{
          return expectedCIImage;
        }];

        expect($([texture image])).to.beCloseToMatWithin($(expected), 0.02);
      });

      it(@"should draw to 4 channel byte texture", ^{
        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(65, 47)
                              pixelFormat:$(LTGLPixelFormatRGBA8Unorm) allocateMemory:YES];

        cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(0, 0, 0, 255));
        expected(cv::Rect(0, 0, 4, 4)).setTo(cv::Vec4b(255, 0, 0, 255));
        auto pixelBuffer = LTCVPixelBufferCreate(expected.cols, expected.rows,
                                                 kCVPixelFormatType_32BGRA);
        LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
          cv::cvtColor(expected, *image, cv::COLOR_RGBA2BGRA);
        });

        CIImage *expectedCIImage = [CIImage imageWithCVPixelBuffer:pixelBuffer.get() options:@{
          kCIImageColorSpace: [NSNull null]
        }];

        [texture drawWithCoreImage:^CIImage *{
          return expectedCIImage;
        }];

        expect($(texture.image)).to.equalMat($(expected));
      });

      dit(@"should draw to 4 channel half float texture", ^{
        using half_float::half;

        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(65, 47)
                              pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];

        cv::Mat4hf expected = cv::Mat4hf::zeros(texture.size.height, texture.size.width);
        cv::Mat4hf roi = expected(cv::Rect(0, 0, 4, 4));
        std::fill(roi.begin(), roi.end(), cv::Vec4hf(half(1), half(2), half(3), half(4)));

        auto pixelBuffer = LTCVPixelBufferCreate(expected.cols, expected.rows,
                                                 kCVPixelFormatType_64RGBAHalf);
        LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
          expected.copyTo(*image);
        });

        CIImage *expectedCIImage = [CIImage imageWithCVPixelBuffer:pixelBuffer.get() options:@{
          kCIImageColorSpace: [NSNull null]
        }];

        [texture drawWithCoreImage:^CIImage *{
          return expectedCIImage;
        }];

        expect($(texture.image)).to.beCloseToMatWithin($(expected), 0.02);
      });

      it(@"should use byte working format when target texture is of byte precision", ^{
        static const cv::Vec4b kColor(32, 64, 128, 255);
        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithImage:cv::Mat4b(47, 65, kColor)];

        LTTexture *output = [(LTTexture *)[textureClass alloc]
                             initWithImage:cv::Mat4b::zeros(1, 1)];
        LTTexture *expectedOutput = [(LTTexture *)[textureClass alloc]
                                     initWithImage:cv::Mat4b(1, 1, kColor)];

        [texture mappedCIImage:^(CIImage *image) {
          [output drawWithCoreImage:^CIImage *{
            CIFilter *filter = [CIFilter filterWithName:@"CIAreaAverage"];
            [filter setValue:image forKey:kCIInputImageKey];
            return filter.outputImage;
          }];
        }];

        expect($(output.image)).notTo.equalMat($(expectedOutput.image));
        expect($(output.image)).to.beCloseToMat($(expectedOutput.image));
      });

      dit(@"should use half float working format when target texture is of half float precision", ^{
        static const LTVector4 kColor(0.1, 0.2, 0.3, 0.4);
        LTTexture *texture = [(LTTexture *)[textureClass alloc]
                              initWithSize:CGSizeMake(65, 47)
                              pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];
        [texture clearColor:kColor];

        LTTexture *output = [[textureClass alloc]
                             initWithSize:CGSizeMakeUniform(1)
                             pixelFormat:texture.pixelFormat allocateMemory:YES];
        LTTexture *expectedOutput = [[textureClass alloc] initWithPropertiesOf:output];
        [expectedOutput clearColor:kColor];

        [texture mappedCIImage:^(CIImage *image) {
          [output drawWithCoreImage:^CIImage *{
            CIFilter *filter = [CIFilter filterWithName:@"CIAreaAverage"];
            [filter setValue:image forKey:kCIInputImageKey];
            return filter.outputImage;
          }];
        }];

        expect($(output.image)).to.beCloseToMatWithin($(expectedOutput.image), 1e-3);
      });
    });

    context(@"reading contents as CIImage", ^{
      it(@"should generate CIImage for a red channel byte texture", ^{
        cv::Mat1b input(47, 65, 128);
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:input];

        __block auto pixelBuffer =
            LTCVPixelBufferCreate(input.cols, input.rows, kCVPixelFormatType_32BGRA);

        CIContext *context = [CIContext contextWithOptions:@{
          kCIContextWorkingColorSpace: [NSNull null],
          kCIContextOutputColorSpace: [NSNull null]
        }];

        __block BOOL mapped = NO;
        [texture mappedCIImage:^(CIImage *image) {
          expect(image.extent).to.equal(CGRectMake(0, 0, input.cols, input.rows));

          [context render:image toCVPixelBuffer:pixelBuffer.get()
                   bounds:image.extent colorSpace:NULL];

          LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
            std::vector<cv::Mat> channels;
            cv::split(image, channels);
            expect($(channels[0])).to.equalMat($(input));
          });

          mapped = YES;
        }];

        expect(mapped).to.beTruthy();
      });

      dit(@"should generate CIImage for a red channel half float texture", ^{
        using half_float::half;

        cv::Mat1hf input = cv::Mat1hf::zeros(47, 65);
        std::fill(input.begin(), input.end(), half(1));
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:input];

        __block auto pixelBuffer =
            LTCVPixelBufferCreate(input.cols, input.rows, kCVPixelFormatType_OneComponent16Half);

        CIContext *context = [CIContext contextWithOptions:@{
          kCIContextWorkingColorSpace: [NSNull null],
          kCIContextOutputColorSpace: [NSNull null]
        }];

        __block BOOL mapped = NO;
        [texture mappedCIImage:^(CIImage *image) {
          expect(image.extent).to.equal(CGRectMake(0, 0, input.cols, input.rows));

          [context render:image toCVPixelBuffer:pixelBuffer.get()
                   bounds:image.extent colorSpace:NULL];

          LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
            expect($(image)).to.equalMat($(input));
          });

          mapped = YES;
        }];

        expect(mapped).to.beTruthy();
      });

      it(@"should generate CIImage for a 4 channel byte texture", ^{
        cv::Mat4b input(47, 65, cv::Vec4b(32, 64, 128, 255));
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:input];

        __block BOOL mapped = NO;
        [texture mappedCIImage:^(CIImage *image) {
          mapped = YES;

          expect(image.extent).to.equal(CGRectMake(0, 0, input.cols, input.rows));

          CIContext *context = [CIContext contextWithOptions:@{
            kCIContextWorkingColorSpace: [NSNull null],
            kCIContextOutputColorSpace: [NSNull null]
          }];

          cv::Mat4b output(input.rows, input.cols);
          [context render:image toBitmap:output.data rowBytes:output.step[0] bounds:image.extent
                   format:kCIFormatRGBA8 colorSpace:NULL];

          expect($(output)).to.equalMat($(input));
        }];

        expect(mapped).to.beTruthy();
      });

      dit(@"should generate CIImage for a 4 channel half float texture", ^{
        using half_float::half;

        cv::Mat4hf input = cv::Mat4hf::zeros(47, 65);
        std::fill(input.begin(), input.end(), cv::Vec4hf(half(1), half(2), half(3), half(4)));
        LTTexture *texture = [(LTTexture *)[textureClass alloc] initWithImage:input];

        __block auto pixelBuffer =
            LTCVPixelBufferCreate(input.cols, input.rows, kCVPixelFormatType_64RGBAHalf);

        CIContext *context = [CIContext contextWithOptions:@{
          kCIContextWorkingColorSpace: [NSNull null],
          kCIContextOutputColorSpace: [NSNull null]
        }];

        __block BOOL mapped = NO;
        [texture mappedCIImage:^(CIImage *image) {
          expect(image.extent).to.equal(CGRectMake(0, 0, input.cols, input.rows));

          [context render:image toCVPixelBuffer:pixelBuffer.get()
                   bounds:image.extent colorSpace:NULL];

          LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
            expect($(image)).to.equalMat($(input));
          });

          mapped = YES;
        }];

        expect(mapped).to.beTruthy();
      });
    });

    context(@"pixel buffer", ^{
      it(@"should return pixel buffer", ^{
        auto pixelBuffer = [texture pixelBuffer];
        BOOL empty = !pixelBuffer;
        expect(empty).to.beFalsy();
      });

      dit(@"should return pixel buffer with previous GPU writes already in effect", ^{
        const std::array<float, 5> values = {{0, 0.25, 0.5, 0.75, 1.0}};

        for (float value : values) {
          [texture clearColor:LTVector4(value, value, value, value)];
          lt::Ref<CVPixelBufferRef> pixelBuffer = [texture pixelBuffer];
          LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
            cv::Mat4b expected = cv::Mat4b(texture.size.height, texture.size.width,
                                           cv::Vec4b(value * 255, value * 255, value * 255,
                                                     value * 255));

            expect($(image)).to.beCloseToMat($(expected));
          });
        }
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

      it(@"should change generation ID after writing via writeToAttachableWithBlock", ^{
        [texture writeToAttachableWithBlock:^{
        }];
        expect(texture.generationID).toNot.equal(generationID);
      });

      it(@"should not change generation ID after reading via sampleWithGPUWithBlock", ^{
        [texture sampleWithGPUWithBlock:^{
        }];
        expect(texture.generationID).to.equal(generationID);
      });

      it(@"should not change generation ID after reading via begin/end samplingWithGPU", ^{
        [texture beginSamplingWithGPU];
        [texture endSamplingWithGPU];
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

      it(@"should change generation ID after clearColor", ^{
        [texture clearColor:LTVector4::zeros()];
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
