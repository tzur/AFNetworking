// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTTypedefs.h>

@protocol LTGPUResource <NSObject>

/// Binds the active context to the resource. If the texture is already bound, nothing will
/// happen. Once \c bind() is called, you must call the matching \c unbind() when the resource is no
/// longer needed for rendering.
- (void)bind;

/// Unbinds the texture from the current active OpenGL context and binds the previous program
/// instead. If the texture is not bound, nothing will happen.
- (void)unbind;

/// Executes the given block while the receiver is bound to the active context. If the receiver is
/// not already bound, this will automatically \c bind and \c unbind the receiver before and after
/// the block, accordingly. If the receiver is bound, the block will execute, but no binding and
/// unbinding will be executed. Making recursive calls to \c bindAndExecute: is possible without
/// loss of context.
///
/// @param block The block to execute after binding the resource. This parameter cannot be nil.
- (void)bindAndExecute:(LTVoidBlock)block;

/// OpenGL name of the resource.
@property (readonly, nonatomic) GLuint name;

@end
