// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTRGBToHSVProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTRGBToHSVProcessor)

context(@"processing", ^{
  it(@"should process grey correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(64, 64, 64, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(0, 0, 64, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTRGBToHSVProcessor *processor = [[LTRGBToHSVProcessor alloc] initWithInput:inputTexture
                                                                         output:outputTexture];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process red correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(255, 0, 0, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(0, 255, 255, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTRGBToHSVProcessor *processor = [[LTRGBToHSVProcessor alloc] initWithInput:inputTexture
                                                                         output:outputTexture];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process green correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 255, 0, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(85, 255, 255, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTRGBToHSVProcessor *processor = [[LTRGBToHSVProcessor alloc] initWithInput:inputTexture
                                                                         output:outputTexture];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process grey correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 0, 255, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(170, 255, 255, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTRGBToHSVProcessor *processor = [[LTRGBToHSVProcessor alloc] initWithInput:inputTexture
                                                                         output:outputTexture];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
});
  
LTSpecEnd
