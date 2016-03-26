// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureBaseArchiver.h"

NS_ASSUME_NONNULL_BEGIN

/// Archiver that can be used for saving textures as ImageZero files. This archiver supports only
/// textures with pixel format of \c LTGLPixelFormatR8Unorm and \c LTGLPixelFormatRGBA8Unorm, with
/// \c usingAlphaChannel of \c NO.
@interface LTTextureIZArchiver : NSObject <LTTextureBaseArchiver>
@end

NS_ASSUME_NONNULL_END
