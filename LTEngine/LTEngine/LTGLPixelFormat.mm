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
  LTGLPixelFormatRGBA32Float,
  LTGLPixelFormatDepth16Unorm
);

/// Unordered map with \c lt::hash as hashing function.
template <typename K, typename V>
using LTUnorderedMap = std::unordered_map<K, V, std::hash<K>>;

/// Tuple of (components, data type) that describes the pixel format.
typedef std::tuple<LTGLPixelComponents, LTGLPixelDataType> LTDescriptorTuple;

/// Maps from pixel format to its descriptor.
static const LTUnorderedMap<_LTGLPixelFormat, LTDescriptorTuple> kFormatToDescriptor{
  {LTGLPixelFormatR8Unorm, {LTGLPixelComponentsR, LTGLPixelDataType8Unorm}},
  {LTGLPixelFormatR16Float, {LTGLPixelComponentsR, LTGLPixelDataType16Float}},
  {LTGLPixelFormatR32Float, {LTGLPixelComponentsR, LTGLPixelDataType32Float}},
  {LTGLPixelFormatRG8Unorm, {LTGLPixelComponentsRG, LTGLPixelDataType8Unorm}},
  {LTGLPixelFormatRG16Float, {LTGLPixelComponentsRG, LTGLPixelDataType16Float}},
  {LTGLPixelFormatRG32Float, {LTGLPixelComponentsRG, LTGLPixelDataType32Float}},
  {LTGLPixelFormatRGBA8Unorm, {LTGLPixelComponentsRGBA, LTGLPixelDataType8Unorm}},
  {LTGLPixelFormatRGBA16Float, {LTGLPixelComponentsRGBA, LTGLPixelDataType16Float}},
  {LTGLPixelFormatRGBA32Float, {LTGLPixelComponentsRGBA, LTGLPixelDataType32Float}},
  {LTGLPixelFormatDepth16Unorm, {LTGLPixelComponentsDepth, LTGLPixelDataType16Unorm}},
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
  {{LTGLVersion3, LTGLPixelComponentsRGBA}, GL_RGBA},
  {{LTGLVersion2, LTGLPixelComponentsDepth}, GL_DEPTH_COMPONENT},
  {{LTGLVersion3, LTGLPixelComponentsDepth}, GL_DEPTH_COMPONENT}
};

/// Pair of (version, data type).
typedef std::pair<LTGLVersion, LTGLPixelDataType> LTPixelDataTypePair;

/// Maps from data type pair to OpenGL type, which specifies the data type of pixel's data.
static const LTUnorderedMap<LTPixelDataTypePair, GLenum> kBitDepthToPrecision{
  {{LTGLVersion2, LTGLPixelDataType8Unorm}, GL_UNSIGNED_BYTE},
  {{LTGLVersion3, LTGLPixelDataType8Unorm}, GL_UNSIGNED_BYTE},
  {{LTGLVersion2, LTGLPixelDataType16Float}, GL_HALF_FLOAT_OES},
  {{LTGLVersion3, LTGLPixelDataType16Float}, GL_HALF_FLOAT},
  {{LTGLVersion3, LTGLPixelDataType16Unorm}, GL_UNSIGNED_INT},
  {{LTGLVersion2, LTGLPixelDataType32Float}, GL_FLOAT},
  {{LTGLVersion3, LTGLPixelDataType32Float}, GL_FLOAT}
};

/// Pair of (version, pixel format).
typedef std::pair<LTGLVersion, _LTGLPixelFormat> LTPixelFormatPair;

/// Maps from pixel format pair to OpenGL texture internal format. Note that when a new pixel format
/// is added, the number of entries that will added to this table should be equal to the number of
/// supported OpenGL versions.
static const LTUnorderedMap<LTPixelFormatPair, GLenum> kFormatToTextureInternalFormat{
  {{LTGLVersion2, LTGLPixelFormatR8Unorm}, GL_RED_EXT},
  {{LTGLVersion3, LTGLPixelFormatR8Unorm}, GL_R8},
  {{LTGLVersion2, LTGLPixelFormatDepth16Unorm}, GL_DEPTH_COMPONENT16},
  {{LTGLVersion3, LTGLPixelFormatDepth16Unorm}, GL_DEPTH_COMPONENT16},
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
  {{LTGLVersion2, LTGLPixelFormatDepth16Unorm}, GL_DEPTH_COMPONENT16},
  {{LTGLVersion3, LTGLPixelFormatDepth16Unorm}, GL_DEPTH_COMPONENT16}
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

/// Maps between \c cv::Mat \c type to pixel format.
static const std::unordered_map<int, _LTGLPixelFormat> kMatTypeToPixelFormat{
  {CV_8UC1, LTGLPixelFormatR8Unorm},
  {CV_16UC1, LTGLPixelFormatDepth16Unorm},
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
  {kCVPixelFormatType_16Gray, LTGLPixelFormatDepth16Unorm},
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

/// Maps between \c cv::Mat \c type to \c CIFormat.
static const std::unordered_map<int, CIFormat> kMatTypeToCIFormat{
  {CV_8UC1, kCIFormatR8},
  {CV_16FC1, kCIFormatRh},
  {CV_32FC1, kCIFormatRf},
  {CV_8UC2, kCIFormatRG8},
  {CV_16FC2, kCIFormatRGh},
  {CV_32FC2, kCIFormatRGf},
  {CV_8UC4, kCIFormatRGBA8},
  {CV_16FC4, kCIFormatRGBAh},
  {CV_32FC4, kCIFormatRGBAf},
  {CV_16UC1, kCIFormatR16}
};

/// Maps between CoreVideo pixel format (CVPixelFormatType) to \c CIFormat.
static const std::unordered_map<OSType, CIFormat> kCVPixelBufferTypeToCIFormat{
  {kCVPixelFormatType_OneComponent8, kCIFormatR8},
  {kCVPixelFormatType_OneComponent16Half, kCIFormatRh},
  {kCVPixelFormatType_OneComponent32Float, kCIFormatRf},
  {kCVPixelFormatType_TwoComponent8, kCIFormatRG8},
  {kCVPixelFormatType_TwoComponent16Half, kCIFormatRGh},
  {kCVPixelFormatType_TwoComponent32Float, kCIFormatRGf},
  {kCVPixelFormatType_32BGRA, kCIFormatBGRA8},
  {kCVPixelFormatType_64RGBAHalf, kCIFormatRGBAh},
  {kCVPixelFormatType_128RGBAFloat, kCIFormatRGBAf},
  {kCVPixelFormatType_16Gray, kCIFormatR16}
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

- (instancetype)initWithComponents:(LTGLPixelComponents)components
                          dataType:(LTGLPixelDataType)dataType {
  for (const auto &pair : kFormatToDescriptor) {
    if (pair.second == LTDescriptorTuple{components, dataType}) {
      return [self initWithValue:pair.first];
    }
  }
  LTAssert(NO, @"No pixel format value was found for the given components (%lu) and dataType (%lu)",
           (unsigned long)components, (unsigned long)dataType);
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
  const auto it = kBitDepthToPrecision.find({version, self.dataType});
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

- (NSUInteger)channels {
  switch (self.components) {
    case LTGLPixelComponentsR:
    case LTGLPixelComponentsDepth:
      return 1;
    case LTGLPixelComponentsRG:
      return 2;
    case LTGLPixelComponentsRGBA:
      return 4;
  }
}

- (LTGLPixelDataType)dataType {
  return std::get<1>(self.descriptor);
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

- (CIFormat)ciFormatForMatType {
  const auto it = kMatTypeToCIFormat.find(self.matType);
  return it != kMatTypeToCIFormat.cend() ? it->second : kUnknownType;
}

- (CIFormat)ciFormatForCVPixelFormatType {
  const auto it = kCVPixelBufferTypeToCIFormat.find(self.cvPixelFormatType);
  return it != kCVPixelBufferTypeToCIFormat.cend() ? it->second : kUnknownType;
}

@end

NS_ASSUME_NONNULL_END
