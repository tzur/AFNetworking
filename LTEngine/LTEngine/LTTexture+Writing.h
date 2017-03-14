// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboWritableAttachment.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Class extension that adds the private protocol \c LTFboWritableAttachment over
/// \c LTTexture.
@interface LTTexture (Writing) <LTFboWritableAttachment>

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

/// Marks the beginning of a GPU write operation to the texture.
///
/// @note for automatic scoping, prefer calls to \c writeToAttachmentWithBlock: instead of calling
/// \c beginWritingWithGPU and \c endWritingWithGPU.
///
/// @see \c writeToAttachmentWithBlock: for more information.
- (void)beginWritingWithGPU;

/// Marks the end of a GPU write operation to the texture.
///
/// @note for automatic scoping, prefer calls to \c writeToAttachmentWithBlock: instead of calling
/// \c beginWritingWithGPU and \c endWritingWithGPU.
///
/// @see \c writeToAttachmentWithBlock: for more information.
- (void)endWritingWithGPU;

@end

NS_ASSUME_NONNULL_END
