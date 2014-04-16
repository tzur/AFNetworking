// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Degenerate processor for copying an input texture to an output texture. The output size can be
/// different than the input size, which will yield a (possibly non-uniformly) resized output.
@interface LTPassthroughProcessor : LTOneShotImageProcessor

/// Initializes a passthrough processor with an input texture and a corresponding output texture.
/// Note that in constrast to \c -[LTTexture clone] and \c -[LTTexture cloneTo:], the input and
/// output textures can be of different size.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
