// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotImageProcessor.h"

@interface LTOneShotImageProcessor (Protected)

/// Returns the source rectangle that should be used when processing an output directly to screen.
- (CGRect)sourceRectForFramebufferSize:(CGSize)framebufferSize outputRect:(CGRect)rect
                     sourceTextureSize:(CGSize)size;

/// Returns the target rectangle that should be used when processing an output directly to screen.
- (CGRect)targetRectForFramebufferSize:(CGSize)framebufferSize outputRect:(CGRect)rect
               originalFramebufferSize:(CGSize)originalFramebufferSize;

@end
