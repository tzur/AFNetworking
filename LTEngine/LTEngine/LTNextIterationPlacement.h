// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTFbo, LTTexture;

/// DTO for specifying the next source texture and target framebuffer for the next iteration.
@interface LTNextIterationPlacement : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize a new iteration placement with a source texture and a target framebuffer.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture andTargetFbo:(LTFbo *)targetFbo
    NS_DESIGNATED_INITIALIZER;

/// The source texture to use in the next iteration.
@property (readonly, nonatomic) LTTexture *sourceTexture;

/// The target framebuffer to draw to in the next iteration.
@property (readonly, nonatomic) LTFbo *targetFbo;

@end
