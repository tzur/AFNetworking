// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// Components of a pixel format.
typedef NS_ENUM(NSUInteger, LTGLPixelComponents) {
  LTGLPixelComponentsR,
  LTGLPixelComponentsRG,
  LTGLPixelComponentsRGBA
};

/// Bit depth of each component of a pixel format.
typedef NS_ENUM(NSUInteger, LTGLPixelBitDepth) {
  LTGLPixelBitDepth8,
  LTGLPixelBitDepth16,
  LTGLPixelBitDepth32
};

/// Data type of each component of a pixel format.
typedef NS_ENUM(NSUInteger, LTGLPixelDataType) {
  LTGLPixelDataTypeUnorm,
  LTGLPixelDataTypeFloat
};

NS_ENUM(int) {
  /// Invalid OpenCV matrix type.
  LTInvalidMatType = INT_MAX
};

NS_ENUM(GLenum) {
  /// Invalid OpenGL GLenum.
  LTGLInvalidEnum = UINT32_MAX
};

/// Describes the organization of color, depth, or stencil data storage in individual pixels of an
/// \c LTTexture or \c LTRenderbuffer objects.
LTEnumDeclare(NSUInteger, LTGLPixelFormat,
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

/// Holds \c cv::Mat types that are supported by \c LTGLPixelFormat.
typedef std::vector<int> LTGLPixelFormatSupportedMatTypes;

/// Additions for the basic enumeration type, including ways to initialize itself from external
/// properties, retrieving OpenGL types that are required for OpenGL object construction and
/// interaction with OpenCV and CoreVideo.
///
/// @note Currently, all defined pixel formats are supported by OpenGL and have a valid format,
/// precision and internal format.
@interface LTGLPixelFormat (Additions)

/// Initializes a new \c LTGLPixelFormat from an \c internalFormat and an OpenGL \c version. If no
/// pixel format can be derived from the \c internalFormat and the \c version, an assert will be
/// raised.
- (instancetype)initWithInternalFormat:(GLenum)internalFormat version:(LTGLVersion)version;

/// Initializes a new \c LTGLPixelFormat from an \c cv::Mat type. If no pixel format can be derived
/// from \c matType, an assert will be raised.
- (instancetype)initWithMatType:(int)matType;

/// Returns a vector of the supported \c cv::Mat types via \c -[LTGLPixelFormat initWithMatType:].
+ (LTGLPixelFormatSupportedMatTypes)supportedMatTypes;

/// OpenGL format for the given OpenGL \c version, or \c LTGLInvalidEnum if no such format is
/// available.
- (GLenum)formatForVersion:(LTGLVersion)version;

/// OpenGL precision for the given OpenGL \c version, or \c LTGLInvalidEnum if no such precision is
/// available.
- (GLenum)precisionForVersion:(LTGLVersion)version;

/// OpenGL internal format for the given OpenGL \c version, or \c LTGLInvalidEnum if no such
/// internal format is available.
- (GLenum)internalFormatForVersion:(LTGLVersion)version;

/// Components of the pixel format.
@property (readonly, nonatomic) LTGLPixelComponents components;

/// Bit depth of each component of the pixel format.
@property (readonly, nonatomic) LTGLPixelBitDepth bitDepth;

/// Data type of each component of the pixel format.
@property (readonly, nonatomic) LTGLPixelDataType dataType;

/// OpenCV type of \c cv::Mat that backs the pixel format or \c LTInvalidMatType if no such type is
/// found.
@property (readonly, nonatomic) int matType;

/// CoreVideo type of pixel format type that is compatible with the pixel format or \c kUnknownType
/// if no compatible type is found.
@property (readonly, nonatomic) OSType cvPixelFormatType;

@end

NS_ASSUME_NONNULL_END
