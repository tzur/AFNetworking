// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTProcessingDrawer.h"

/// Uniform name of the source texture, which must be contained in each rect drawer program.
extern NSString * const kSourceTextureUniform;

/// @class LTTextureDrawer
///
/// Abstract class for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, an operation which is very common when using programs to perform image
/// processing operations.
@interface LTTextureDrawer : NSObject <LTProcessingDrawer>

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c setUniform:withValue:.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the underlying program's uniform value, or throws an exception if the given \c key is
/// not a valid one.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Set of mandatory uniforms that must exist in the given program.
@property (readonly, nonatomic) NSSet *mandatoryUniforms;

@end
