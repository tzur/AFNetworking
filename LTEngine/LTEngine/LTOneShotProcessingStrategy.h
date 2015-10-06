// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

/// A one shot processing strategy, used when a single iteration on an image is suffice to produce
/// an output.
@interface LTOneShotProcessingStrategy : NSObject <LTProcessingStrategy>

/// Initializes with a single input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input andOutput:(LTTexture *)output;

@end
