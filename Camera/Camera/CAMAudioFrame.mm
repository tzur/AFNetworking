// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CAMAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMAudioFrame {
  /// Backing sample buffer.
  lt::Ref<CMSampleBufferRef> _sampleBuffer;
}

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  LTParameterAssert(sampleBuffer);
  if (self = [super init]) {
    _sampleBuffer = lt::Ref<CMSampleBufferRef>::retain(sampleBuffer);
  }
  return self;
}

- (lt::Ref<CMSampleBufferRef>)sampleBuffer {
  return lt::Ref<CMSampleBufferRef>::retain(_sampleBuffer.get());
}

- (CMSampleTimingInfo)timingInfo {
  CMSampleTimingInfo timingInfo;
  OSStatus status = CMSampleBufferGetSampleTimingInfo(_sampleBuffer.get(), 0, &timingInfo);
  LTAssert(status == 0, @"Failed to retrieve sample timing, status: %d", (int)status);
  return timingInfo;
}

@end

NS_ASSUME_NONNULL_END
