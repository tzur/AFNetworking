// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CAMAudioFrame.h"

#import <AVFoundation/AVFoundation.h>

#import "CAMSampleTimingInfo.h"
#import "CAMTestUtils.h"

SpecBegin(CAMAudioFrame)

__block CMSampleTimingInfo sampleTiming;
__block CAMAudioFrame *frame;
__block lt::Ref<CMSampleBufferRef> sampleBuffer;

beforeEach(^{
  sampleTiming = {
    .duration= CMTimeMake(1, 44100),
    .presentationTimeStamp= kCMTimeZero,
    .decodeTimeStamp= kCMTimeInvalid
  };
  sampleBuffer = CAMCreateEmptyAudioSampleBuffer(sampleTiming);
  frame = [[CAMAudioFrame alloc] initWithSampleBuffer:sampleBuffer.get()];
});

context(@"initialization and basic properties", ^{
  it(@"should initialize correctly", ^{
    expect([frame sampleBuffer].get()).to.equal(sampleBuffer.get());
  });

  it(@"should retain sample buffer and release after dealloc", ^{
    lt::Ref<CMSampleBufferRef> localSampleBuffer = CAMCreateEmptyAudioSampleBuffer(sampleTiming);
    CMSampleBufferRef sampleBufferRef = localSampleBuffer.get();
    NSInteger initialRetainCount = CFGetRetainCount(sampleBufferRef);
    @autoreleasepool {
      CAMAudioFrame * __unused anotherFrame =
          [[CAMAudioFrame alloc] initWithSampleBuffer:sampleBufferRef];
      expect(CFGetRetainCount(sampleBufferRef)).to.beGreaterThan(initialRetainCount);
    }
    expect(CFGetRetainCount(sampleBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should not retain sample buffer after returned lt::Ref is released", ^{
    CMSampleBufferRef sampleBufferRef = sampleBuffer.get();
    NSInteger initialRetainCount = CFGetRetainCount(sampleBufferRef);

    lt::Ref<CMSampleBufferRef> sampleBufferLTRef = [frame sampleBuffer];
    sampleBufferLTRef.reset(nullptr);

    expect(CFGetRetainCount(sampleBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should return timing info", ^{
    expect(CAMSampleTimingInfoIsEqual([frame timingInfo], sampleTiming)).to.beTruthy();
  });
});

SpecEnd
