// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGPUResource.h"

/// Abstract class for encapsulating an OpenGL framebuffer.
@interface LTFbo : NSObject <LTGPUResource>

/// Initialize the framebuffer object with the given framebuffer identifier, size and viewport to
/// use when binding it.
- (instancetype)initWithFramebufferIdentifier:(GLuint)identifier size:(CGSize)size
                                     viewport:(CGRect)viewport;

/// Executes the given block while the receiver is bound to the active context, while locking the
/// framebuffer's texture when the block is executed. If the receiver is not already bound, this
/// will automatically \c bind and \c unbind the receiver before and after the block, accordingly.
/// If the receiver is bound, the block will execute, but no binding and unbinding will be executed.
/// Making recursive calls to \c bindAndDraw: is possible without loss of context.
///
/// @note use this method when drawing into the framebuffer's texture, instead of \c
/// bindAndExecute:.
///
/// @param block The block to execute after binding the resource. This parameter cannot be nil.
- (void)bindAndDraw:(LTVoidBlock)block;

/// Fills the texture bound to this FBO with the given color.
- (void)clearWithColor:(GLKVector4)color;

/// Size of the framebuffer, in pixels.
@property (readonly, nonatomic) CGSize size;

@end
