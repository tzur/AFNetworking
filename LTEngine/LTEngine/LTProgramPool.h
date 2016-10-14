// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class LTProgram;

/// Represents a pool of OpenGL programs. The pool is responsible for creating new program names,
/// recycling them and destroying them when it deallocates. Recycling an existing program can be
/// used to avoid redundant recompilations and linkages.
///
/// @note the pool has an unlimited size, and because the created programs are destroyed only when
/// the pool deallocates the number of active programs is unbounded.
///
/// @important this pool is not thread safe.
@interface LTProgramPool : NSObject

/// Pool associated with the current \c LTGLContext or \c nil if no \c LTGLContext is associated
/// with the current thread.
+ (nullable instancetype)currentPool;

/// Deletes all the program names that are held by this pool.
- (void)flush;

/// Returns a name of a program with the given \c identifier. If such program is not available in
/// the pool, a new program is created and returned. If a matching program is available in the pool,
/// its state is reset, it is removed from the pool and then it is returned.
- (GLuint)nameForIdentifier:(NSString *)identifier;

/// Returns the program with the given \c name and \c identifier back to the pool. After this method
/// returns the program must not be used anymore, as it may be returned to a different client in the
/// future.
- (void)recycleName:(GLuint)name withIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
