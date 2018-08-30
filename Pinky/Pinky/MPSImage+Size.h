// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Category for convenient retrieval of the size of an \c MPSImage.
@interface MPSImage (Size)

/// Returns the size of the image with \c depth being the \c featureChannels property of the image.
- (MTLSize)pnk_size;

/// Returns the value of \c arrayLength property of the image's texture. Does not actually access
/// the \c texture property
- (NSUInteger)pnk_textureArrayDepth;

/// Returns \c YES iff <tt>pnk_textureArrayDepth > 1 </tt>
- (BOOL)pnk_isTextureArray;

/// Returns \c YES iff <tt>pnk_textureArrayDepth <= 1 </tt>
- (BOOL)pnk_isSingleTexture;

/// Returns the size of the image with \c depth being the value of \c pnk_textureArrayDepth.
- (MTLSize)pnk_textureArraySize;

@end

NS_ASSUME_NONNULL_END
