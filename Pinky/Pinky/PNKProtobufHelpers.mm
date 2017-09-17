// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "PNKProtobufHelpers.h"

#import "PNKProtobufMacros.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import <google/protobuf/repeated_field.h>
PNK_PROTOBUF_INCLUDE_END

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

cv::Mat1f createMat(const google::protobuf::RepeatedField<float> &repeatedField) {
  if (repeatedField.size() == 0) {
    return cv::Mat1f();
  }
  cv::Mat1f mat(1, repeatedField.size());
  std::copy(repeatedField.begin(), repeatedField.end(), mat.begin());
  return mat;
}

} // namespace pnk

NS_ASSUME_NONNULL_END
