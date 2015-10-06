// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "../../third_party/utils/half/half.hpp"

#import <opencv2/core/core.hpp>

/// Support for half-float matrices and vectors for OpenCV.

/// @important currently supported operations are:
///     - Creating a matrix.
///     - Storing and retrieving values using element access.
///     - Using \c .setTo() to set value across the entire matrix.
///
/// Since the underlying implementation handles the half-float data type as an unsigned short, avoid
/// using OpenCV's methods that rely on type such as conversion operators and math operators. Your
/// data will be probably handled as an unsigned short.

#define CV_16F CV_16U

#define CV_16FC1 CV_MAKETYPE(CV_16F, 1)
#define CV_16FC2 CV_MAKETYPE(CV_16F, 2)
#define CV_16FC3 CV_MAKETYPE(CV_16F, 3)
#define CV_16FC4 CV_MAKETYPE(CV_16F, 4)
#define CV_16FC(n) CV_MAKETYPE(CV_16F, (n))

namespace cv {
  typedef Vec<half_float::half, 2> Vec2hf;
  typedef Vec<half_float::half, 3> Vec3hf;
  typedef Vec<half_float::half, 4> Vec4hf;

  typedef Mat_<half_float::half> Mat1hf;
  typedef Mat_<Vec2hf> Mat2hf;
  typedef Mat_<Vec3hf> Mat3hf;
  typedef Mat_<Vec4hf> Mat4hf;

  template<>
  class DataDepth<half_float::half> {
  public:
    enum {
      value = CV_16F,
      fmt = (int)'r'
    };
  };

  template<>
  class DataType<half_float::half> {
  public:
    typedef half_float::half value_type;
    typedef value_type work_type;
    typedef value_type channel_type;
    typedef value_type vec_type;
    enum {
      generic_type = 0,
      depth = DataDepth<channel_type>::value,
      channels = 1,
      fmt = DataDepth<channel_type>::fmt,
      type = CV_MAKETYPE(depth, channels)
    };
  };
}
