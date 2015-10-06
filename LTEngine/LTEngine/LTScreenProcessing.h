// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Protocol for processing an output directly to screen, without writing to the designated output
/// texture. This is useful for real-time feedback where full processing is slow.
@protocol LTScreenProcessing <NSObject>

/// Generates an output for the \c rect given in output coordinates, and renders it to the entire
/// framebuffer with the given \c size. To make sure only uniform scaling is being done while
/// drawing to the framebuffer, verify that \c rect is uniformly scaled from the normal output
/// texture. The framebuffer is assumed to be already bound when this method is called. This method
/// blocks until a result is available.
- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect;

@end
