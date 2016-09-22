// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@class LTGLPixelFormat;

/// Category for creating \c CIContext based on given pixel formats.
@interface CIContext (PixelFormat)

/// Returns a \c CIContext without a specific rendering destination, with no color management for
/// both the output image and intermediate results (both \c kCIContextOutputColorSpace and
/// \c kCIContextWorkingColorSpace are mapped to \c [NSNull null]) and with working format
/// based on the given \c pixelFormat (\c kCIContextWorkingFormat will be either \c kCIFormatRGBA8
/// or \c kCIFormatRGBAh according to its bit depth and data type).
///
/// Returned contexts are cached in the thread local storage with the creation options as key.
/// Therefore, requesting a context on the same thread for the same \c pixelFormat twice will only
/// create a single context.
///
/// @note Supported pixel format must have either \c LTGLPixelBitDepth8 and
/// \c LTGLPixelDataTypeUnorm or \c LTGLPixelBitDepth16 and \c LTGLPixelDataTypeFloat. Will raise an
/// exception otherwise.
+ (instancetype)lt_contextWithPixelFormat:(LTGLPixelFormat *)pixelFormat;

/// Cleans the context cache of the current thread.
+ (void)lt_cleanContextCache;

@end

NS_ASSUME_NONNULL_END
