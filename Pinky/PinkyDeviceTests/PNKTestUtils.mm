// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTestUtils.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSBundle+Path.h>

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Maps Open CV type constants to \c MPSImageFeatureChannelFormat.
static const std::map<int, MPSImageFeatureChannelFormat> kCVTypeToFeatureChannelFormat = {
  {CV_8U, MPSImageFeatureChannelFormatUnorm8},
  {CV_16U, MPSImageFeatureChannelFormatUnorm16},
  {CV_16F, MPSImageFeatureChannelFormatFloat16},
  {CV_32F, MPSImageFeatureChannelFormatFloat32}
};

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

MPSImage *PNKImageMakeAndClearHalf(id<MTLDevice> device, MTLSize size) {
  auto image = [MPSImage pnk_float16ImageWithDevice:device size:size];

  auto slices = (int)image.pnk_textureArrayDepth;
  auto channelsPerSlice = (size.depth <= 2) ? (int)size.depth : 4;

  cv::Mat zeroes((int)size.height, (int)size.width, CV_16FC(channelsPerSlice));
  zeroes = 0;

  for (int slice = 0; slice < slices; ++slice) {
    PNKCopyMatToMTLTexture(image.texture, zeroes, slice);
  }

  return image;
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

template <typename T>
cv::Mat PNKGenerateChannelwiseConstantMatrix(NSUInteger rows, NSUInteger columns,
                                             const std::vector<T> &values) {
  int channels = (int)values.size();

  cv::Mat matrix = cv::Mat((int)(rows * columns), channels, cv::DataType<T>::type);

  for (int i = 0; i < matrix.rows; i++) {
    for (int j = 0; j < channels; j++) {
      matrix.at<T>(i, j) = values[j];
    }
  }

  return matrix.reshape(channels, (int)rows);
}

template cv::Mat PNKGenerateChannelwiseConstantMatrix<uchar>(NSUInteger rows, NSUInteger columns,
                                                             const std::vector<uchar> &values);

template cv::Mat PNKGenerateChannelwiseConstantMatrix<half_float::half>(NSUInteger rows,
    NSUInteger columns, const std::vector<half_float::half> &values);

MPSImageFeatureChannelFormat PNKFeatureChannelFormatFromCVType(int type) {
  return kCVTypeToFeatureChannelFormat.at(type);
}

NS_ASSUME_NONNULL_END
