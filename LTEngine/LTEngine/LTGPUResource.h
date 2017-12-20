// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTTypedefs.h>

@class LTGLContext;

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
- (void)bindAndExecute:(NS_NOESCAPE LTVoidBlock)block;

/// Disposes the resource immediately and sets the \c name to \c 0.
///
/// This method must be called when the context that created the resource is bound. After calling
/// this method any responses or side effects caused by messages sent to this object are considered
/// undefined behavior.
///
/// A common usage of this method is to enforce relinquishing to resource before this object is
/// deallocated, since it's usually impossible to precisely control the lifetime of an ObjC object.
///
/// Any subsequent calls to this method will be ignored.
///
/// @important this method allows manual management of the GPU resource lifetime, which should
/// normally be avoided. It leaves the object in a "half-dead" and mostly unusable state, which can
/// easily result in hard to detect use-after-dispose bugs. Always prefer automatic dispose, where
/// the system guaranties that the disposal occurs only after the resource can no longer be used,
/// and on the correct context.
- (void)dispose;

/// OpenGL name of the resource.
@property (readonly, nonatomic) GLuint name;

/// The context that was used to create this resource.
///
/// @note \c context is held strongly by the resource, which prevents it from being deallocated
/// while the resource is still alive.
@property (readonly, nonatomic) LTGLContext *context;

@end
