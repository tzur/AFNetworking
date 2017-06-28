// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleUpsampleProcessor.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>
#import <LTEngine/LTGLPixelFormat.h>
#import <LTEngine/LTOpenCVExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNKStyleUpsampleProcessor ()

/// URL of the model file defining the parameters of the stylization network.
@property (readonly, nonatomic) NSURL *modelURL;

@end

@implementation PNKStyleUpsampleProcessor

- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _modelURL = modelURL;
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating this stub"];
    }
    return nil;
  }
  return self;
}

// Stub implementation.
- (void)upsampleStylizedImage:(CVPixelBufferRef)image withGuide:(CVPixelBufferRef)guide
                       output:(CVPixelBufferRef)output {
  LTParameterAssert(image);
  auto width = CVPixelBufferGetWidth(guide);
  auto height = CVPixelBufferGetHeight(guide);
  LTParameterAssert(height == CVPixelBufferGetHeight(output));
  LTParameterAssert(width == CVPixelBufferGetWidth(output));
  OSType imageFormat = CVPixelBufferGetPixelFormatType(image);
  LTParameterAssert(imageFormat == kCVPixelFormatType_32BGRA,
                    @"Expected image format to be %u, got:%u",
                    (unsigned int)kCVPixelFormatType_32BGRA, (unsigned int)imageFormat);

  LTCVPixelBufferImageForWriting(output, ^(cv::Mat *outputMat) {
    LTCVPixelBufferImageForReading(image, ^(const cv::Mat &imageMat) {
      cv::resize(imageMat, *outputMat, cv::Size((int)width, (int)height));
    });
  });
}

@end

NS_ASSUME_NONNULL_END
