// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// View that receives a signal of \c CAMVideoFrames and displays the underlying \c CMSampleBuffers.
@interface CUISampleBufferView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/// Initializes with the signal of the \c CAMVideoFrame's to display.
- (instancetype)initWithVideoFrames:(RACSignal *)framesSignal;

@end

NS_ASSUME_NONNULL_END
