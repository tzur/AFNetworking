// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for convenient retrieval of the size of an \c MPSImage.
@interface MPSImage (Size)

/// Returns the size of the image with \c depth being the \c featureChannels property of the image.
- (MTLSize)pnk_size;

@end

#endif

NS_ASSUME_NONNULL_END
