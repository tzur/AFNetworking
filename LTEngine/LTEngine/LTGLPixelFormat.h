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

/// Holds CVPixelFormatType's that are supported by \c LTGLPixelFormat.
typedef std::vector<OSType> LTGLPixelFormatSupportedCVPixelFormatTypes;

/// Additions for the basic enumeration type, including ways to initialize itself from external
/// properties, retrieving OpenGL types that are required for OpenGL object construction and
/// interaction with OpenCV and CoreVideo.
///
/// @note Currently, all defined pixel formats are supported by OpenGL and have a valid format,
/// precision and texture internal format. For renderbuffers, only the \c LTGLPixelFormatRGBA8Unorm
/// format is supported.
@interface LTGLPixelFormat (Additions)

/// Initializes a new \c LTGLPixelFormat from a texture \c internalFormat and an OpenGL \c version.
/// If no pixel format can be derived from the \c internalFormat and the \c version, an assert will
/// be raised.
- (instancetype)initWithTextureInternalFormat:(GLenum)internalFormat version:(LTGLVersion)version;

/// Initializes a new \c LTGLPixelFormat from a renderbuffer \c internalFormat and an OpenGL
/// \c version. If no pixel format can be derived from the \c internalFormat and the \c version, an
/// assert will be raised.
- (instancetype)initWithRenderbufferInternalFormat:(GLenum)internalFormat
                                           version:(LTGLVersion)version;

/// Initializes a new \c LTGLPixelFormat from an \c cv::Mat type. If no pixel format can be derived
/// from \c matType, an assert will be raised.
- (instancetype)initWithMatType:(int)matType;

/// Initializes a new \c LTGLPixelFormat from a CVPixelFormatType. If no pixel format can be derived
/// from \c cvPixelFormatType, an assert will be raised.
- (instancetype)initWithCVPixelFormatType:(OSType)cvPixelFormatType;

/// Initializes a new \c LTGLPixelFormat from a planar CVPixelFormatType, using the pixel format of
/// the plane with the given index. If no pixel format can be derived from \c cvPixelFormatType and
/// the given \c planeIndex, an assert will be raised.
- (instancetype)initWithPlanarCVPixelFormatType:(OSType)cvPixelFormatType
                                     planeIndex:(size_t)planeIndex;

/// Initializes a pixel format from \c components, \c bitDepth and \c dataType.
- (instancetype)initWithComponents:(LTGLPixelComponents)components
                          bitDepth:(LTGLPixelBitDepth)bitDepth
                          dataType:(LTGLPixelDataType)dataType;

/// Returns a vector of the supported \c cv::Mat types via \c -[LTGLPixelFormat initWithMatType:].
+ (LTGLPixelFormatSupportedMatTypes)supportedMatTypes;

/// Returns a vector of the supported CVPixelFormatType types via
/// \c -[LTGLPixelFormat initWithCVPixelFormatType:].
+ (LTGLPixelFormatSupportedCVPixelFormatTypes)supportedCVPixelFormatTypes;

/// Returns a vector of the supported planar CVPixelFormatType types via
/// \c -[LTGLPixelFormat initWithCVPixelFormatType:planeIndex:].
+ (LTGLPixelFormatSupportedCVPixelFormatTypes)supportedPlanarCVPixelFormatTypes;

/// OpenGL format for the given OpenGL \c version, or \c LTGLInvalidEnum if no such format is
/// available.
- (GLenum)formatForVersion:(LTGLVersion)version;

/// OpenGL precision for the given OpenGL \c version, or \c LTGLInvalidEnum if no such precision is
/// available.
- (GLenum)precisionForVersion:(LTGLVersion)version;

/// OpenGL texture internal format for the given OpenGL \c version, or \c LTGLInvalidEnum if no such
/// internal format is available.
- (GLenum)textureInternalFormatForVersion:(LTGLVersion)version;

/// OpenGL renderbuffer internal format for the given OpenGL \c version, or \c LTGLInvalidEnum if no
/// such internal format is available.
- (GLenum)renderbufferInternalFormatForVersion:(LTGLVersion)version;

/// Components of the pixel format.
@property (readonly, nonatomic) LTGLPixelComponents components;

/// Returns the number of channels of the pixel format.
@property (readonly, nonatomic) NSUInteger channels;

/// Bit depth of each component of the pixel format.
@property (readonly, nonatomic) LTGLPixelBitDepth bitDepth;

/// Data type of each component of the pixel format.
@property (readonly, nonatomic) LTGLPixelDataType dataType;

/// OpenCV type of \c cv::Mat that backs the pixel format or \c LTInvalidMatType if no such type is
/// found.
@property (readonly, nonatomic) int matType;

/// Core Video type of pixel format type that is compatible with the pixel format or \c kUnknownType
/// if no compatible type is found.
@property (readonly, nonatomic) OSType cvPixelFormatType;

/// Core Image format that is compatible with \c matType or \c kUnknownType if no compatible type is
/// found.
@property (readonly, nonatomic) CIFormat ciFormatForMatType;

/// Core Image format that is compatible with \c cvPixelFormatType or \c kUnknownType if no
/// compatible type is found.
@property (readonly, nonatomic) CIFormat ciFormatForCVPixelFormatType;

@end

NS_ASSUME_NONNULL_END
