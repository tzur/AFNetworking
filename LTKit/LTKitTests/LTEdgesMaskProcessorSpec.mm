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
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default tone properties correctly", ^{
    expect(processor.edgesMode).to.equal(LTEdgesModeGrey);
  });
});
  
context(@"processing", ^{
  sit(@"should return greyscale edges", ^{
    LTEdgesMaskProcessor *processor =
        [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethGreyEdges.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
  
  sit(@"should return color edges", ^{
    LTEdgesMaskProcessor *processor =
        [[LTEdgesMaskProcessor alloc] initWithInput:input output:output];
    processor.edgesMode = LTEdgesModeColor;
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethColorEdges.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
