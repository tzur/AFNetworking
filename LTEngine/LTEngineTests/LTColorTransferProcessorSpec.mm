// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTColorTransferProcessor.h"

#import "LT3DLUT.h"
#import "LT3DLUTProcessor.h"
#import "LTImage+Texture.h"
#import "LTOpenCVExtensions.h"
#import "LTTestColorTransferProcessor.h"
#import "LTTexture+Factory.h"

static LTTexture *LTApplyLUT(LTTexture *input, LT3DLUT *lut) {
  auto output = [LTTexture textureWithPropertiesOf:input];
  auto processor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];
  processor.lookupTable = lut;
  [processor process];
  return output;
}

SpecBegin(LTColorTransferProcessor)

__block LTColorTransferProcessor *processor;

beforeEach(^{
  processor = [[LTColorTransferProcessor alloc] init];
});

it(@"should have default properties", ^{
  expect(processor.iterations).to.equal(20);
  expect(processor.histogramBins).to.equal(32);
  expect(processor.dampingFactor).to.equal(0.2);
  expect(processor.noisyCopies).to.equal(1);
  expect(processor.noiseStandardDeviation).to.equal(0.1);
  expect(processor.alphaThreshold).to.equal(0.5);
});

context(@"texture formats", ^{
  __block LTTexture *byteRed;
  __block LTTexture *byteRGBA;
  __block LTTexture *halfFloatRed;
  __block LTTexture *halfFloatRGBA;

  beforeEach(^{
    processor.iterations = 1;
    byteRed = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(16)];
    byteRGBA = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    halfFloatRed = [LTTexture textureWithSize:CGSizeMakeUniform(16)
                                  pixelFormat:$(LTGLPixelFormatR16Float) allocateMemory:YES];
    halfFloatRGBA = [LTTexture textureWithSize:CGSizeMakeUniform(16)
                                   pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];
  });

  afterEach(^{
    byteRed = nil;
    byteRGBA = nil;
    halfFloatRed = nil;
    halfFloatRGBA = nil;
  });

  it(@"should not raise if both input and reference are byte RGBA", ^{
    expect(^{
      [processor lutForInputTexture:byteRGBA referenceTexture:byteRGBA progress:nil];
    }).notTo.raiseAny();
  });

  it(@"should raise if input texture is of incorrect format", ^{
    expect(^{
      [processor lutForInputTexture:byteRed referenceTexture:byteRGBA progress:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInputTexture:halfFloatRed referenceTexture:byteRGBA progress:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInputTexture:halfFloatRGBA referenceTexture:byteRGBA progress:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if reference texture is of incorrect format", ^{
    expect(^{
      [processor lutForInputTexture:byteRGBA referenceTexture:byteRed progress:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInputTexture:byteRGBA referenceTexture:halfFloatRed progress:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInputTexture:byteRGBA referenceTexture:halfFloatRGBA progress:nil];
    }).to.raise(NSInvalidArgumentException);
});
});

context(@"creating lookup table mapping input palette to reference palette", ^{
  __block LTTexture *input;
  __block LTTexture *reference;
  __block cv::Mat4b expected;

  beforeEach(^{
    processor.iterations = 10;
    input = [LTTexture textureWithImage:LTLoadMat(self.class, @"LTColorTransferInput.jpg")];
    reference = [LTTexture textureWithImage:LTLoadMat(self.class, @"LTColorTransferReference.jpg")];
    expected = LTLoadMat(self.class, @"LTColorTransferResult.png");
  });

  afterEach(^{
    input = nil;
    reference = nil;
  });

  it(@"should compute correct lut on test processor", ^{
    auto testProcessor = [[LTTestColorTransferProcessor alloc] init];
    testProcessor.iterations = processor.iterations;
    auto lut = [testProcessor lutForInputTexture:input referenceTexture:reference progress:nil];
    auto output = LTApplyLUT(input, lut);
    expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should compute correct lut for given matrices", ^{
    auto lut = [processor lutForInputMat:input.image referenceMat:reference.image progress:nil];
    auto output = LTApplyLUT(input, lut);
    expect($(output.image)).to.beCloseToMatWithin($(expected), 3);
  });

  it(@"should compute correct lut for given textures", ^{
    auto lut = [processor lutForInputTexture:input referenceTexture:reference progress:nil];
    auto output = LTApplyLUT(input, lut);
    expect($(output.image)).to.beCloseToMatWithin($(expected), 3);
  });

  context(@"transparency", ^{
    it(@"should return nil if all input pixels have alpha below threshold", ^{
      cv::Mat4b transparent = input.image;
      std::transform(transparent.begin(), transparent.end(), transparent.begin(), [](cv::Vec4b v) {
        v[3] = 0;
        return v;
      });

      auto lut = [processor lutForInputMat:transparent referenceMat:reference.image progress:nil];
      expect(lut).to.beNil();
    });

    it(@"should return nil if all reference pixels have alpha below threshold", ^{
      cv::Mat4b transparent = reference.image;
      std::transform(transparent.begin(), transparent.end(), transparent.begin(), [](cv::Vec4b v) {
        v[3] = 0;
        return v;
      });

      auto lut = [processor lutForInputMat:input.image referenceMat:transparent progress:nil];
      expect(lut).to.beNil();
    });

    it(@"should ignore input pixels with alpha values below threshold", ^{
      auto transparent = [input clone];
      [transparent mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        cv::Mat4b roi = mapped->rowRange(0, mapped->rows / 2);
        mapped->rowRange(0, mapped->rows / 2).setTo(cv::Vec4b(255, 255, 255, 0));
      }];
      auto lut = [processor lutForInputTexture:transparent referenceTexture:reference progress:nil];
      auto output = LTApplyLUT(input, lut);

      expected = LTLoadMat(self.class, @"LTColorTransferResultTransparentInput.png");
      expect($(output.image)).to.beCloseToMatWithin($(expected), 3);
    });

    it(@"should ignore reference pixels with alpha values below threshold", ^{
      [reference mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        cv::Mat4b roi = mapped->rowRange(0, mapped->rows / 2);
        mapped->rowRange(0, mapped->rows / 2).setTo(cv::Vec4b(255, 255, 255, 0));
      }];

      auto lut = [processor lutForInputTexture:input referenceTexture:reference progress:nil];
      auto output = LTApplyLUT(input, lut);

      expected = LTLoadMat(self.class, @"LTColorTransferResultTransparentReference.png");
      expect($(output.image)).to.beCloseToMatWithin($(expected), 3);
    });
  });
});

context(@"progress callback", ^{
  __block LTTexture *input;
  __block LTTexture *reference;

  beforeEach(^{
    processor.iterations = 4;
    input = [LTTexture textureWithImage:LTLoadMat(self.class, @"LTColorTransferInput.jpg")];
    reference = [LTTexture textureWithImage:LTLoadMat(self.class, @"LTColorTransferReference.jpg")];
  });

  afterEach(^{
    input = nil;
    reference = nil;
  });

  it(@"should call progress block after every iteration", ^{
    NSMutableArray<NSNumber *> *iterations = [NSMutableArray array];
    [processor lutForInputMat:input.image referenceMat:reference.image
                     progress:^(NSUInteger iterationsCompleted, LT3DLUT *) {
      [iterations addObject:@(iterationsCompleted)];
    }];

    expect(iterations).to.equal(@[@1, @2, @3, @4]);
  });

  it(@"should call progress block with intermediate lookup tables", ^{
    auto testProcessor = [[LTTestColorTransferProcessor alloc] init];
    testProcessor.iterations = processor.iterations;

    __block NSMutableArray<LTTexture *> *expected = [NSMutableArray array];
    [testProcessor lutForInputTexture:input referenceTexture:reference
                             progress:^(NSUInteger, LT3DLUT *lut) {
      [expected addObject:LTApplyLUT(input, lut)];
    }];

    __block NSMutableArray<LTTexture *> *actual = [NSMutableArray array];
    [processor lutForInputTexture:input referenceTexture:reference
                         progress:^(NSUInteger, LT3DLUT *lut) {
       [actual addObject:LTApplyLUT(input, lut)];
     }];

    expect(actual).to.haveCountOf(expected.count);
    for (NSUInteger i = 0; i < actual.count; ++i) {
      expect($(actual[i].image)).to.beCloseToMatWithin($(expected[i].image), 3);
    }
  });

  it(@"should provide the final lookup table in the last call to the progress block", ^{
    __block LT3DLUT *progressLut;
    __block NSUInteger progressIteration;
    auto returnedLut = [processor lutForInputTexture:input referenceTexture:reference
                                            progress:^(NSUInteger iteration, LT3DLUT *lut) {
      progressLut = lut;
      progressIteration = iteration;
    }];

    expect(progressIteration).to.equal(processor.iterations);
    expect(progressLut).to.equal(returnedLut);
  });
});

SpecEnd
