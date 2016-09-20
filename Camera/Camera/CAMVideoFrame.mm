// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTGLContext.h>
#import <LTEngine/LTTexture+Factory.h>

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMVideoFrame {
  /// Backing sample buffer.
  lt::Ref<CMSampleBufferRef> _sampleBuffer;
}

/// Dictionary mapping supported pixel buffer formats to their respective \c CAMPixelFormat.
static NSDictionary * const kCVPixelFormatToCAMPixelFormat = @{
  @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange): $(CAMPixelFormat420f),
  @(kCVPixelFormatType_32BGRA): $(CAMPixelFormatBGRA)
};

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  LTParameterAssert(sampleBuffer);
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  LTParameterAssert(pixelBuffer, @"sampleBuffer does not contain an image buffer");
  OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  LTParameterAssert([kCVPixelFormatToCAMPixelFormat.allKeys containsObject:@(pixelFormat)],
      @"sampleBuffer's image buffer has an unsupported pixel format: %d", (int)pixelFormat);
  if (self = [super init]) {
    _sampleBuffer = lt::Ref<CMSampleBufferRef>((CMSampleBufferRef)CFRetain(sampleBuffer));
  }
  return self;
}

- (lt::Ref<CMSampleBufferRef>)sampleBuffer {
  return lt::Ref<CMSampleBufferRef>((CMSampleBufferRef)CFRetain(_sampleBuffer.get()));
}

- (lt::Ref<CVPixelBufferRef>)pixelBuffer {
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer.get());
  return lt::Ref<CVPixelBufferRef>(CVPixelBufferRetain(pixelBuffer));
}

- (UIImage *)image {
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer.get());

  CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
  CIContext *context = [CIContext contextWithOptions:nil];
  CGSize size = CVImageBufferGetDisplaySize(pixelBuffer);
  lt::Ref<CGImageRef> cgImage([context createCGImage:ciImage fromRect:CGRectFromSize(size)]);

  return [UIImage imageWithCGImage:cgImage.get()];
}

- (LTTexture *)textureAtPlaneIndex:(NSUInteger)planeIndex {
  LTAssert([LTGLContext currentContext]);

  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer.get());
  LTParameterAssert(planeIndex == 0 || planeIndex < CVPixelBufferGetPlaneCount(pixelBuffer));

  if (CVPixelBufferIsPlanar(pixelBuffer)) {
    return [LTTexture textureWithPixelBuffer:pixelBuffer planeIndex:planeIndex];
  } else {
    return [LTTexture textureWithPixelBuffer:pixelBuffer];
  }
}

- (CMSampleTimingInfo)timingInfo {
  CMSampleTimingInfo timingInfo;
  OSStatus status = CMSampleBufferGetSampleTimingInfo(_sampleBuffer.get(), 0, &timingInfo);
  LTAssert(status == 0, @"Failed to retrieve sample timing, status: %d", (int)status);
  return timingInfo;
}

- (int)exifOrientation {
  NSNumber *orientation = (__bridge NSNumber *)CMGetAttachment(_sampleBuffer.get(),
                                                               (__bridge CFStringRef)@"Orientation",
                                                               NULL);
  return [orientation intValue];
}

- (CAMPixelFormat *)pixelFormat {
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer.get());
  OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  return kCVPixelFormatToCAMPixelFormat[@(pixelFormat)];
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (NSString *)debugDescription {
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer.get());
  size_t width = CVPixelBufferGetWidth(pixelBuffer);
  size_t height = CVPixelBufferGetHeight(pixelBuffer);
  return [NSString stringWithFormat:@"<%@: %p, pixelFormat: %@, size: %@>", [self class], self,
          self.pixelFormat.name, NSStringFromCGSize(CGSizeMake(width, height))];
}

- (id)debugQuickLookObject {
  return [self image];
}

@end

NS_ASSUME_NONNULL_END
