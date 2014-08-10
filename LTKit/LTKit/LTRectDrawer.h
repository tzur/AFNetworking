// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMultiRectDrawer.h"
#import "LTProcessingDrawer.h"
#import "LTSingleRectDrawer.h"

@class LTRotatedRect;

/// Class for drawing rectangular regions from a source texture into a rectangular region of a
/// target framebuffer, optimzied for drawing both singe rects and an array of rects (using the
/// \c LTSingleRectDrawer and \c LTMultiRectDrawer classes.
@interface LTRectDrawer : NSObject <LTProcessingDrawer>

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c setUniform:withValue:.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the underlying program's uniform value, or throws an exception if the given \c key is
/// not a valid one.
- (id)objectForKeyedSubscript:(NSString *)key;

@end
