// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTGLContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTGPUResource;

/// Category adding managing functionality of \c LTGPUResource objects. \c LTGLContext maintains a
/// set of weak references to \c LTGPUResource objects.
///
/// @note Two \c LTGPUResource objects are considered to be same object if they have same
/// \c LTGPUResource.name and are of the same concrete \c class.
@interface LTGLContext (Internal)

/// Adds a weak reference of the given \c resource to this instance resource tracking table. If a
/// resource exists (with the same \c LTGPUResource.name and of the same \c LTGPUResource.class) it
/// will be replaced by the given \c resource.
- (void)addResource:(id<LTGPUResource>)resource;

/// Removes the given \c resource if exists, otherwise does nothing.
- (void)removeResource:(id<LTGPUResource>)resource;

@end

NS_ASSUME_NONNULL_END
