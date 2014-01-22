// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProcessingDrawer.h"

/// @class LTRectDrawer
///
/// Class for drawing rectangular regions from a source texture into a rectangular region of a
/// target framebuffer, an operation which is very common when using programs to perform image
/// processing operations.
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
