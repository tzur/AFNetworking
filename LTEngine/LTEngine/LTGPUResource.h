// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTTypedefs.h>

@protocol LTGPUResource <NSObject>

/// Binds the active context to the resource. Does nothing if the resource is already bound. Once
/// \c bind has been called, the matching \c unbind method must be called when the resource is no
/// longer needed for rendering.
- (void)bind;

/// Unbinds the resource from the currently active OpenGL context and binds the previously bound
/// resource instead. Does nothing if the resource is not bound.
- (void)unbind;

/// Executes the given \c block while the receiver is bound to the active context. If the receiver
/// is not bound yet, this will automatically \c bind and \c unbind the receiver before and after
/// the \c block, accordingly. If the receiver is bound, the \c block will execute, but no binding
/// and unbinding will be performed. Making recursive calls to \c bindAndExecute: is possible
/// without loss of context.
///
/// @param block The block to execute after binding the resource. Must not be \c nil.
- (void)bindAndExecute:(LTVoidBlock)block;

/// OpenGL name of the resource.
@property (readonly, nonatomic) GLuint name;

@end
