// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRectDrawer.h"

/// Category for initializing an \c LTRectDrawer with the passthrough shader, for drawing
/// unprocessed textures.
@interface LTRectDrawer (PassthroughShader)

/// Initializes with the passthrough shader and the given texture as the source texture.
- (instancetype)initWithSourceTexture:(LTTexture *)texture;

@end
