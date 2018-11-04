// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSmoothPyramidProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTSmoothPyramidProcessor)

__block LTTexture *input;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"PyramidGrid7.png")];
});

afterEach(^{
  input = nil;
});

context(@"properties", ^{
  it(@"should upsample correctly using subsampled smoothing kernels", ^{
    NSArray *outputs = @[[LTTexture byteRGBATextureWithSize:input.size * 2],
                         [LTTexture byteRGBATextureWithSize:input.size * 4],
                         [LTTexture byteRGBATextureWithSize:input.size * 8]];
    LTSmoothPyramidProcessor *processor = [[LTSmoothPyramidProcessor alloc] initWithInput:input
                                                                                  outputs:outputs];
    [processor process];

    for (NSUInteger i = 0; i < outputs.count; ++i) {
      cv::Mat expected = LTLoadMat([self class],
                                   [NSString stringWithFormat:@"SmoothPyramidUpsampleGrid%lu.png",
                                    (unsigned long)6 - i]);
      expect($([(LTTexture *)outputs[i] image])).to.beCloseToMatPSNR($(expected), 50);
    }
  });

  it(@"should upsample correctly using canonical smoothing kernels", ^{
    NSArray *outputs = @[[LTTexture byteRGBATextureWithSize:input.size * 2],
                         [LTTexture byteRGBATextureWithSize:input.size * 4],
                         [LTTexture byteRGBATextureWithSize:input.size * 8]];
    LTSmoothPyramidProcessor *processor = [[LTSmoothPyramidProcessor alloc] initWithInput:input
                                                                                  outputs:outputs];
    processor.updateTexelStepInUpsample = YES;
    [processor process];

    for (NSUInteger i = 0; i < outputs.count; ++i) {
      cv::Mat expected =
          LTLoadMat([self class],
                    [NSString stringWithFormat:@"SmoothPyramidUpsampleUpdateGrid%lu.png",
                     (unsigned long)6 - i]);
      expect($([(LTTexture *)outputs[i] image])).to.beCloseToMatPSNR($(expected), 50);
    }
  });

  it(@"should upsample correctly to odd grid", ^{
    NSArray *outputs = @[[LTTexture byteRGBATextureWithSize:input.size * 2 + 1]];
    LTSmoothPyramidProcessor *processor = [[LTSmoothPyramidProcessor alloc] initWithInput:input
                                                                                  outputs:outputs];
    [processor process];

    cv::Mat expected =
        LTLoadMat([self class], [NSString stringWithFormat:@"SmoothPyramidUpsampleToOddGrid.png"]);
    expect($([(LTTexture *)[outputs firstObject] image])).to.beCloseToMatPSNR($(expected), 50);
  });
});

SpecEnd
