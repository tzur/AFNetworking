// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <opencv2/core/core.hpp>

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the ImageZero lossless compression algorithm, including a proprietary file
/// format which is not defined in the original implementation. The implementation of ImageZero is
/// multithreaded when possible for maximal performance and stores each compressed image in a number
/// of shards (similar to archive formats such as RAR). This allows ImageZero to be amazingly fast
/// (x2.8 faster than JPEG compression on average on iPhone 6+) while keeping the file size sane
/// (only 40% larger than JPEG) and the pixel data lossless.
///
/// The file format contains a header, which defines the current version, total image size and
/// current shard size and index, followed by the ImageZero compressed data. The compressed data and
/// the header, besides specific documented fields, are stored in little endian format. Each pixel's
/// value is predicted using its top, left and top-left neighbours (when available), and only the
/// difference between the predictor and the actual value is stored. The bit length of each pixel is
/// encoded using a static Huffman table.
///
/// @important current implementation only supports R8 and RGBA8 images, without transparency. The
/// alpha channel will not be compressed and the descompressed images will contain an opaque alpha
/// channel.
///
/// @important this file format is intended for internal app use only. Header and data abuse may
/// cause decompression code to corrupt memory and/or to crash.
///
/// @see http://imagezero.maxiom.de/ and https://github.com/cfeck/imagezero for more information and
/// the original implementation.
@interface LTIZCompressor : NSObject

/// Compresses the given \c image to the given \c path and returns \c YES. On error, \c error is
/// populated.
///
/// @important image must be of type \c CV_8UC1 or \c CV_8UC4. For \c CV_8UC4, the ImageZero file
/// format currently does not support alpha channels. Therefore, its data won't be stored to disk.
///
/// @important image width and height cannot be larger than 2^16 - 1.
- (BOOL)compressImage:(const cv::Mat &)image toPath:(NSString *)path error:(NSError **)error;

/// Decompresses the ImageZero data in the given \c path to \c image matrix, which must have the
/// same dimensions of the decompressed image. After the operation completes, \c YES is returned.
/// On error, \c error is populated and \c NO is returned.
///
/// @important \c image must be of type \c CV_8UC1 or \c CV_8UC4. For \c CV_8UC4, the ImageZero file
/// format currently does not support alpha channels. Therefore, the returned image will have a
/// constant opaque alpha channel.
- (BOOL)decompressFromPath:(NSString *)path toImage:(cv::Mat *)image error:(NSError **)error;

/// Array of \c NSString paths to all the shards of the given image. The given \c path must point to
/// the first shard. On error, \c error will be populated and \c nil will be returned.
- (nullable NSArray *)shardsPathsOfCompressedImageFromPath:(NSString *)path error:(NSError **)error;

/// Maximal compressed ImageZero file size for the given \c image, which must be of type \c CV_8UC1
/// or \c CV_8UC4.
+ (size_t)maximalCompressedSizeForImage:(const cv::Mat &)image;

@end

NS_ASSUME_NONNULL_END
