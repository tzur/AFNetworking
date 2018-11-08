// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Available compression types.
typedef NS_ENUM(NSUInteger, LTCompressionType) {
  /// LZFSE compression algorithm. Use when speed and compression ratio are equally important.
  ///
  /// @see COMPRESSION_LZFSE
  LTCompressionTypeLZFSE,
  /// LZ4 compression algorithm. Use when speed is more important than compression ratio.
  ///
  /// @see COMPRESSION_LZ4
  LTCompressionTypeLZ4,
  /// LZMA compression algorithm. Use when compression ratio is more important than speed.
  /// Compression is done at level 6. Decompression supports any compression level.
  ///
  /// @see COMPRESSION_LZMA
  LTCompressionTypeLZMA,
  /// ZLIB compression algorithm. Use when speed and compression ratio are equally important, and
  /// the format need to be decompressed with standard decompressors.
  /// Compression is done at level 5. Decompression supports any compression level.
  ///
  /// @see COMPRESSION_ZLIB
  LTCompressionTypeZLIB
};

/// Category that provides compression and decompression capabilities over \c NSData.
@interface NSData (Compression)

/// Compresses the receiver with the given \c compressionType. On successful compression, a mutable
/// data holding the compressed buffer is returned. If an error occurred while compressing, \c error
/// is populated with the \c LTErrorCodeCompressionFailed code and \c nil is returned.
///
/// @note a mutable container is returned for performance reasons. The returned object is not
/// retained nor modified by the receiver after this method returns.
- (nullable NSMutableData *)lt_compressWithCompressionType:(LTCompressionType)compressionType
                                                     error:(NSError *__autoreleasing *)error;

/// Decompresses the receiver with the given \c compressionType. On successful compression, a
/// mutable data holding the compressed buffer is returned. If an error occurred while compressing,
/// \c error is populated with the \c LTErrorCodeCompressionFailed code and \c nil is returned.
///
/// @note a mutable container is returned for performance reasons. The returned object is not
/// retained nor modified by the receiver after this method returns.
- (nullable NSMutableData *)lt_decompressWithCompressionType:(LTCompressionType)compressionType
                                                       error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
