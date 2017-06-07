// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping of Metal texture pixel format to mat type.
static const std::unordered_map<MTLPixelFormat, int> kMTLPixelFormatToMatInfo{
  {MTLPixelFormatRGBA8Unorm, CV_8UC4},
  {MTLPixelFormatRGBA8Unorm_sRGB, CV_8UC4},
  {MTLPixelFormatRGBA8Snorm, CV_8SC4},
  {MTLPixelFormatRGBA8Uint, CV_8UC4},
  {MTLPixelFormatRGBA8Sint, CV_8SC4},
  {MTLPixelFormatRGBA16Unorm, CV_16UC4},
  {MTLPixelFormatRGBA16Snorm, CV_16SC4},
  {MTLPixelFormatRGBA16Uint, CV_16UC4},
  {MTLPixelFormatRGBA16Sint, CV_16SC4},
  {MTLPixelFormatRGBA16Float, CV_16FC4},
  {MTLPixelFormatRGBA32Sint, CV_32SC4},
  {MTLPixelFormatRGBA32Float, CV_32FC4}
};

cv::Mat PNKMatFromMTLTexture(id<MTLTexture> texture) {
  auto region = MTLRegionMake2D(0, 0, texture.width, texture.height);
  return PNKMatFromMTLTextureRegion(texture, region);
}

cv::Mat PNKMatFromMTLTextureRegion(id<MTLTexture> texture, MTLRegion region) {
  auto pixelFormat = kMTLPixelFormatToMatInfo.find(texture.pixelFormat);
  LTParameterAssert(pixelFormat != kMTLPixelFormatToMatInfo.end(),
                    @"Pixel format type is not supported: %lu",
                    (unsigned long)texture.pixelFormat);

  auto matType = pixelFormat->second;
  auto targetSize = CGSizeMake(region.size.width, region.size.height);
  auto targetBytesPerRow = targetSize.width * CV_MAT_CN(matType) * CV_ELEM_SIZE1(matType);

  cv::Mat output(targetSize.height, targetSize.width, matType);
  [texture getBytes:output.data bytesPerRow:targetBytesPerRow fromRegion:region mipmapLevel:0];
  return output;
}

void PNKCopyMatToMTLTextureRegion(id<MTLTexture> texture, MTLRegion region, const cv::Mat &data,
                                  NSUInteger slice, NSUInteger mipmapLevel) {
  LTParameterAssert(data.isContinuous(), @"Allocated matrix is not continuous");
  LTParameterAssert(data.cols == (int)(region.size.width),
                    @"Data mat width doesn't match region width");
  LTParameterAssert(data.rows == (int)(region.size.height),
                    @"Data mat height doesn't match region height");
  auto pixelFormat = kMTLPixelFormatToMatInfo.find(texture.pixelFormat);
  LTParameterAssert(pixelFormat != kMTLPixelFormatToMatInfo.end(),
                    @"Pixel format type is not supported: %lu",
                    (unsigned long)texture.pixelFormat);
  auto matType = pixelFormat->second;
  LTParameterAssert(matType == data.type(), @"Data mat type doesn't match texture pixel: %lu",
                    (unsigned long)texture.pixelFormat);
  [texture replaceRegion:region
             mipmapLevel:mipmapLevel
                   slice:slice
               withBytes:data.data
             bytesPerRow:texture.width * CV_MAT_CN(matType) * CV_ELEM_SIZE1(matType)
           bytesPerImage:0];
}

void PNKCopyMatToMTLTexture(id<MTLTexture> texture, const cv::Mat &data, NSUInteger slice,
                            NSUInteger mipmapLevel) {
  PNKCopyMatToMTLTextureRegion(texture, MTLRegionMake2D(0, 0, texture.width, texture.height),
                               data, slice, mipmapLevel);
}

NS_ASSUME_NONNULL_END
