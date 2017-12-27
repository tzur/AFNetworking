// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping of Metal texture pixel format to mat type.
static const std::unordered_map<MTLPixelFormat, int> kMTLPixelFormatToMatInfo = {
  {MTLPixelFormatR8Unorm, CV_8UC1},
  {MTLPixelFormatR8Unorm_sRGB, CV_8UC1},
  {MTLPixelFormatR8Snorm, CV_8SC1},
  {MTLPixelFormatR8Uint, CV_8UC1},
  {MTLPixelFormatR8Sint, CV_8SC1},
  {MTLPixelFormatR16Unorm, CV_16UC1},
  {MTLPixelFormatR16Snorm, CV_16SC1},
  {MTLPixelFormatR16Uint, CV_16UC1},
  {MTLPixelFormatR16Sint, CV_16SC1},
  {MTLPixelFormatR16Float, CV_16FC1},
  {MTLPixelFormatR32Sint, CV_32SC1},
  {MTLPixelFormatR32Float, CV_32FC1},
  {MTLPixelFormatRG8Unorm, CV_8UC2},
  {MTLPixelFormatRG8Unorm_sRGB, CV_8UC2},
  {MTLPixelFormatRG8Snorm, CV_8SC2},
  {MTLPixelFormatRG8Uint, CV_8UC2},
  {MTLPixelFormatRG8Sint, CV_8SC2},
  {MTLPixelFormatRG16Unorm, CV_16UC2},
  {MTLPixelFormatRG16Snorm, CV_16SC2},
  {MTLPixelFormatRG16Uint, CV_16UC2},
  {MTLPixelFormatRG16Sint, CV_16SC2},
  {MTLPixelFormatRG16Float, CV_16FC2},
  {MTLPixelFormatRG32Sint, CV_32SC2},
  {MTLPixelFormatRG32Float, CV_32FC2},
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

cv::Mat PNKMatFromMTLTexture(id<MTLTexture> texture, NSUInteger slice) {
  auto region = MTLRegionMake2D(0, 0, texture.width, texture.height);
  return PNKMatFromMTLTextureRegion(texture, region, slice);
}

cv::Mat PNKMatFromMTLTextureRegion(id<MTLTexture> texture, MTLRegion region, NSUInteger slice) {
  auto pixelFormat = kMTLPixelFormatToMatInfo.find(texture.pixelFormat);
  LTParameterAssert(pixelFormat != kMTLPixelFormatToMatInfo.end(),
                    @"Pixel format type is not supported: %lu",
                    (unsigned long)texture.pixelFormat);
  cv::Mat output((int)region.size.height, (int)region.size.width, pixelFormat->second);
  PNKCopyMTLTextureRegionToMat(texture, region, slice, 0, &output);
  return output;
}

void PNKCopyMTLTextureToMat(id<MTLTexture> texture, NSUInteger slice, NSUInteger mipmapLevel,
                            cv::Mat *mat) {
  auto region = MTLRegionMake2D(0, 0, texture.width, texture.height);
  PNKCopyMTLTextureRegionToMat(texture, region, slice, mipmapLevel, mat);
}

void PNKCopyMTLTextureRegionToMat(id<MTLTexture> texture, MTLRegion region, NSUInteger slice,
                                  NSUInteger mipmapLevel, cv::Mat *mat) {
  auto pixelFormat = kMTLPixelFormatToMatInfo.find(texture.pixelFormat);
  LTParameterAssert(pixelFormat != kMTLPixelFormatToMatInfo.end(),
                    @"Pixel format type is not supported: %lu",
                    (unsigned long)texture.pixelFormat);
  LTParameterAssert(slice < texture.arrayLength,
                    @"Slice must be smaller than the texture's arrayLength (%lu), got: %lu",
                    (unsigned long)texture.arrayLength, (unsigned long)slice);

  auto matType = pixelFormat->second;
  LTParameterAssert(mat, @"Mat parameter must be non-null");
  LTParameterAssert(matType == mat->type(), @"matrix must be of type %d - got %d", matType,
                    mat->type());
  LTParameterAssert((int)region.size.width == mat->cols, @"Matrix must have %d columns - got %d",
                    (int)region.size.width, mat->cols);
  LTParameterAssert((int)region.size.height == mat->rows, @"Matrix must have %d columns - got %d",
                    (int)region.size.height, mat->rows);

  auto matBytesPerRow = mat->step[0];

  [texture getBytes:mat->data bytesPerRow:matBytesPerRow bytesPerImage:0 fromRegion:region
        mipmapLevel:mipmapLevel slice:slice];
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
  LTParameterAssert(slice < texture.arrayLength,
                    @"Slice must be smaller than the texture's arrayLength (%lu), got: %lu",
                    (unsigned long)texture.arrayLength, (unsigned long)slice);

  // \c bytesPerImage must be \c 0 when writing to textures of type other than MTLTextureType3D.
  [texture replaceRegion:region
             mipmapLevel:mipmapLevel
                   slice:slice
               withBytes:data.data
             bytesPerRow:region.size.width * CV_MAT_CN(matType) * CV_ELEM_SIZE1(matType)
           bytesPerImage:0];
}

void PNKCopyMatToMTLTexture(id<MTLTexture> texture, const cv::Mat &data, NSUInteger slice,
                            NSUInteger mipmapLevel) {
  PNKCopyMatToMTLTextureRegion(texture, MTLRegionMake2D(0, 0, texture.width, texture.height),
                               data, slice, mipmapLevel);
}

NSUInteger PNKChannelCountForTexture(id<MTLTexture> texture) {
  auto pixelFormat = kMTLPixelFormatToMatInfo.find(texture.pixelFormat);
  LTParameterAssert(pixelFormat != kMTLPixelFormatToMatInfo.end(),
                    @"Pixel format type is not supported: %lu",
                    (unsigned long)texture.pixelFormat);
  int cvType = pixelFormat->second;
  int channels = (cvType >> CV_CN_SHIFT) + 1;
  return channels * texture.arrayLength;
}

NS_ASSUME_NONNULL_END
