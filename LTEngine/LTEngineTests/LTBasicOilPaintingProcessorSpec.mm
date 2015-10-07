// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBasicOilPaintingProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBasicOilPaintingProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTBasicOilPaintingProcessor *processor;

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should fail on invalid quantization parameter", ^{
    processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                            outputTexture:output];
    expect(^{
      processor.quantization = 1;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid radius parameter", ^{
    processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                            outputTexture:output];
    expect(^{
      processor.radius = 0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not fail on correct input", ^{
    processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                            outputTexture:output];
    expect(^{
      processor.quantization = 30;
      processor.radius = 3;
    }).toNot.raiseAny();
  });
});

context(@"initialization", ^{
  it(@"should not initialize when input and output textures have a different size", ^{
    expect(^{
      output = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 2)];
      processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                              outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should process square image", ^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    output = [LTTexture byteRGBATextureWithSize:input.size];
    processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                            outputTexture:output];
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"Lena128BasicOilPainting.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });

  it(@"should process rectangular image", ^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Meal.png")];
    output = [LTTexture byteRGBATextureWithSize:input.size];
    processor = [[LTBasicOilPaintingProcessor alloc] initWithInputTexture:input
                                                            outputTexture:output];
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MealBasicOilPainting.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
