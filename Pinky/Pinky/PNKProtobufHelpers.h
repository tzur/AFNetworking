// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

namespace google {
  namespace protobuf {
    template <typename Element>
    class RepeatedField;
  }
}

namespace pnk {

/// Returns a row vector with the values of the given \c repeatedField. If \c repeatedField is
/// empty, an empty matrix is returned.
cv::Mat1f createMat(const google::protobuf::RepeatedField<float> &repeatedField);

} // namespace pnk

NS_ASSUME_NONNULL_END
