// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTEdgesMaskProcessor.h"

#import "LTCGExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTEdgesMaskProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTEdgesMaskProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"MacbethSmall.jpg")];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"processing", ^{
  sit(@"should return greyscale edges", ^{
    output = [LTTexture byteRedTextureWithSize:input.size];
    processor = [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    LTEdgesMaskProcessor *processor =
        [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethGreyEdges.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
  
  sit(@"should return color edges", ^{
    output = [LTTexture byteRGBATextureWithSize:input.size];
    processor = [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    LTEdgesMaskProcessor *processor =
        [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethColorEdges.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
