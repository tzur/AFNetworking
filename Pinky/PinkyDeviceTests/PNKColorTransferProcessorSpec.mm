// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferProcessor.h"

#import <LTEngine/LT3DLUT.h>
#import <LTEngine/LT3DLUTProcessor.h>
#import <LTEngine/LTColorTransferProcessor.h>
#import <LTEngine/LTGLContext.h>
#import <LTEngine/LTImage+Texture.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTTexture+Factory.h>

static LTTexture *LTApplyLUT(LTTexture *input, LT3DLUT *lut) {
  auto output = [LTTexture textureWithPropertiesOf:input];
  auto processor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];
  processor.lookupTable = lut;
  [processor process];
  return output;
}

DeviceSpecBegin(PNKColorTransferMetalProcessor)

__block id<MTLDevice> device;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];

  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
  [LTGLContext setCurrentContext:nil];
});

it(@"should have default properties", ^{
  auto processor = [[PNKColorTransferProcessor alloc]
                    initWithDevice:device inputSize:CGSizeMakeUniform(1)
                    referenceSize:CGSizeMakeUniform(1)];

  expect(processor.iterations).to.equal(20);
  expect(processor.histogramBins).to.equal(32);
  expect(processor.dampingFactor).to.equal(0.2);
});

context(@"pixel buffer formats", ^{
  __block PNKColorTransferProcessor *processor;
  __block LTTexture *byteRed;
  __block LTTexture *byteRGBA;
  __block LTTexture *halfFloatRed;
  __block LTTexture *halfFloatRGBA;

  beforeEach(^{
    auto size = CGSizeMakeUniform(16);
    byteRed = [LTTexture byteRedTextureWithSize:size];
    byteRGBA = [LTTexture byteRGBATextureWithSize:size];
    halfFloatRed = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatR16Float)
                               allocateMemory:YES];
    halfFloatRGBA = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                allocateMemory:YES];
    processor = [[PNKColorTransferProcessor alloc]
                 initWithDevice:device inputSize:size referenceSize:size];
  });

  afterEach(^{
    processor = nil;
    byteRed = nil;
    byteRGBA = nil;
    halfFloatRed = nil;
    halfFloatRGBA = nil;
  });

  it(@"should not raise if both input and reference are byte RGBA or half-float RGBA", ^{
    expect(^{
      [processor lutForInput:byteRGBA.pixelBuffer.get() reference:byteRGBA.pixelBuffer.get()];
      [processor lutForInput:byteRGBA.pixelBuffer.get() reference:halfFloatRGBA.pixelBuffer.get()];
      [processor lutForInput:halfFloatRGBA.pixelBuffer.get() reference:byteRGBA.pixelBuffer.get()];
      [processor lutForInput:halfFloatRGBA.pixelBuffer.get()
                   reference:halfFloatRGBA.pixelBuffer.get()];
    }).notTo.raiseAny();
  });

  it(@"should raise if input texture is of incorrect format", ^{
    expect(^{
      [processor lutForInput:byteRed.pixelBuffer.get() reference:byteRGBA.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInput:halfFloatRed.pixelBuffer.get() reference:byteRGBA.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if reference texture is of incorrect format", ^{
    expect(^{
      [processor lutForInput:byteRGBA.pixelBuffer.get() reference:byteRed.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [processor lutForInput:byteRGBA.pixelBuffer.get() reference:halfFloatRed.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"incorrect size", ^{
  __block PNKColorTransferProcessor *processor;
  __block LTTexture *small;
  __block LTTexture *large;

  beforeEach(^{
    small = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    large = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(32)];
    processor = [[PNKColorTransferProcessor alloc]
                 initWithDevice:device inputSize:small.size referenceSize:small.size];
  });

  afterEach(^{
    processor = nil;
    small = nil;
    large = nil;
  });

  it(@"should not raise if both input and reference are in the correct size", ^{
    expect(^{
      [processor lutForInput:small.pixelBuffer.get() reference:small.pixelBuffer.get()];
    }).notTo.raiseAny();
  });

  it(@"should raise if input pixelbuffer size doesn't match size provided at initialization", ^{
    expect(^{
      [processor lutForInput:large.pixelBuffer.get() reference:small.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if reference pixelbuffer size doesn't match size provided at initialization", ^{
    expect(^{
      [processor lutForInput:small.pixelBuffer.get() reference:large.pixelBuffer.get()];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"create lut from input and reference textures", ^{
  __block LTTexture *inputTexture;
  __block LTTexture *referenceTexture;

  beforeEach(^{
    inputTexture = [LTTexture textureWithImage:LTLoadMat(self.class, @"ColorTransferInput.png")];
    referenceTexture =
        [LTTexture textureWithImage:LTLoadMat(self.class, @"ColorTransferReference.png")];
  });

  afterEach(^{
    inputTexture = nil;
    referenceTexture = nil;
  });

  it(@"should create lookup table mapping input palette to reference palette", ^{
    auto processor = [[PNKColorTransferProcessor alloc]
                      initWithDevice:device inputSize:inputTexture.size
                      referenceSize:referenceTexture.size];
    processor.iterations = 5;
    processor.dampingFactor = 0.5;
    auto lut = [processor lutForInput:inputTexture.pixelBuffer.get()
                            reference:referenceTexture.pixelBuffer.get()];
    auto output = LTApplyLUT(inputTexture, lut);

    auto expected = LTLoadMat(self.class, @"ColorTransferResult.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 3);
  });
});

DeviceSpecEnd
