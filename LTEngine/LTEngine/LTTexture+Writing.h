// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboAttachable.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Class extension that adds the private protocol \c LTFboWritableAttachable over
/// \c LTTexture.
@interface LTTexture (Writing)

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

/// Marks the beginning of a GPU write operation to the texture.
///
/// @note for automatic scoping, prefer calls to \c writeToAttachableWithBlock: instead of calling
/// \c beginWritingWithGPU and \c endWritingWithGPU.
///
/// @see \c writeToAttachableWithBlock: for more information.
- (void)beginWritingWithGPU;

/// Marks the end of a GPU write operation to the texture.
///
/// @note for automatic scoping, prefer calls to \c writeToAttachableWithBlock: instead of calling
/// \c beginWritingWithGPU and \c endWritingWithGPU.
///
/// @see \c writeToAttachableWithBlock: for more information.
- (void)endWritingWithGPU;

@end

NS_ASSUME_NONNULL_END
