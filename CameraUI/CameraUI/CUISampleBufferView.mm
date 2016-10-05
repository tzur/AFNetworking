// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CUISampleBufferView.h"

#import <AVFoundation/AVFoundation.h>
#import <Camera/CAMVideoFrame.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUISampleBufferView ()

/// Underlying display layer.
@property (readonly, nonatomic) AVSampleBufferDisplayLayer *layer;

@end

@implementation CUISampleBufferView

@dynamic layer;

- (instancetype)initWithVideoFrames:(RACSignal *)framesSignal {
  if (self = [super initWithFrame:CGRectZero]) {
    @weakify(self);
    [[framesSignal
        takeUntil:[self rac_willDeallocSignal]]
        subscribeNext:^(CAMVideoFrame *frame) {
          @strongify(self);
          if (self.layer.error) {
            [self.layer flush];
          }
          [self.layer enqueueSampleBuffer:[frame sampleBuffer].get()];
        }];
  }
  return self;
}

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

@end

NS_ASSUME_NONNULL_END
