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
using LTUnorderedMap = std::unordered_map<K, V, std::hash<K>>;

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
  LTParameterAssert(kMatTypeToPixelFormat.count(type), @"Given mat type %d doesn't have a "
                    "matching internal format", type);
  return kMatTypeToPixelFormat.at(type);
}

/// Maps between CoreVideo pixel format (CVPixelFormatType) to pixel format.
static const std::unordered_map<OSType, _LTGLPixelFormat> kCVPixelFormatTypeToPixelFormat{
  {kCVPixelFormatType_OneComponent8, LTGLPixelFormatR8Unorm},
  {kCVPixelFormatType_OneComponent16Half, LTGLPixelFormatR16Float},
  {kCVPixelFormatType_OneComponent32Float, LTGLPixelFormatR32Float},
  {kCVPixelFormatType_TwoComponent8, LTGLPixelFormatRG8Unorm},
  {kCVPixelFormatType_TwoComponent16Half, LTGLPixelFormatRG16Float},
  {kCVPixelFormatType_TwoComponent32Float, LTGLPixelFormatRG32Float},
  {kCVPixelFormatType_32BGRA, LTGLPixelFormatRGBA8Unorm},
  {kCVPixelFormatType_64RGBAHalf, LTGLPixelFormatRGBA16Float},
  {kCVPixelFormatType_128RGBAFloat, LTGLPixelFormatRGBA32Float}
};

/// Maps between planar CoreVideo pixel format (CVPixelFormatType) to a vector of pixel formats, one
/// for each plane.
static const std::unordered_map<OSType, std::vector<_LTGLPixelFormat>>
    kPlanarCVPixelFormatTypeToPixelFormats{
  {kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
    {LTGLPixelFormatR8Unorm, LTGLPixelFormatRG8Unorm}},
  {kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
    {LTGLPixelFormatR8Unorm, LTGLPixelFormatRG8Unorm}},
  {kCVPixelFormatType_420YpCbCr8Planar,
    {LTGLPixelFormatR8Unorm, LTGLPixelFormatR8Unorm, LTGLPixelFormatR8Unorm}},
  {kCVPixelFormatType_420YpCbCr8PlanarFullRange,
    {LTGLPixelFormatR8Unorm, LTGLPixelFormatR8Unorm, LTGLPixelFormatR8Unorm}},
};

/// Returns the pixel format that corresponds to the given CVPixelFormatType. Asserts if no such
/// format is found.
static _LTGLPixelFormat LTGLPixelFormatForCVPixelFormatType(OSType type) {
  LTParameterAssert(kCVPixelFormatTypeToPixelFormat.count(type),
                    @"Given CVPixelFormatType 0x%08X doesn't have a matching internal format",
                    (unsigned int)type);
  return kCVPixelFormatTypeToPixelFormat.at(type);
}

/// Returns the pixel format that corresponds to the given CVPixelFormatType. Asserts if no such
/// format is found.
static _LTGLPixelFormat LTGLPixelFormatForPlanarCVPixelFormatType(OSType type, size_t planeIndex) {
  LTParameterAssert(kPlanarCVPixelFormatTypeToPixelFormats.count(type),
                    @"Given CVPixelFormatType 0x%08X doesn't have a matching internal format",
                    (unsigned int)type);

  const auto &planes = kPlanarCVPixelFormatTypeToPixelFormats.at(type);
  LTParameterAssert(planeIndex < planes.size(),
                    @"Given CVPixelFormatType %08X doesn't have a plane with index %zu",
                    (unsigned int)type, planeIndex);

  return planes[planeIndex];
}

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

- (instancetype)initWithCVPixelFormatType:(OSType)cvPixelFormatType {
  _LTGLPixelFormat pixelFormat = LTGLPixelFormatForCVPixelFormatType(cvPixelFormatType);
  return [self initWithValue:pixelFormat];
}

- (instancetype)initWithPlanarCVPixelFormatType:(OSType)cvPixelFormatType
                                     planeIndex:(size_t)planeIndex {
  _LTGLPixelFormat pixelFormat = LTGLPixelFormatForPlanarCVPixelFormatType(cvPixelFormatType,
                                                                           planeIndex);
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

+ (LTGLPixelFormatSupportedCVPixelFormatTypes)supportedCVPixelFormatTypes {
  static LTGLPixelFormatSupportedCVPixelFormatTypes supportedTypes;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supportedTypes.resize(kCVPixelFormatTypeToPixelFormat.size());
    std::transform(kCVPixelFormatTypeToPixelFormat.cbegin(), kCVPixelFormatTypeToPixelFormat.cend(),
                   supportedTypes.begin(), [](auto keyValuePair) {
                     return keyValuePair.first;
                   });
  });

  return supportedTypes;
}

+ (LTGLPixelFormatSupportedCVPixelFormatTypes)supportedPlanarCVPixelFormatTypes {
  static LTGLPixelFormatSupportedCVPixelFormatTypes supportedTypes;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supportedTypes.resize(kPlanarCVPixelFormatTypeToPixelFormats.size());
    std::transform(kPlanarCVPixelFormatTypeToPixelFormats.cbegin(),
                   kPlanarCVPixelFormatTypeToPixelFormats.cend(),
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
  LTAssert(kFormatToDescriptor.count(self.value), @"No descriptor found for pixel format %@", self);
  return kFormatToDescriptor.at(self.value);
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
  for (const auto &pair : kCVPixelFormatTypeToPixelFormat) {
    if (pair.second == self.value) {
      return pair.first;
    }
  }
  return kUnknownType;
}

@end

NS_ASSUME_NONNULL_END
