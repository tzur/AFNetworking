// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTestUtils.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSBundle+Path.h>

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Extracts image size from the tensor file name. The \c fileName must be in form
/// <tt><some text>_<width>x<height>x<depth>.<extension></tt>; zero size is returned otherwise.
static MTLSize PNKImageSizeFromFileName(NSString *fileName) {
  auto *regex = [NSRegularExpression
                 regularExpressionWithPattern:@"^.*_(\\d+)x(\\d+)x(\\d+)\\.\\w+$"
                 options:0 error:nil];
  auto matches = [regex matchesInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
  if (matches.count != 1) {
    return MTLSizeMake(0, 0, 0);
  }

  auto match = matches[0];
  if (match.numberOfRanges != 4) {
    return MTLSizeMake(0, 0, 0);
  }

  auto height = [[fileName substringWithRange:[match rangeAtIndex:1]] integerValue];
  auto width = [[fileName substringWithRange:[match rangeAtIndex:2]] integerValue];
  auto depth = [[fileName substringWithRange:[match rangeAtIndex:3]] integerValue];

  return MTLSizeMake(width, height, depth);
}

MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels) {
  return [MPSImage pnk_imageWithDevice:device format:format width:width height:height
                              channels:channels];
}

MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels) {
  return [MPSImage pnk_unorm8ImageWithDevice:device width:width height:height channels:channels];
}

cv::Mat1f PNKLoadFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(float) == 0, @"File size must be a multiply of "
                    "%lu, got %lu", sizeof(float), tensorFile.size);

  cv::Mat1f tensorData(1, (int)tensorFile.size / sizeof(float));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

cv::Mat1hf PNKLoadHalfFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(half_float::half) == 0, @"File size must be a "
                    "multiply of %lu, got %lu", sizeof(float) / 2, tensorFile.size);

  cv::Mat1hf tensorData(1, (int)tensorFile.size / sizeof(half_float::half));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

cv::Mat PNKLoadStructuredHalfFloatTensorFromResource(NSBundle *bundle, NSString *resource) {
  auto tensorAsOneRow = PNKLoadHalfFloatTensorFromBundleResource(bundle, resource);
  auto tensorSize = PNKImageSizeFromFileName(resource);
  LTParameterAssert((NSUInteger)tensorAsOneRow.total() == tensorSize.width * tensorSize.height *
                    tensorSize.depth, @"Tensor size %lu does not match its dimensions "
                    "%lu * %lu * %lu", (unsigned long)tensorAsOneRow.total(),
                    (unsigned long)tensorSize.width, (unsigned long)tensorSize.height,
                    (unsigned long)tensorSize.depth);
  cv::Mat result = tensorAsOneRow.reshape((int)tensorSize.depth, (int)tensorSize.height);
  return result;
}

cv::Mat PNKFillMatrix(int rows, int columns, int channels) {
  cv::Mat1hf matrix(rows * columns, channels);
  for (int i = 0; i < rows; ++i) {
    for (int j = 0; j < columns; ++j) {
      for (int k = 0; k < channels; ++k) {
        matrix.at<half_float::half>(i * columns + j, k) =
            (half_float::half)((i + j + k) % 2);
      }
    }
  }
  return matrix.reshape(channels, rows);
}

template <typename T, int cvType>
cv::Mat PNKGenerateChannelwiseConstantMatrix(NSUInteger rows, NSUInteger columns,
                                             const std::vector<T> &values) {
  int channels = (int)values.size();

  cv::Mat matrix = cv::Mat((int)(rows * columns), channels, cvType);

  for (int i = 0; i < matrix.rows; i++) {
    for (int j = 0; j < channels; j++) {
      matrix.at<T>(i, j) = values[j];
    }
  }

  return matrix.reshape(channels, (int)rows);
}

cv::Mat PNKGenerateChannelwiseConstantUcharMatrix(NSUInteger rows, NSUInteger columns,
                                                  const std::vector<uchar> &values) {
  return PNKGenerateChannelwiseConstantMatrix<uchar, CV_8U>(rows, columns, values);
}

cv::Mat PNKGenerateChannelwiseConstantHalfFloatMatrix(NSUInteger rows, NSUInteger columns,
                                                      const std::vector<half_float::half> &values) {
  return PNKGenerateChannelwiseConstantMatrix<half_float::half, CV_16F>(rows, columns, values);
}

NS_ASSUME_NONNULL_END
