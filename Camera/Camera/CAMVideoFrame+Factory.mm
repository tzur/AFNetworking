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

@end

NS_ASSUME_NONNULL_END
