// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Wrapper for OpenEXR PIZ lossless compression algorithm for 16-bit RGBA images (CV_16FC4).
@interface LTOpenExrPizCompressor : NSObject

/// Compresses the given \c image to the given \c path. The \c image must be of type \c CV_16FC4.
/// After the operation completes, \c YES is returned. On error, \c error is populated and \c NO is
/// returned.
- (BOOL)compressImage:(const cv::Mat &)image toPath:(NSString *)path error:(NSError **)error;

/// Decompresses the OpenEXR PIZ data in the given \c path to \c image matrix, which must be of type
/// \c CV_16FC4 and of the same dimensions as the decompressed image. After the operation completes,
/// \c YES is returned. On error, \c error is populated and \c NO is returned.
- (BOOL)decompressFromPath:(NSString *)path toImage:(cv::Mat *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
