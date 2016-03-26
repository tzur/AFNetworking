// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Protocol for producing a partial output image, in contrast to the \c -[LTImageProcessor process]
/// method which produces the entire output.
@protocol LTPartialProcessing <NSObject>

/// Processes and modifies the output texture in the given \c rect only. This method blocks until a
/// result is available.
- (void)processInRect:(CGRect)rect;

@end
