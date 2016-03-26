// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageCompression.h"

NS_ASSUME_NONNULL_BEGIN

/// Applies compression on input images using the ImageIO framework. Allows specifying the 
/// compression format by specifying the \c UTI. It also allows parameterization of the compression
/// via \c options dictionary.
@interface LTImageIOCompressor : NSObject <LTImageCompression>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new \c LTImageIOCompressor with compression \c options and \c UTI, which specifies
/// the output compression format. The \c options an optional dictionary which is passed to
/// ImageIO \c CGImageDestinationAddImage or \c CGImageDestinationAddImageFromSource to effect the
/// output, such as image compression quality.
- (instancetype)initWithOptions:(nullable NSDictionary *)options UTI:(CFStringRef)UTI
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
