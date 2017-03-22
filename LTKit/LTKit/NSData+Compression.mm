// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSData+Compression.h"

#import <compression.h>

#import "NSErrorCodes+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents the compression operation to perform.
typedef NS_ENUM(NSUInteger, LTCompressionOperation) {
  /// Compress the data.
  LTCompressionOperationCompress,
  /// Decompress the data.
  LTCompressionOperationDecompress
};

@implementation NSData (Compression)

/// Chunk size used when compressing and decompressing a stream.
static const size_t kChunkSize = 16384;

- (nullable NSMutableData *)lt_compressWithCompressionType:(LTCompressionType)compressionType
                                                     error:(NSError *__autoreleasing *)error {
  return [self lt_dataUsingCompressionType:compressionType
                      compressionOperation:LTCompressionOperationCompress error:error];
}

- (nullable NSMutableData *)lt_decompressWithCompressionType:(LTCompressionType)compressionType
                                                       error:(NSError *__autoreleasing *)error {
  return [self lt_dataUsingCompressionType:compressionType
                      compressionOperation:LTCompressionOperationDecompress error:error];
}

- (nullable NSMutableData *)lt_dataUsingCompressionType:(LTCompressionType)compressionType
                                   compressionOperation:(LTCompressionOperation)operation
                                                  error:(NSError *__autoreleasing *)error {
  compression_stream stream;
  compression_algorithm algorithm = [self.class lt_algorithmForCompressionType:compressionType];
  compression_stream_operation streamOperation = operation == LTCompressionOperationDecompress ?
      COMPRESSION_STREAM_DECODE : COMPRESSION_STREAM_ENCODE;
  compression_status initStatus = compression_stream_init(&stream, streamOperation, algorithm);
  if (initStatus != COMPRESSION_STATUS_OK) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed
                             description:@"Error creating compression stream"];
    }
    return nil;
  }

  NSMutableData *data = [NSMutableData data];
  const auto buffer = std::make_unique<uint8_t[]>(kChunkSize);

  stream.src_ptr = (uint8_t *)self.bytes;
  stream.src_size = self.length;
  stream.dst_ptr = buffer.get();
  stream.dst_size = kChunkSize;

  compression_status processStatus;
  BOOL successfullyEnded = NO;

  do {
    processStatus = compression_stream_process(&stream, COMPRESSION_STREAM_FINALIZE);

    switch (processStatus) {
      case COMPRESSION_STATUS_OK:
        if (!stream.dst_size) {
          [data appendBytes:buffer.get() length:kChunkSize];

          stream.dst_ptr = buffer.get();
          stream.dst_size = kChunkSize;
        }
        break;
      case COMPRESSION_STATUS_END:
        [data appendBytes:buffer.get() length:kChunkSize - stream.dst_size];
        successfullyEnded = YES;
        break;
      case COMPRESSION_STATUS_ERROR:
        if (error) {
          *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed
                                 description:@"Error while decompressing"];
        }
        break;
      default:
        LTAssert(NO, @"Invalid status while decompressing: %d", processStatus);
    }
  } while (processStatus == COMPRESSION_STATUS_OK);

  compression_status destroyStatus = compression_stream_destroy(&stream);
  if (destroyStatus != COMPRESSION_STATUS_OK) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed
                             description:@"Error while destroying compression stream"];
    }
    return nil;
  }

  if (!data.length) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed
                             description:@"Output data is empty"];
    }
    return nil;
  }

  return successfullyEnded ? data : nil;
}

+ (compression_algorithm)lt_algorithmForCompressionType:(LTCompressionType)compressionType {
  switch (compressionType) {
    case LTCompressionTypeLZFSE:
      return COMPRESSION_LZFSE;
    case LTCompressionTypeLZ4:
      return COMPRESSION_LZ4;
    case LTCompressionTypeLZMA:
      return COMPRESSION_LZMA;
    case LTCompressionTypeZLIB:
      return COMPRESSION_ZLIB;
  }
}

@end

NS_ASSUME_NONNULL_END
