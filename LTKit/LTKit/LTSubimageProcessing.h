// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Protocol for producing a partial output image, in contrast to the \c -[LTImageProcessor process]
/// method which produces the entire output.
@protocol LTSubimageProcessing <NSObject>

/// Generates an output for the \c rect given in output coordinates, and renders it to the entire
/// framebuffer with the given \c size. To make sure only uniform scaling is being done while
/// drawing to the framebuffer, verify that \c rect is uniformly scaled from the normal output
/// texture. The framebuffer is assumed to be already bound when this method is called. This method
/// blocks until a result is available.
- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect;

/// Processes and modifies the output texture in the given \c rect only. This method blocks until a
/// result is available.
- (void)processInRect:(CGRect)rect;

@end
