// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTTexture, LTTextureFbo;

/// DTO for specifying the next source texture and target framebuffer for the next iteration.
@interface LTNextIterationPlacement : NSObject

/// Initialize a new iteration placement with a source texture and a target framebuffer.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                         andTargetFbo:(LTTextureFbo *)targetFbo;

/// The source texture to use in the next iteration.
@property (readonly, nonatomic) LTTexture *sourceTexture;

/// The target framebuffer to draw to in the next iteration.
@property (readonly, nonatomic) LTTextureFbo *targetFbo;

@end
