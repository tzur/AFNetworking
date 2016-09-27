// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMVideoFrame+Factory.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>

#import "CAMSampleBufferMetadataUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMVideoFrame (Factory)

+ (instancetype)videoFrameWithPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer
                  withPropertiesFromFrame:(CAMVideoFrame *)otherFrame {
  @autoreleasepool {
    CMVideoFormatDescriptionRef videoFormat;
    CVReturn videoFormatCreate = CMVideoFormatDescriptionCreateForImageBuffer(NULL,
                                                                              pixelBuffer.get(),
                                                                              &videoFormat);
    LTAssert(videoFormatCreate == kCVReturnSuccess,
             @"Video format creation failed with code %d", videoFormatCreate);
    lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef(videoFormat);

    CMSampleBufferRef sampleBuffer;
    CMSampleTimingInfo timingInfo = [otherFrame timingInfo];
    OSStatus sampleBufferCreate = CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                                                           pixelBuffer.get(),
                                                                           videoFormat,
                                                                           &timingInfo,
                                                                           &sampleBuffer);
    LTAssert(sampleBufferCreate == 0,
             @"CMSampleBuffer creation failed with code %d", (int)sampleBufferCreate);
    lt::Ref<CMSampleBufferRef> sampleBufferRef(sampleBuffer);

    CAMCopyPropagatableMetadata([otherFrame sampleBuffer].get(), sampleBuffer);

    return [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer];
  }
}

@end

NS_ASSUME_NONNULL_END
