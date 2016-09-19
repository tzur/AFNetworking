// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CUISampleBufferView.h"

#import <Camera/CAMVideoFrame.h>

#import "CAMTestUtils.h"

SpecBegin(CUISampleBufferView)

context(@"dealloc", ^{
  it(@"should dealloc when Signal is still running", ^{
    CGSize size = CGSizeMake(3, 6);
    lt::Ref<CMSampleBufferRef> sampleBuffer = CAMCreateImageSampleBuffer(size);
    CAMVideoFrame *frame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];

    RACSubject *frames = [RACSubject subject];

    __weak CUISampleBufferView *weakView;

    @autoreleasepool {
      CUISampleBufferView *strongView = [[CUISampleBufferView alloc] initWithVideoFrames:frames];
      [frames sendNext:frame];
      weakView = strongView;
    }

    expect(weakView).to.beNil();
  });
});

context(@"subscription lifetime", ^{
  __block RACSignal *signal;
  __block RACSubject *subject;
  __block NSUInteger subscriptionCount;
  __block NSUInteger disposalCount;

  beforeEach(^{
    subject = [RACSubject subject];
    subscriptionCount = 0;
    disposalCount = 0;
    signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      subscriptionCount++;
      [subject subscribe:subscriber];
      return [RACDisposable disposableWithBlock:^{
        disposalCount++;
      }];
    }];
  });

  it(@"should unsubscribe when deallocing", ^{
    @autoreleasepool {
      CUISampleBufferView * __unused view = [[CUISampleBufferView alloc]
                                             initWithVideoFrames:signal];
      expect(subscriptionCount).to.equal(1);
    }
    expect(disposalCount).to.equal(1);
  });
});

SpecEnd
