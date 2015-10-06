// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSingleQuadDrawer.h"
#import "LTTextureDrawer.h"

/// Class for drawing a quadrilateral region from a source texture into a quadrilateral region of a
/// target framebuffer.
@interface LTQuadDrawer : NSObject <LTSingleQuadDrawer, LTTextureDrawer>
@end
