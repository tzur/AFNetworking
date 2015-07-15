// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIZCompressor.h"

#import "LTIZFastMath.h"
#import "LTIZHeader.h"
#import "LTMMInputFile.h"
#import "LTMMOutputFile.h"
#import "LTMatParallelDispatcher.h"
#import "NSError+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Number of bits in for each element in the context.
static const size_t kContextBits = 4;

/// Maximal number of bits the code can have. The values in \c kCountTable must not have values
/// above this constant.
static const size_t kMaxCodeBits = 6;

/// Maximal value the code can have.
static const size_t kMaxCodeValue = 1 << kMaxCodeBits;

/// Initial context value, used both for encoding and decoding.
static const uint32_t kInitialContextValue = 7;

/// Number of bits to use for each value for (previous, next) contexts pair.
static const uint32_t kBitCountTable[1 << (2 * kContextBits)] = {
  1, 3, 2, 5, 5, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  3, 2, 2, 2, 4, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  4, 2, 2, 2, 3, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  6, 4, 2, 2, 2, 3, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  6, 6, 3, 2, 2, 2, 4, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  6, 6, 4, 2, 2, 2, 3, 6, 6, 0, 0, 0, 0, 0, 0, 0,
  6, 6, 6, 4, 2, 2, 2, 3, 6, 0, 0, 0, 0, 0, 0, 0,
  6, 6, 6, 6, 3, 2, 2, 2, 4, 0, 0, 0, 0, 0, 0, 0,
  6, 6, 5, 5, 5, 3, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0
};

/// Maps from a (previous, next) contexts pair to a code value.
static const uint32_t kEncodeTable[1 << (2 * kContextBits)] = {
  0,  6,  2,  28, 29, 60, 61, 62, 63, 0,  0,  0,  0,  0,  0,  0,
  6,  0,  1,  2,  14, 60, 61, 62, 63, 0,  0,  0,  0,  0,  0,  0,
  14, 0,  1,  2,  6,  60, 61, 62, 63, 0,  0,  0,  0,  0,  0,  0,
  60, 14, 0,  1,  2,  6,  61, 62, 63, 0,  0,  0,  0,  0,  0,  0,
  60, 61, 6,  0,  1,  2,  14, 62, 63, 0,  0,  0,  0,  0,  0,  0,
  60, 61, 14, 0,  1,  2,  6,  62, 63, 0,  0,  0,  0,  0,  0,  0,
  60, 61, 62, 14, 0,  1,  2,  6,  63, 0,  0,  0,  0,  0,  0,  0,
  60, 61, 62, 63, 6,  0,  1,  2,  14, 0,  0,  0,  0,  0,  0,  0,
  62, 63, 28, 29, 30, 6,  0,  1,  2,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

/// Maps from the previous context and the current code value to the next context.
static const uint32_t kDecodeTable[1 << kContextBits][kMaxCodeValue] = {
  {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 4, 4, 5, 6, 7, 8
  }, {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 5, 6, 7, 8
  }, {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 5, 6, 7, 8
  }, {
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 0, 6, 7, 8
  }, {
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 0, 1, 7, 8
  }, {
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 0, 1, 7, 8
  }, {
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 3, 3, 3, 3, 0, 1, 2, 8
  }, {
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 8, 8, 0, 1, 2, 3
  }, {
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 5, 5, 5, 5, 5, 5, 5, 5, 2, 2, 3, 3, 4, 4, 0, 1
  }
};

NS_INLINE int LTIZPredict0(const uchar __unused * const data, size_t __unused bpp,
                           size_t __unused bpr) {
  return 0;
}

NS_INLINE int LTIZPredict1x(const uchar * const data, size_t bpp, size_t __unused  bpr) {
  return data[-bpp];
}

NS_INLINE int LTIZPredict1y(const uchar * const data, size_t __unused bpp, size_t bpr) {
  return data[-bpr];
}

NS_INLINE int LTIZPredict3(const uchar * const data, size_t bpp, size_t bpr)  {
  int x = data[-bpp];
  int y = data[-bpr];
  int xy = data[-bpp - bpr];

  return (3 * x + 3 * y - 2 * xy + 2) >> 2;
}

@implementation LTIZCompressor

/// Type of each code word.
typedef uint32_t LTIZCodeWord;

/// Type of the bit cache.
typedef uint64_t LTBitCache;

/// Number of bits in a code word.
static const size_t kCodeBits = sizeof(LTIZCodeWord) * CHAR_BIT;

/// Version of the Image Zero format.
static const uint16_t kImageZeroVersion = 1;

#pragma mark -
#pragma mark Encoding
#pragma mark -

/// Encodes a single pixel pointed by \c data with the given \c predictor.
#define LTEncodePixel(predictor) { \
  int32_t r = data[0]; \
  int32_t g = data[1]; \
  int32_t b = data[2]; \
  \
  int32_t pr = r - predictor(data, bpp, bpr); \
  int32_t pg = g - predictor(data + 1, bpp, bpr); \
  int32_t pb = b - predictor(data + 2, bpp, bpr); \
  \
  uint32_t upr = LTSignedToUnsigned((int8_t)(pr - pg)); \
  uint32_t upg = LTSignedToUnsigned((int8_t)pg); \
  uint32_t upb = LTSignedToUnsigned((int8_t)(pb - pg)); \
  \
  uint32_t bitCount = LTNumberOfBits(upr | upg | upb); \
  context = (context << kContextBits) + bitCount; \
  \
  LTEncoderWriteBits(kEncodeTable[context & LTBitMask(2 * kContextBits)], \
                     kBitCountTable[context & LTBitMask(2 * kContextBits)]); \
  LTEncoderWriteBits(upg, bitCount); \
  LTEncoderWriteBits(upr, bitCount); \
  LTEncoderWriteBits(upb, bitCount); \
  LTEncoderFlushSingleCodeWord(); \
  \
  data += bpp; \
}

/// Initializes the encoder's bit cache.
#define LTEncoderInitialize() \
  LTBitCache bitCache = 0; \
  uint32_t length = 0

/// Writes the given \c value of \c bitCount bits to the bit cache.
#define LTEncoderWriteBits(value, bitCount) \
  length += (bitCount); \
  bitCache = (bitCache << (bitCount)) + (value)

/// Flushes a single code word from the cache to memory if cache contains at least a single code
/// word.
#define LTEncoderFlushSingleCodeWord() \
  if (length >= kCodeBits) { \
    length -= kCodeBits; \
    LTEncoderStoreCode((LTIZCodeWord)(bitCache >> length)); \
  }

/// Flushes all the cache into memory.
#define LTEncoderFlushAll() \
  if (length > 0) { \
    LTEncoderStoreCode((LTIZCodeWord)(bitCache << (kCodeBits - length))); \
    length = 0; \
  }

/// Stores a code word of a given \c value to memory.
#define LTEncoderStoreCode(value) \
  *output++ = (value)

- (BOOL)compressImage:(const cv::Mat4b &)image toPath:(NSString *)path
                error:(NSError *__autoreleasing *)error {
  LTParameterAssert(image.rows < std::pow(2, 16) && image.cols < std::pow(2, 16), @"Input image "
                    "width and height must be less than 65535, got: (%d, %d)", image.rows,
                    image.cols);

  __block NSLock *lock = [[NSLock alloc] init];
  __block uint32_t success = YES;
  __block NSMutableArray *errors = [NSMutableArray array];

  LTMatParallelDispatcher *dispatcher = [[LTMatParallelDispatcher alloc] init];
  [dispatcher processMatAndWait:&(cv::Mat4b &)image
                processingBlock:^(NSUInteger shardIndex, NSUInteger shardCount, cv::Mat shard) {
                  __block NSError *shardError;

                  NSString *shardPath = [self shardPathForBasePath:path shardIndex:shardIndex];
                  BOOL compressedShard = [self compressShard:shard toPath:shardPath
                                                   imageSize:image.size()
                                                  shardIndex:shardIndex shardCount:shardCount
                                                       error:&shardError];

                  if (!compressedShard) {
                    [lock lock];
                    success = NO;
                    [errors addObject:shardError];
                    [lock unlock];
                  }
                }];

  if (error && errors.count) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed userInfo:@{
      NSFilePathErrorKey: path,
      kLTUnderlyingErrorsKey: [errors copy]
    }];
  }

  return success;
}

- (BOOL)compressShard:(const cv::Mat4b &)shard toPath:(NSString *)path
            imageSize:(cv::Size)imageSize
           shardIndex:(NSUInteger)shardIndex
           shardCount:(NSUInteger)shardCount
                error:(NSError *__autoreleasing *)error {
  size_t outputSize = [[self class] maximalCompressedSizeForImage:shard];
  LTMMOutputFile *file = [[LTMMOutputFile alloc] initWithPath:path
                                                         size:outputSize
                                                         mode:0644 error:error];
  if (!file) {
    return NO;
  }

  // Write file header.
  LTIZHeader header = [self headerForImageSize:imageSize shardSize:shard.size()
                                    shardIndex:shardIndex shardCount:shardCount];
  memcpy(file.data, &header, sizeof(LTIZHeader));

  if (!shard.total()) {
    file.finalSize = sizeof(LTIZHeader);
    return YES;
  }

  size_t bpr = shard.step[0];
  size_t bpp = shard.elemSize();
  size_t runLength = (shard.cols - 1) * bpp;

  uint32_t context = kInitialContextValue;

  const uchar *data = shard.data;
  LTIZCodeWord *output = (LTIZCodeWord *)(file.data + sizeof(LTIZHeader));

  LTEncoderInitialize();

  // First pixel has a zero predictor, since it has no top, left or diagonal neighbours.
  LTEncodePixel(LTIZPredict0);

  const uchar * const endFirstLine = data + runLength;
  while (data != endFirstLine) {
    // Pixels in the first row only have a left neighbour.
    LTEncodePixel(LTIZPredict1x);
  }

  for (int row = 1; row < shard.rows; ++row) {
    // First pixels in non-top row only have a top neighbour.
    data = shard.ptr<uchar>(row);
    LTEncodePixel(LTIZPredict1y);

    const uchar *endLine = data + runLength;
    while (data != endLine) {
      // General pixels have top, left and diagonal neighbours.
      LTEncodePixel(LTIZPredict3);
    }
  }

  LTEncoderFlushAll();

  // Truncate file to encoded size.
  file.finalSize = (uchar *)output - file.data;

  return YES;
}

- (LTIZHeader)headerForImageSize:(cv::Size)imageSize
                       shardSize:(cv::Size)shardSize
                        shardIndex:(uint8_t)shardIndex
                        shardCount:(uint8_t)shardCount {
  return {
    .signature = kLTIZHeaderSignature,
    .version = kImageZeroVersion,
    .totalWidth = (uint16_t)imageSize.width,
    .totalHeight = (uint16_t)imageSize.height,
    .shardWidth = (uint16_t)shardSize.width,
    .shardHeight = (uint16_t)shardSize.height,
    .shardIndex = shardIndex,
    .shardCount = shardCount
  };
}

#pragma mark -
#pragma mark Decoding
#pragma mark -

/// Decodes a single pixel to \c data with the given \c predictor.
#define LTDecodePixel(predictor) { \
  LTDecoderFillCache(); \
  \
  bitCount = kDecodeTable[previousBitCount][LTDecoderPeekBits(kMaxCodeBits)]; \
  LTDecoderSkipBits(kBitCountTable[previousBitCount << kContextBits | bitCount]); \
  previousBitCount = bitCount; \
  \
  uint32_t upg = LTDecoderReadBits(bitCount); \
  uint32_t upr = LTDecoderReadBits(bitCount); \
  uint32_t upb = LTDecoderReadBits(bitCount); \
  \
  int32_t pg = LTUnsignedToSigned(upg); \
  int32_t pr = LTUnsignedToSigned(upr) + pg; \
  int32_t pb = LTUnsignedToSigned(upb) + pg; \
  \
  data[0] = pr + predictor(data, bpp, bpr); \
  data[1] = pg + predictor(data + 1, bpp, bpr); \
  data[2] = pb + predictor(data + 2, bpp, bpr); \
  data[3] = UCHAR_MAX; \
  \
  data += bpp; \
}

/// Initializes the bit cache of the decoder.
#define LTDecoderInitialize() \
  LTBitCache bitCache = 0; \
  uint32_t length = 0; \
  \
  if ((uchar *)(code + 1) <= fileEnd) { \
    bitCache = LTDecoderFetchCodeWord(); \
    length = (uint32_t)kCodeBits; \
  }

/// Reads the given number of bits from the bit cache.
#define LTDecoderReadBits(bitCount) ({ \
  length -= (bitCount); \
  (LTIZCodeWord)((bitCache >> length) & LTBitMask(bitCount)); \
})

/// Peeks in the bit cache and returns the first given number of bits.
#define LTDecoderPeekBits(bitCount) ({ \
  (LTIZCodeWord)((bitCache >> (length - (bitCount))) & LTBitMask(bitCount)); \
})

/// Skips the given number of bits in the cache.
#define LTDecoderSkipBits(bitCount) \
  length -= (bitCount);

/// Fills the cache with a single code word from memory.
#define LTDecoderFillCache() \
  if (length < kCodeBits) { \
    bitCache <<= kCodeBits; \
    if ((uchar *)(code + 1) <= fileEnd) { \
      bitCache |= LTDecoderFetchCodeWord(); \
    } \
    length += kCodeBits; \
  }

/// Fetches a the next code word from memory.
#define LTDecoderFetchCodeWord() \
  *code++

- (BOOL)decompressFromPath:(NSString *)path toImage:(cv::Mat4b *)image
                     error:(NSError *__autoreleasing *)error {
  LTMMInputFile *file = [[LTMMInputFile alloc] initWithPath:path error:error];
  if (!file) {
    return NO;
  }

  if (file.size < sizeof(LTIZHeader)) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: @"File is smaller than ImageZero's header size"
      }];
    }
    return NO;
  }

  // Read and verify file header.
  LTIZHeader *header = (LTIZHeader *)file.data;
  if (![self verifyHeader:*header forFileInPath:path withImageSize:image->size() error:error]) {
    return NO;
  }

  if (!image->total()) {
    return YES;
  }

  NSLock *lock = [[NSLock alloc] init];
  __block uint32_t success = YES;
  __block NSMutableArray *errors = [NSMutableArray array];

  LTMatParallelDispatcher *dispatcher = [[LTMatParallelDispatcher alloc]
                                         initWithMaxShardCount:header->shardCount];
  [dispatcher processMatAndWait:image processingBlock:^(NSUInteger shardIndex,
                                                        NSUInteger shardCount,
                                                        cv::Mat shard) {
    cv::Mat4b rgbaShard = (cv::Mat4b)shard;
    BOOL decompressedShard;
    NSError *shardError;

    if (!shardIndex) {
      decompressedShard = [self decompressFromFile:file toShard:&rgbaShard
                                         imageSize:image->size()
                                        shardCount:shardCount error:&shardError];
    } else {
      NSString *shardPath = [self shardPathForBasePath:path shardIndex:shardIndex];
      decompressedShard = [self decompressFromPath:shardPath toShard:&rgbaShard
                                         imageSize:image->size()
                                        shardCount:shardCount error:&shardError];
    }

    if (!decompressedShard) {
      [lock lock];
      success = NO;
      [errors addObject:shardError];
      [lock unlock];
    }
  }];

  if (error && errors.count) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed userInfo:@{
      NSFilePathErrorKey: path,
      kLTUnderlyingErrorsKey: [errors copy]
    }];
  }

  return success;
}

- (BOOL)decompressFromPath:(NSString *)path toShard:(cv::Mat4b *)shard
                 imageSize:(cv::Size)imageSize
                shardCount:(NSUInteger)shardCount
                     error:(NSError *__autoreleasing *)error {
  LTMMInputFile *file = [[LTMMInputFile alloc] initWithPath:path error:error];
  if (!file) {
    return NO;
  }

  return [self decompressFromFile:file toShard:shard imageSize:imageSize
                       shardCount:shardCount error:error];
}

- (BOOL)decompressFromFile:(LTMMInputFile *)file toShard:(cv::Mat4b *)shard
                 imageSize:(cv::Size)imageSize
                shardCount:(NSUInteger)shardCount
                     error:(NSError *__autoreleasing *)error {
  if (file.size < sizeof(LTIZHeader)) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed userInfo:@{
        NSFilePathErrorKey: file.path ?: [NSNull null],
        kLTErrorDescriptionKey: @"File is smaller than ImageZero's header size"
      }];
    }
    return NO;
  }

  // Read and verify file header.
  LTIZHeader *header = (LTIZHeader *)file.data;
  if (![self verifyHeader:*header forFileInPath:file.path
            withImageSize:imageSize shardSize:shard->size()
            andShardCount:shardCount error:error]) {
    return NO;
  }

  const uchar *fileEnd = file.data + file.size;
  LTIZCodeWord *code = (LTIZCodeWord *)(file.data + sizeof(LTIZHeader));
  LTDecoderInitialize();

  size_t bpr = shard->step[0];
  size_t bpp = shard->elemSize();
  size_t runLength = (shard->cols - 1) * bpp;

  uint32_t bitCount;
  uint32_t previousBitCount = kInitialContextValue;

  uchar *data = shard->data;

  // First pixel has a zero predictor, since it has no top, left or diagonal neighbours.
  LTDecodePixel(LTIZPredict0);

  const uchar *endFirstLine = data + runLength;
  while (data != endFirstLine) {
    // Pixels in the first row only have a left neighbour.
    LTDecodePixel(LTIZPredict1x);
  }

  for (int row = 1; row < shard->rows; ++row) {
    data = shard->ptr<uchar>(row);
    // First pixels in non-top row only have a top neighbour.
    LTDecodePixel(LTIZPredict1y);

    const uchar *endLine = data + runLength;
    while (data != endLine) {
      // General pixels have top, left and diagonal neighbours.
      LTDecodePixel(LTIZPredict3);
    }
  }
  
  return YES;
}

- (BOOL)verifyHeader:(const LTIZHeader &)header forFileInPath:(NSString *)path
               error:(NSError *__autoreleasing *)error {
  if (header.signature != kLTIZHeaderSignature) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Invalid header signature given: %hu",
                               header.signature];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  if (header.version != kImageZeroVersion) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Unsupported header version given: %hu",
                               header.version];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  if (header.shardIndex >= header.shardCount) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Given shard index %hu cannot be larger "
                               "or equal to the total number of shards %hu", header.shardIndex,
                               header.shardCount];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  return YES;
}

- (BOOL)verifyHeader:(const LTIZHeader &)header forFileInPath:(NSString *)path
       withImageSize:(cv::Size)imageSize error:(NSError *__autoreleasing *)error {
  if (![self verifyHeader:header forFileInPath:path error:error]) {
    return NO;
  }

  if (imageSize.width != header.totalWidth || imageSize.height != header.totalHeight) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Given image size must be equal to the "
                               "compressed image's size. Got image with size (%d, %d), where the "
                               "compressed image size is (%d, %d)",
                               imageSize.width, imageSize.height,
                               header.totalWidth, header.totalHeight];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  return YES;
}

- (BOOL)verifyHeader:(const LTIZHeader &)header forFileInPath:(NSString *)path
       withImageSize:(cv::Size)imageSize shardSize:(cv::Size)shardSize
       andShardCount:(NSUInteger)shardCount
               error:(NSError *__autoreleasing *)error {
  if (![self verifyHeader:header forFileInPath:path withImageSize:imageSize error:error]) {
    return NO;
  }

  if (shardSize.width != header.shardWidth || shardSize.height != header.shardHeight) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Given shard size must be equal to the "
                               "compressed shard's size. Got image with size (%d, %d), where the "
                               "compressed shard size is (%d, %d)",
                               shardSize.width, shardSize.height,
                               header.shardWidth, header.shardHeight];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  if (header.shardCount != shardCount) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Given shard count %hu must be equal "
                               "across all shards of the same image (initial shard count of this "
                               "image is %lu)", header.shardCount,
                               (unsigned long)shardCount];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  if (!header.shardCount) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Given shard count must be non-zero"];
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return NO;
  }

  return YES;
}

+ (size_t)maximalCompressedSizeForImage:(const cv::Mat4b &)image {
  // The maximal size analysis is as follows:
  ///
  // Max pixel bit count: <max encoded pixel bit count> + <channels per pixel> *
  // <max bit count per channel> = 6 + 3 * 8 = 30 bit.
  //
  // This means in the worst case, we store 30 bits for each element (32 bits) in the input (since
  // we do not store the alpha channel).
  //
  // Max size for the entire image: <header size> + <pixel count> * <max pixel bit count> +
  // <align to code word> = sizeof(LTIZHeader) +
  // ceil(image.total() * (30.0 / 32.0)) * image.elemSize()
  static const double kMinimalCompressionFactor = 30.0 / 32.0;
  return sizeof(LTIZHeader) +
      std::ceil(image.total() * kMinimalCompressionFactor) * image.elemSize();
}

#pragma mark -
#pragma mark File paths
#pragma mark -

- (nullable NSArray *)shardsPathsOfCompressedImageFromPath:(NSString *)path
                                                     error:(NSError *__autoreleasing *)error {
  LTMMInputFile *file = [[LTMMInputFile alloc] initWithPath:path error:error];
  if (!file) {
    return nil;
  }

  if (file.size < sizeof(LTIZHeader)) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed userInfo:@{
        NSFilePathErrorKey: file.path ?: [NSNull null],
        kLTErrorDescriptionKey: @"File is smaller than ImageZero's header size"
      }];
    }
    return nil;
  }

  LTIZHeader *header = (LTIZHeader *)file.data;
  if (![self verifyHeader:*header forFileInPath:path error:error]) {
    return nil;
  }

  if (header->shardIndex != 0) {
    NSString *description = [NSString stringWithFormat:@"Expecting shardIndex of 0, got: %d",
                             header->shardIndex];
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeBadHeader userInfo:@{
        NSFilePathErrorKey: path ?: [NSNull null],
        kLTErrorDescriptionKey: description
      }];
    }
    return nil;
  }

  NSMutableArray *paths = [NSMutableArray array];
  for (NSUInteger i = 0; i < header->shardCount; ++i) {
    [paths addObject:[self shardPathForBasePath:path shardIndex:i]];
  }
  return [paths copy];
}

- (NSString *)shardPathForBasePath:(NSString *)basePath shardIndex:(NSUInteger)shardIndex {
  if (!shardIndex) {
    return basePath;
  }

  NSString *suffix = [NSString stringWithFormat:@"%lu", (unsigned long)shardIndex];
  return [basePath stringByAppendingPathExtension:suffix];
}

@end

NS_ASSUME_NONNULL_END
