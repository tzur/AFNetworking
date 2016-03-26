// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBaseArchiver.h"

NS_ASSUME_NONNULL_BEGIN

/// Archiver that can be used for saving textures as jpeg files. This archiver supports only
/// textures with \c LTGLPixelBitDepth8 \c bitDepth, with \c usingAlphaChannel of \c NO.
@interface LTTextureJpegArchiver : NSObject <LTTextureBaseArchiver>
@end

NS_ASSUME_NONNULL_END
