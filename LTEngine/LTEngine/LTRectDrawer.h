// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMultiRectDrawer.h"
#import "LTTextureDrawer.h"
#import "LTSingleRectDrawer.h"

@class LTRotatedRect;

/// Class for drawing rectangular regions from a source texture into a rectangular region of a
/// target framebuffer, optimzied for drawing both singe rects and an array of rects (using the
/// \c LTSingleRectDrawer and \c LTMultiRectDrawer classes.
@interface LTRectDrawer : NSObject <LTMultiRectDrawer, LTSingleRectDrawer, LTTextureDrawer>
@end
