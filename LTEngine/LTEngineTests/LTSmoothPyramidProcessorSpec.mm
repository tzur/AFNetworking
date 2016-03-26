// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSmoothPyramidProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTSmoothPyramidProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTSmoothPyramidProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"PyramidGrid7.png")];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should create correct pyramid", ^{
    NSArray *outputs = @[[LTTexture byteRGBATextureWithSize:input.size * 2],
                         [LTTexture byteRGBATextureWithSize:input.size * 4],
                         [LTTexture byteRGBATextureWithSize:input.size * 8]];
    processor = [[LTSmoothPyramidProcessor alloc] initWithInput:input outputs:outputs];
    
    [processor process];

    for (NSUInteger i = 0; i < outputs.count; ++i) {
      cv::Mat expected = LTLoadMat([self class],
                                   [NSString stringWithFormat:@"SmoothPyramidUpsampleGrid%lu.png",
                                    (unsigned long)6 - i]);
      expect($([(LTTexture *)outputs[i] image])).to.equalMat($(expected));
    }
  });

  it(@"should upsample correctly to odd grid", ^{
    NSArray *outputs = @[[LTTexture byteRGBATextureWithSize:input.size * 2 + 1]];
    LTSmoothPyramidProcessor *processor = [[LTSmoothPyramidProcessor alloc] initWithInput:input
                                                                                  outputs:outputs];
    [processor process];

    cv::Mat expected =
        LTLoadMat([self class], [NSString stringWithFormat:@"SmoothPyramidUpsampleToOddGrid.png"]);
    expect($([(LTTexture *)[outputs firstObject] image])).to.equalMat($(expected));
  });
});

SpecEnd
