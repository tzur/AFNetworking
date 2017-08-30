// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTCLAHEProcessor.h"

#import "LTColorConversionProcessor.h"
#import "LTTexture+Factory.h"

@interface LTCLAHEProcessor ()

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

@end

@implementation LTCLAHEProcessor

- (instancetype)initWithInputTexture:(LTTexture *)inputTexture
                       outputTexture:(LTTexture *)outputTexture {
  LTParameterAssert(outputTexture.pixelFormat.value == LTGLPixelFormatR8Unorm,
                    @"Output texture pixel format should be LTGLPixelFormatR8Unorm, got: %@",
                    outputTexture.pixelFormat);
  if (self = [super init]) {
    self.inputTexture = inputTexture;
    self.outputTexture = outputTexture;
  }
  return self;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  LTColorConversionProcessor *processor =
      [[LTColorConversionProcessor alloc] initWithInput:self.inputTexture
                                                 output:self.outputTexture];
  processor.mode = LTColorConversionRGBToYYYY;
  [processor process];

  [self.outputTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE();
    clahe->setClipLimit(3);
    clahe->apply(*mapped, *mapped);
  }];
}

@end
