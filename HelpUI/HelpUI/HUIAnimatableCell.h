// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

/// Protocol for controlling animations of help cells.
@protocol HUIAnimatableCell <NSObject>

/// Called when the cell should start its animation.
- (void)startAnimation;

/// Called when the cell should stop its animation.
- (void)stopAnimation;

@end
