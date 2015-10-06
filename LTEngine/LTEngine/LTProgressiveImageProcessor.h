// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTImageProcessor.h"

/// Abstract image processor for progressive image processing tasks. This processor is built to
/// process progressively according to its \c targetProgress property. This allows animating the
/// output, as its being processed, for both UX and performance reasons.
@interface LTProgressiveImageProcessor : LTImageProcessor

/// Resets the processor's progress, setting both \c processedProgress and \c targetProgress to
/// \c 0.
- (void)resetProgress;

/// Size of the canvas texture.
@property (readonly, nonatomic) CGSize canvasSize;

/// Indicates how much of the processing was already completed, in range [0,1].
@property (readonly, nonatomic) double processedProgress;

/// Indicates how much processing should be done in the next call to \c process. Must be in range
/// [0,1], and greater or equal than \c processedProgress.
@property (nonatomic) double targetProgress;
LTPropertyDeclare(double, targetProgress, TargetProgress);

@end
