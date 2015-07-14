// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTGLView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTGLContextGuard
#pragma mark -

/// Guards a given OpenGL context, preventing it from being deallocated. When the guard object is
/// deallocated it sets the current GL context to be the guarded context.
@interface LTGLContextGuard : NSObject

/// Creates and returns a new context guard for current OpenGL context.
+ (instancetype)contextGuardForCurrentContext;

/// OpenGL context to guard.
@property (readonly, nonatomic, nullable) EAGLContext *guardedContext;

@end

@implementation LTGLContextGuard

+ (instancetype)contextGuardForCurrentContext {
  return [[self alloc] initWithContext:[EAGLContext currentContext]];
}

- (instancetype)initWithContext:(nullable EAGLContext *)context {
  if (self = [super init]) {
    _guardedContext = context;
  }
  return self;
}

- (void)dealloc {
  [EAGLContext setCurrentContext:self.guardedContext];
}

@end

#pragma mark -
#pragma mark LTGLView
#pragma mark -

@implementation LTGLView

/// Since \c GLKView -dealloc sets OpenGL context to \c nil, the context have to be restored during
/// the deallocation process but only after the \c GLKView -dealloc finished. Associated objects are
/// deallocated quite late in the deallocation process, specifically after \c NSObject -dealloc.
/// Thus associating an \c LTGLContextGuard promises that it will be deallocated after the
/// deallocation of the \c GLKView and when deallocation completes the OpenGL context will be the
/// same context used before the deallocation.
///
/// @see http://stackoverflow.com/questions/10842829/will-an-associated-object-be-released-automatically
- (void)dealloc {
  [self associateContextGuard];
}

- (void)associateContextGuard {
  LTGLContextGuard *contextGuard = [LTGLContextGuard contextGuardForCurrentContext];
  objc_setAssociatedObject(self, @selector(associateContextGuard), contextGuard,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NS_ASSUME_NONNULL_END
