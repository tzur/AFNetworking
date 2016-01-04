// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLPixelFormat.h"

#import <LTKit/LTHashExtensions.h>

#import "LTOpenCVHalfFloat.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTGLPixelFormat,
  LTGLPixelFormatR8Unorm, 
  LTGLPixelFormatR16Float, 
  LTGLPixelFormatR32Float, 
  LTGLPixelFormatRG8Unorm, 
  LTGLPixelFormatRG16Float, 
  LTGLPixelFormatRG32Float, 
  LTGLPixelFormatRGBA8Unorm, 
  LTGLPixelFormatRGBA16Float,
  LTGLPixelFormatRGBA32Float
);

/// Unordered map with \c lt::hash as hashing function.
template <typename K, typename V>
using LTUnorderedMap = std::unordered_map<K, V, lt::hash<K>>;

/// Tuple of (components, bit depth, data type) that describes the pixel format.
typedef std::tuple<LTGLPixelComponents, LTGLPixelBitDepth, LTGLPixelDataType> LTDescriptorTuple;

/// Maps from pixel format to its descriptor.
static const LTUnorderedMap<_LTGLPixelFormat, LTDescriptorTuple> kFormatToDescriptor{
  {LTGLPixelFormatR8Unorm,
    {LTGLPixelComponentsR, LTGLPixelBitDepth8, LTGLPixelDataTypeUnorm}},
  {LTGLPixelFormatR16Float,
    {LTGLPixelComponentsR, LTGLPixelBitDepth16, LTGLPixelDataTypeFloat}},
  {LTGLPixelFormatR32Float,
    {LTGLPixelComponentsR, LTGLPixelBitDepth32, LTGLPixelDataTypeFloat}},
  {LTGLPixelFormatRG8Unorm,
    {LTGLPixelComponentsRG, LTGLPixelBitDepth8, LTGLPixelDataTypeUnorm}},
  {LTGLPixelFormatRG16Float,
    {LTGLPixelComponentsRG, LTGLPixelBitDepth16, LTGLPixelDataTypeFloat}},
  {LTGLPixelFormatRG32Float,
    {LTGLPixelComponentsRG, LTGLPixelBitDepth32, LTGLPixelDataTypeFloat}},
  {LTGLPixelFormatRGBA8Unorm,
    {LTGLPixelComponentsRGBA, LTGLPixelBitDepth8, LTGLPixelDataTypeUnorm}},
  {LTGLPixelFormatRGBA16Float,
    {LTGLPixelComponentsRGBA, LTGLPixelBitDepth16, LTGLPixelDataTypeFloat}},
  {LTGLPixelFormatRGBA32Float,
    {LTGLPixelComponentsRGBA, LTGLPixelBitDepth32, LTGLPixelDataTypeFloat}}
};

/// Pair of (version, components).
typedef std::pair<LTGLVersion, LTGLPixelComponents> LTPixelComponentsPair;

/// Maps from components pair to OpenGL format. Note that when a new pixel format is added, the
/// number of entries that will added to this table should be equal to the number of supported
/// OpenGL versions.
///
/// @note when there's a discrepancy between the format of a renderbuffer and a texture, the format
/// of texture will be used. This is because right now we use the pixel format solely for textures
/// and not renderbuffers, which are allocated by Core Animation.
static const LTUnorderedMap<LTPixelComponentsPair, GLenum> kComponentsToFormat{
  {{LTGLVersion2, LTGLPixelComponentsR}, GL_RED_EXT},
  {{LTGLVersion3, LTGLPixelComponentsR}, GL_RED},
  {{LTGLVersion2, LTGLPixelComponentsRG}, GL_RG_EXT},
  {{LTGLVersion3, LTGLPixelComponentsRG}, GL_RG},
  {{LTGLVersion2, LTGLPixelComponentsRGBA}, GL_RGBA},
  {{LTGLVersion3, LTGLPixelComponentsRGBA}, GL_RGBA}
};

/// Pair of (version, bit depth).
typedef std::pair<LTGLVersion, LTGLPixelBitDepth> LTPixelBitDepthPair;

/// Maps from bit depth pair to OpenGL precision. Note that when a new pixel format is added, the
/// number of entries that will added to this table should be equal to the number of supported
/// OpenGL versions.
static const LTUnorderedMap<LTPixelBitDepthPair, GLenum> kBitDepthToPrecision{
  {{LTGLVersion2, LTGLPixelBitDepth8}, GL_UNSIGNED_BYTE},
  {{LTGLVersion3, LTGLPixelBitDepth8}, GL_UNSIGNED_BYTE},
  {{LTGLVersion2, LTGLPixelBitDepth16}, GL_HALF_FLOAT_OES},
  {{LTGLVersion3, LTGLPixelBitDepth16}, GL_HALF_FLOAT},
  {{LTGLVersion2, LTGLPixelBitDepth32}, GL_FLOAT},
  {{LTGLVersion3, LTGLPixelBitDepth32}, GL_FLOAT}
};

/// Pair of (version, pixel format).
typedef std::pair<LTGLVersion, _LTGLPixelFormat> LTPixelFormatPair;

/// Maps from pixel format pair to OpenGL texture internal format. Note that when a new pixel format
/// is added, the number of entries that will added to this table should be equal to the number of
/// supported OpenGL versions.
static const LTUnorderedMap<LTPixelFormatPair, GLenum> kFormatToTextureInternalFormat{
  {{LTGLVersion2, LTGLPixelFormatR8Unorm}, GL_RED_EXT},
  {{LTGLVersion3, LTGLPixelFormatR8Unorm}, GL_R8},
  {{LTGLVersion2, LTGLPixelFormatR16Float}, GL_RED_EXT},
  {{LTGLVersion3, LTGLPixelFormatR16Float}, GL_R16F},
  {{LTGLVersion2, LTGLPixelFormatR32Float}, GL_RED_EXT},
  {{LTGLVersion3, LTGLPixelFormatR32Float}, GL_R32F},
  {{LTGLVersion2, LTGLPixelFormatRG8Unorm}, GL_RG_EXT},
  {{LTGLVersion3, LTGLPixelFormatRG8Unorm}, GL_RG8},
  {{LTGLVersion2, LTGLPixelFormatRG16Float}, GL_RG_EXT},
  {{LTGLVersion3, LTGLPixelFormatRG16Float}, GL_RG16F},
  {{LTGLVersion2, LTGLPixelFormatRG32Float}, GL_RG_EXT},
  {{LTGLVersion3, LTGLPixelFormatRG32Float}, GL_RG32F},
  {{LTGLVersion2, LTGLPixelFormatRGBA8Unorm}, GL_RGBA},
  {{LTGLVersion3, LTGLPixelFormatRGBA8Unorm}, GL_RGBA8},
  {{LTGLVersion2, LTGLPixelFormatRGBA16Float}, GL_RGBA},
  {{LTGLVersion3, LTGLPixelFormatRGBA16Float}, GL_RGBA16F},
  {{LTGLVersion2, LTGLPixelFormatRGBA32Float}, GL_RGBA},
  {{LTGLVersion3, LTGLPixelFormatRGBA32Float}, GL_RGBA32F}
};

/// Maps from pixel format pair to OpenGL renderbuffer internal format. Note that when a new pixel
/// format is added, the number of entries that will added to this table should be equal to the
/// number of supported OpenGL versions.
static const LTUnorderedMap<LTPixelFormatPair, GLenum> kFormatToRenderbufferInternalFormat{
  {{LTGLVersion2, LTGLPixelFormatRGBA8Unorm}, GL_RGBA8_OES},
  {{LTGLVersion3, LTGLPixelFormatRGBA8Unorm}, GL_RGBA8},
};

/// Returns the pixel format that corresponds to the given texture \c internalFormat and \c version.
/// Asserts if no such format is found.
static _LTGLPixelFormat LTGLPixelFormatForTextureInternalFormat(GLenum internalFormat,
                                                                LTGLVersion version) {
  for (const auto &pair : kFormatToTextureInternalFormat) {
    if (pair.second == internalFormat && pair.first.first == version) {
      return pair.first.second;
    }
  }

  LTParameterAssert(NO, @"No pixel format was found for the texture internal format %lu, "
                    "version %lu", (unsigned long)internalFormat, (unsigned long)version);
}

/// Returns the pixel format that corresponds to the given renderbuffer \c internalFormat and
/// \c version. Asserts if no such format is found.
static _LTGLPixelFormat LTGLPixelFormatForRenderbufferInternalFormat(GLenum internalFormat,
                                                                     LTGLVersion version) {
  for (const auto &pair : kFormatToRenderbufferInternalFormat) {
    if (pair.second == internalFormat && pair.first.first == version) {
      return pair.first.second;
    }
  }

  LTParameterAssert(NO, @"No pixel format was found for the renderbuffer internal format %lu, "
                    "version %lu", (unsigned long)internalFormat, (unsigned long)version);
}

/// Maps between pixel format pair to OpenGL internal format.
static const std::unordered_map<int, _LTGLPixelFormat> kMatTypeToPixelFormat{
  {CV_8UC1, LTGLPixelFormatR8Unorm},
  {CV_16FC1, LTGLPixelFormatR16Float},
  {CV_32FC1, LTGLPixelFormatR32Float},
  {CV_8UC2, LTGLPixelFormatRG8Unorm},
  {CV_16FC2, LTGLPixelFormatRG16Float},
  {CV_32FC2, LTGLPixelFormatRG32Float},
  {CV_8UC4, LTGLPixelFormatRGBA8Unorm},
  {CV_16FC4, LTGLPixelFormatRGBA16Float},
  {CV_32FC4, LTGLPixelFormatRGBA32Float}
};

/// Returns the pixel format that corresponds to the given \c cv::Mat \c type. Asserts if no such
/// format is found.
static _LTGLPixelFormat LTGLPixelFormatForMatType(int type) {
  const auto it = kMatTypeToPixelFormat.find(type);
  LTParameterAssert(it != kMatTypeToPixelFormat.cend(), @"Given mat type %d doesn't have a "
                    "matching internal format", type);
  return it->second;
}

/// Maps between pixel format to CoreVideo pixel format.
static const std::unordered_map<int, GLenum> kPixelFormatToCoreVideoPixelFormat{
  {LTGLPixelFormatR8Unorm, kCVPixelFormatType_OneComponent8},
  {LTGLPixelFormatR16Float, kCVPixelFormatType_OneComponent16Half},
  {LTGLPixelFormatR32Float, kCVPixelFormatType_OneComponent32Float},
  {LTGLPixelFormatRG8Unorm, kCVPixelFormatType_TwoComponent8},
  {LTGLPixelFormatRG16Float, kCVPixelFormatType_TwoComponent16Half},
  {LTGLPixelFormatRG32Float, kCVPixelFormatType_TwoComponent32Float},
  {LTGLPixelFormatRGBA8Unorm, kCVPixelFormatType_32BGRA},
  {LTGLPixelFormatRGBA16Float, kCVPixelFormatType_64RGBAHalf},
  {LTGLPixelFormatRGBA32Float, kCVPixelFormatType_128RGBAFloat}
};

@implementation LTGLPixelFormat (Additions)

- (instancetype)initWithTextureInternalFormat:(GLenum)internalFormat version:(LTGLVersion)version {
  _LTGLPixelFormat pixelFormat = LTGLPixelFormatForTextureInternalFormat(internalFormat, version);
  return [self initWithValue:pixelFormat];
}

- (instancetype)initWithRenderbufferInternalFormat:(GLenum)internalFormat
                                           version:(LTGLVersion)version {
  _LTGLPixelFormat pixelFormat = LTGLPixelFormatForRenderbufferInternalFormat(internalFormat,
                                                                              version);
  return [self initWithValue:pixelFormat];
}

- (instancetype)initWithMatType:(int)matType {
  _LTGLPixelFormat pixelFormat = LTGLPixelFormatForMatType(matType);
  return [self initWithValue:pixelFormat];
}

+ (LTGLPixelFormatSupportedMatTypes)supportedMatTypes {
  static LTGLPixelFormatSupportedMatTypes supportedTypes;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supportedTypes.resize(kMatTypeToPixelFormat.size());
    std::transform(kMatTypeToPixelFormat.cbegin(), kMatTypeToPixelFormat.cend(),
                   supportedTypes.begin(), [](auto keyValuePair) {
                     return keyValuePair.first;
                   });
  });

  return supportedTypes;
}

- (GLenum)formatForVersion:(LTGLVersion)version {
  const auto it = kComponentsToFormat.find({version, self.components});
  return it != kComponentsToFormat.cend() ? it->second : LTGLInvalidEnum;
}

- (GLenum)precisionForVersion:(LTGLVersion)version {
  const auto it = kBitDepthToPrecision.find({version, self.bitDepth});
  return it != kBitDepthToPrecision.cend() ? it->second : LTGLInvalidEnum;
}

- (GLenum)textureInternalFormatForVersion:(LTGLVersion)version {
  const auto it = kFormatToTextureInternalFormat.find({version, self.value});
  return it != kFormatToTextureInternalFormat.cend() ? it->second : LTGLInvalidEnum;
}

- (GLenum)renderbufferInternalFormatForVersion:(LTGLVersion)version {
  const auto it = kFormatToRenderbufferInternalFormat.find({version, self.value});
  return it != kFormatToRenderbufferInternalFormat.cend() ? it->second : LTGLInvalidEnum;
}

- (LTDescriptorTuple)descriptor {
  const auto it = kFormatToDescriptor.find(self.value);
  LTAssert(it != kFormatToDescriptor.cend(), @"No descriptor found for pixel format %@", self);
  return it->second;
}

- (LTGLPixelComponents)components {
  return std::get<0>(self.descriptor);
}

- (LTGLPixelBitDepth)bitDepth {
  return std::get<1>(self.descriptor);
}

- (LTGLPixelDataType)dataType {
  return std::get<2>(self.descriptor);
}

- (int)matType {
  for (const auto &pair : kMatTypeToPixelFormat) {
    if (pair.second == self.value) {
      return pair.first;
    }
  }
  return LTInvalidMatType;
}

- (OSType)cvPixelFormatType {
  const auto it = kPixelFormatToCoreVideoPixelFormat.find(self.value);
  return it != kPixelFormatToCoreVideoPixelFormat.cend() ? it->second : kUnknownType;
}

@end

NS_ASSUME_NONNULL_END
