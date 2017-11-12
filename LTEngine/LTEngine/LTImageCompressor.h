// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

NS_ASSUME_NONNULL_BEGIN

@class LTCompressionFormat;

/// Implemented by objects that perform image compression on \c UIImage and return \c NSData or
/// write the results directly to file.
@protocol LTImageCompressor <NSObject>

/// Compresses \c image and adds \c metadata to the resulting \c NSData. On error, \c nil will be
/// returned and \c error will be set. \c metadata will only be added to compression formats that
/// support it.
- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError **)error;

/// Compresses \c image and adds \c metadata, while writing the result to \c url. On error, \c nil
/// will be returned and \c error will be set. \c metadata will only be added to compression formats
/// that support it.
- (BOOL)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                toURL:(NSURL *)url error:(NSError **)error;

/// Compressor output format.
@property (readonly, nonatomic) LTCompressionFormat *format;

@end

NS_ASSUME_NONNULL_END
