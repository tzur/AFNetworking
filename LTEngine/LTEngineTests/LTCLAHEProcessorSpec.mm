// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTCLAHEProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTCLAHEProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTCLAHEProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"initialization", ^{
  it(@"should not initialize with RGB texture as output", ^{
    expect(^{
      output = [LTTexture byteRGBATextureWithSize:input.size];
      processor = [[LTCLAHEProcessor alloc] initWithInputTexture:input
                                                   outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  sit(@"should image with locally equalized histograms", ^{
    output = [LTTexture byteRedTextureWithSize:input.size];
    processor = [[LTCLAHEProcessor alloc] initWithInputTexture:input
                                                 outputTexture:output];
    
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"Lena128CLAHE.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

LTSpecEnd
