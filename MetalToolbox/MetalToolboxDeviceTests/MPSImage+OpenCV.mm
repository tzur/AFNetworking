// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSImage+OpenCV.h"

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping of Metal texture pixel format to matrix depth.
static const std::unordered_map<MTLPixelFormat, int> kMTLPixelFormatToMatDepth = {
  {MTLPixelFormatR8Unorm, CV_8U},
  {MTLPixelFormatR8Unorm_sRGB, CV_8U},
  {MTLPixelFormatR8Snorm, CV_8S},
  {MTLPixelFormatR8Uint, CV_8U},
  {MTLPixelFormatR8Sint, CV_8S},
  {MTLPixelFormatR16Unorm, CV_16U},
  {MTLPixelFormatR16Snorm, CV_16S},
  {MTLPixelFormatR16Uint, CV_16U},
  {MTLPixelFormatR16Sint, CV_16S},
  {MTLPixelFormatR32Sint, CV_32S},
  {MTLPixelFormatR32Float, CV_32F},
  {MTLPixelFormatRG8Unorm, CV_8U},
  {MTLPixelFormatRG8Unorm_sRGB, CV_8U},
  {MTLPixelFormatRG8Snorm, CV_8S},
  {MTLPixelFormatRG8Uint, CV_8U},
  {MTLPixelFormatRG8Sint, CV_8S},
  {MTLPixelFormatRG16Unorm, CV_16U},
  {MTLPixelFormatRG16Snorm, CV_16S},
  {MTLPixelFormatRG16Uint, CV_16U},
  {MTLPixelFormatRG16Sint, CV_16S},
  {MTLPixelFormatRG32Sint, CV_32S},
  {MTLPixelFormatRG32Float, CV_32F},
  {MTLPixelFormatRGBA8Unorm, CV_8U},
  {MTLPixelFormatRGBA8Unorm_sRGB, CV_8U},
  {MTLPixelFormatRGBA8Snorm, CV_8S},
  {MTLPixelFormatRGBA8Uint, CV_8U},
  {MTLPixelFormatRGBA8Sint, CV_8S},
  {MTLPixelFormatRGBA16Unorm, CV_16U},
  {MTLPixelFormatRGBA16Snorm, CV_16S},
  {MTLPixelFormatRGBA16Uint, CV_16U},
  {MTLPixelFormatRGBA16Sint, CV_16S},
  {MTLPixelFormatRGBA32Sint, CV_32S},
  {MTLPixelFormatRGBA32Float, CV_32F}
};

/// Mapping of matrix depth to Metal feature channel format.
static const std::unordered_map<int, MPSImageFeatureChannelFormat>
    kMatDepthToMPSPixelChannelFormat = {
      {CV_8U, MPSImageFeatureChannelFormatUnorm8},
      {CV_16U, MPSImageFeatureChannelFormatUnorm16},
      {CV_32F, MPSImageFeatureChannelFormatFloat32}
    };

@implementation MPSImage (OpenCV)

+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device mat:(const cv::Mat &)mat {
  auto matDepth = mat.depth();
  auto featureChannelFormat = kMatDepthToMPSPixelChannelFormat.find(matDepth);
  auto image = [MPSImage mtb_imageWithDevice:device format:featureChannelFormat->second
                                       width:mat.cols height:mat.rows channels:mat.channels()];

  [image mtb_copyFromMat:mat];
  return image;
}

- (void)mtb_copyToMat:(cv::Mat *)mat {
  auto matDepth = kMTLPixelFormatToMatDepth.find(self.pixelFormat);
  auto matType = CV_MAKETYPE(matDepth->second, (int)self.featureChannels);
  mat->create((int)self.height, (int)self.width, matType);

  auto region = MTLRegionMake2D(0, 0, self.width, self.height);

  if (self.featureChannels == 1 || self.featureChannels == 2 || self.featureChannels == 4) {
    [self.texture getBytes:mat->data bytesPerRow:mat->step[0] fromRegion:region mipmapLevel:0];
    return;
  }

  // Textures of images with featureChannels >= 3 are sliced into slices with 4 channels in each.
  static const int kChannelsPerSlice = 4;

  int sliceCount = ((int)self.featureChannels + kChannelsPerSlice - 1) / kChannelsPerSlice;

  auto pixelPerRow = mat->reshape(1, (int)mat->total());
  cv::Mat sliceMat((int)mat->total(), kChannelsPerSlice, mat->depth());

  for (int i = 0; i < sliceCount; ++i) {
    int sliceStart = kChannelsPerSlice * i;
    auto sliceWidth = std::min((int)self.featureChannels - sliceStart, kChannelsPerSlice);

    [self.texture getBytes:sliceMat.data bytesPerRow:sliceMat.step[0] bytesPerImage:0
                fromRegion:region mipmapLevel:0 slice:i];

    sliceMat.colRange(0, sliceWidth).copyTo(pixelPerRow.colRange(sliceStart,
                                                                 sliceStart + sliceWidth));
  }
}

- (cv::Mat)mtb_mat {
  auto matDepth = kMTLPixelFormatToMatDepth.find(self.pixelFormat);
  auto matType = CV_MAKETYPE(matDepth->second, (int)self.featureChannels);
  cv::Mat output((int)self.height, (int)self.width, matType);

  [self mtb_copyToMat:&output];

  return output;
}

- (void)mtb_copyFromMat:(const cv::Mat &)mat {
  auto region = MTLRegionMake2D(0, 0, self.width, self.height);

  if (self.featureChannels == 1 || self.featureChannels == 2 || self.featureChannels == 4) {
    [self.texture replaceRegion:region mipmapLevel:0 withBytes:mat.data bytesPerRow:mat.step[0]];
    return;
  }

  // All slices of Metal textures have 4 channels.
  static const int kChannelsPerSlice = 4;

  int sliceCount = ((int)self.featureChannels + kChannelsPerSlice - 1) / kChannelsPerSlice;

  auto pixelPerRow = mat.reshape(1, (int)mat.total());
  cv::Mat sliceMat((int)mat.total(), kChannelsPerSlice, mat.depth());

  for (int i = 0; i < sliceCount; ++i) {
    int sliceStart = kChannelsPerSlice * i;
    auto sliceWidth = std::min((int)self.featureChannels - sliceStart, kChannelsPerSlice);

    pixelPerRow.colRange(sliceStart, sliceStart + sliceWidth).copyTo(sliceMat.colRange(0,
                                                                                       sliceWidth));

    [self.texture replaceRegion:region mipmapLevel:0 slice:i withBytes:sliceMat.data
                    bytesPerRow:sliceMat.step[0] bytesPerImage:0];
  }
}

@end

NS_ASSUME_NONNULL_END
