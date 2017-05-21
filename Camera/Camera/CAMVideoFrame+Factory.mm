// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMVideoFrame+Factory.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>

#import "CAMSampleBufferMetadataUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMVideoFrame (Factory)

+ (instancetype)videoFrameWithPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer
                  withPropertiesFromFrame:(CAMVideoFrame *)otherFrame {
    CMSampleTimingInfo timingInfo = [otherFrame timingInfo];

    NSDictionary * _Nullable propagatableMetadata =
        CAMGetPropagatableMetadata([otherFrame sampleBuffer].get());

    return [self videoFrameWithPixelBuffer:std::move(pixelBuffer)
                            withTimingInfo:timingInfo
                  withPropagatableMetadata:propagatableMetadata];
}

+ (instancetype)videoFrameWithPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer
                           withTimingInfo:(CMSampleTimingInfo)timingInfo
                 withPropagatableMetadata:(nullable NSDictionary *)propagatableMetadata {
  @autoreleasepool {
    CMVideoFormatDescriptionRef videoFormat;
    CVReturn videoFormatCreate = CMVideoFormatDescriptionCreateForImageBuffer(NULL,
                                                                              pixelBuffer.get(),
                                                                              &videoFormat);

    LTAssert(videoFormatCreate == kCVReturnSuccess,
             @"Video format creation failed with code %d", videoFormatCreate);
    lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef(videoFormat);
    CMSampleBufferRef sampleBuffer;
    OSStatus sampleBufferCreate = CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                                                           pixelBuffer.get(),
                                                                           videoFormat,
                                                                           &timingInfo,
                                                                           &sampleBuffer);
    LTAssert(sampleBufferCreate == 0,
             @"CMSampleBuffer creation failed with code %d", (int)sampleBufferCreate);
    lt::Ref<CMSampleBufferRef> sampleBufferRef(sampleBuffer);

    if (propagatableMetadata != nil) {
      CAMSetPropagatableMetadata(sampleBuffer, propagatableMetadata);
    }

    return [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer];
  }
}

+ (instancetype)videoFrameWithVideoFrame:(CAMVideoFrame *)sourceFrame {
  CVPixelBufferRef sourceBuffer = sourceFrame.pixelBuffer.get();
  OSType pixelFormatType = CVPixelBufferGetPixelFormatType(sourceBuffer);
  lt::Ref<CVPixelBufferRef> destinationBufferRef =
      LTCVPixelBufferCreate(sourceFrame.size.width, sourceFrame.size.height, pixelFormatType);
  CVPixelBufferRef destinationBuffer = destinationBufferRef.get();

  LTCVPixelBufferImagesForReading(sourceBuffer, ^(const Matrices &sourcePlanes) {
    LTCVPixelBufferImagesForWriting(destinationBuffer, ^(const Matrices &destinationPlanes) {
      for (size_t i = 0; i < std::min(sourcePlanes.size(), destinationPlanes.size()); ++i) {
        LTAssert(sourcePlanes[i].size == destinationPlanes[i].size, @"Source plane size (%d, %d) "
                 "differs from destination plane size (%d, %d)", sourcePlanes[i].cols,
                 sourcePlanes[i].rows, destinationPlanes[i].cols, destinationPlanes[i].rows);
        sourcePlanes[i].copyTo(destinationPlanes[i]);
      }
    });
  });

  return [self videoFrameWithPixelBuffer:std::move(destinationBufferRef)
                 withPropertiesFromFrame:sourceFrame];
}

@end

NS_ASSUME_NONNULL_END
