// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTensorSerializationUtilities.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSData+Compression.h>

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

cv::Mat loadHalfTensor(NSURL *tensorURL, MTLSize tensorSize, NSError **error) {
  auto _Nullable tesnorPath = tensorURL.path;
  LTParameterAssert(tesnorPath, @"%@ path is nil", tensorURL);
  LTMMInputFile * _Nullable inputFile = [[LTMMInputFile alloc] initWithPath:tesnorPath error:error];
  if (!inputFile) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed url:tensorURL];
    }
    return cv::Mat();
  }

  NSData *inputData = [NSData dataWithBytes:inputFile.data length:inputFile.size];
  NSData * _Nullable data =
      [inputData lt_decompressWithCompressionType:LTCompressionTypeLZFSE error:error];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed path:tesnorPath
                             description:@"Failed to decompress data of tensor file"];
    }
    return cv::Mat();
  }

  unsigned long expectedLength = (unsigned long)(tensorSize.width * tensorSize.height *
                                                 tensorSize.depth * sizeof(half_float::half));
  if (data.length != expectedLength) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Tensor data length must be %lu, got %lu",
                expectedLength, (unsigned long)data.length];
    }
    return cv::Mat();
  }

  cv::Mat1hf tensor((int)(tensorSize.width * tensorSize.height), (int)tensorSize.depth);
  memcpy(tensor.data, data.bytes, data.length);
  return tensor.reshape((int)tensorSize.depth, (int)tensorSize.height);
}

} // namespace pnk

NS_ASSUME_NONNULL_END
