// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSingleStyleTransferProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTGLPixelFormat.h>
#import <LTEngine/LTOpenCVExtensions.h>

NS_ASSUME_NONNULL_BEGIN

/// Supported CVPixelFormat types for input images and their corresponding Metal pixel types for
/// mapping of the \c CVPixelBuffer to a \c MTLTexture.
static const std::unordered_map<OSType, MTLPixelFormat> kSupportedCVPixelFormatToMTLPixelFormat{
  {kCVPixelFormatType_OneComponent8, MTLPixelFormatR8Unorm},
  {kCVPixelFormatType_32BGRA, MTLPixelFormatBGRA8Unorm},
  {kCVPixelFormatType_OneComponent16Half, MTLPixelFormatR16Float},
  {kCVPixelFormatType_64RGBAHalf, MTLPixelFormatRGBA16Float}
};

@interface PNKSingleStyleTransferProcessor ()

/// URL of the model file defining the parameters of the stylization network.
@property (readonly, nonatomic) NSURL *modelURL;

@end

@implementation PNKSingleStyleTransferProcessor

- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _modelURL = modelURL;
    _stylizedOutputSize = CGSizeMake(256, 256);
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
- (lt::Ref<CVPixelBufferRef>)stylizeWithInput:(CVPixelBufferRef)input {
  LTParameterAssert(input);
  OSType inputFormat = CVPixelBufferGetPixelFormatType(input);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(inputFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Input pixel format (%u) is not supported", (unsigned int)inputFormat);

  auto outputBuffer = LTCVPixelBufferCreate(self.stylizedOutputSize.width,
                                            self.stylizedOutputSize.height,
                                            kCVPixelFormatType_32BGRA);
  LTCVPixelBufferImageForWriting(outputBuffer.get(), ^(cv::Mat *outputMat) {
    LTCVPixelBufferImageForReading(input, ^(const cv::Mat &inputMat) {
      if (inputMat.channels() == 1) {
        cv::Mat intermediateMat;
        cv::resize(inputMat, intermediateMat, outputMat->size());
        cv::cvtColor(intermediateMat, *outputMat, CV_GRAY2RGBA);
      } else {
        cv::resize(inputMat, *outputMat, outputMat->size());
      }
    });
    cv::cvtColor(*outputMat, *outputMat, CV_RGBA2BGRA);
  });
  return outputBuffer;
}

@end

NS_ASSUME_NONNULL_END
