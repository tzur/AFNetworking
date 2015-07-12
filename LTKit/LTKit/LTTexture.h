// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

/// Precision of each channel of the texture on the GPU.
typedef NS_ENUM(GLenum, LTTexturePrecision) {
  LTTexturePrecisionByte = GL_UNSIGNED_BYTE,
  LTTexturePrecisionHalfFloat = GL_HALF_FLOAT_OES,
  LTTexturePrecisionFloat = GL_FLOAT
};

/// Type of interpolation used by the sampler on the GPU.
typedef NS_ENUM(GLenum, LTTextureInterpolation) {
  /// Nearest neighbor interpolation.
  LTTextureInterpolationNearest = GL_NEAREST,
  /// Linear interpolation.
  LTTextureInterpolationLinear = GL_LINEAR,
  /// Nearest neighbor interpolation with nearest neighbor across mipmap levels.
  LTTextureInterpolationNearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
  /// Nearest neighbor with nearest linear interpolation across mipmap levels.
  LTTextureInterpolationNearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
  /// Linear interpolation with nearest neighbor across mipmap levels.
  LTTextureInterpolationLinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
  /// Linear interpolation with linear interpolation across mipmap levels (trilinear filtering).
  LTTextureInterpolationLinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR
};

/// Type of wraping used by the sampler for texture coodinates outside [0, 1].
typedef NS_ENUM(GLenum, LTTextureWrap) {
  /// Clamp texture coordinates.
  LTTextureWrapClamp = GL_CLAMP_TO_EDGE,
  /// Wrap texture coordinates cyclically.
  LTTextureWrapRepeat = GL_REPEAT
};

/// Number of channels stored in the texture.
typedef NS_ENUM(NSUInteger, LTTextureChannels) {
  /// Single channel.
  LTTextureChannelsOne = 1,
  /// Two channels.
  LTTextureChannelsTwo = 2,
  /// Four channels.
  LTTextureChannelsFour = 4
};

/// Format the texture is stored in the GPU.
typedef NS_ENUM(GLenum, LTTextureFormat) {
  /// Single, red channel only.
  LTTextureFormatRed = GL_RED_EXT,
  /// Dual red and green channels.
  LTTextureFormatRG = GL_RG_EXT,
  /// All four channels.
  LTTextureFormatRGBA = GL_RGBA,
  /// Single channel, but values are replicated across the RGB channels, and alpha is always 1.
  LTTextureFormatLuminance = GL_LUMINANCE
};

/// Returns precision for a given \c cv::Mat type, or throws an \c LTGLException with \c
/// kLTTextureUnsupportedFormatException if the precision is invalid or unsupported.
LTTexturePrecision LTTexturePrecisionFromMatType(int type);

/// Returns precision for a given \c cv::Mat, or throws an \c LTGLException with \c
/// kLTTextureUnsupportedFormatException if the precision is invalid or unsupported.
LTTexturePrecision LTTexturePrecisionFromMat(const cv::Mat &image);

/// Returns number of channels for a given \c cv::Mat type, or throws an \c LTGLException with \c
/// kLTTextureUnsupportedFormatException if the number of channels is invalid or unsupported.
LTTextureChannels LTTextureChannelsFromMatType(int type);

/// Returns number of channels for a given \c cv::Mat, or throws an \c LTGLException with \c
/// kLTTextureUnsupportedFormatException if the number of channels is invalid or unsupported.
LTTextureChannels LTTextureChannelsFromMat(const cv::Mat &image);

/// Returns format for a given \c cv::Mat type.
LTTextureFormat LTTextureFormatFromMatType(int type);

/// Returns format for a given \c cv::Mat.
LTTextureFormat LTTextureFormatFromMat(const cv::Mat &image);

/// Returns a \c cv::Mat depth for the given \c precision.
int LTMatDepthForPrecision(LTTexturePrecision precision);

/// Returns a \c cv::Mat type for the given \c precision and \c channels.
int LTMatTypeForPrecisionAndChannels(LTTexturePrecision precision, LTTextureChannels channels);

/// Returns a \c cv::Mat type for the given \c precision and \c format.
int LTMatTypeForPrecisionAndFormat(LTTexturePrecision precision, LTTextureFormat format);

namespace cv {
  class Mat;
}

/// @class LTTexture
///
/// An abstract class representing a GPU-based texture. This class supports the texture CPU-GPU
/// interface of loading, updating and retrieving a texture.
///
/// @note Since in OpenGL textures (0, 0) is bottom left and there's a need to keep a single
/// coordinate system, the texture is flipped vertically to match UIKit's system. This means that
/// when using this class for drawing, updating and so on, (0, 0) represents the top left corner
/// of the texture.
///
/// @note The currently supported \c cv::Mat types are \c CV_32F (grayscale), \c CV32F_C4 (four
/// channel float), CV_16C4 (four channel half-float) and \c CV_8UC4 (RGBA).
@interface LTTexture : NSObject <LTGPUResource> {
  // This is required to prevent redeclaring \c name in subclasses.
  @protected
  GLuint _name;
}

#pragma mark -
#pragma mark Initializers
#pragma mark -

/// Creates an empty texture on the GPU.  Throws \c LTGLException with \c
/// kLTOpenGLRuntimeErrorException if texture creation failed.
///
/// @param size size of the texture. Must be integral.
/// @param precision precision of the texture.
/// @param format format the texture is stored in the GPU with. The format must be supported on the
/// target platform, or an \c NSInvalidArguemntException will be thrown.
/// @param allocateMemory an optimization recommendation to implementors of this class. If set to \c
/// YES, the texture's memory will be allocated on the GPU (but will not be initialized - see note).
/// Otherwise, the implementation will try to create a texture object only without allocating the
/// memory, and a call to \c load: or \c loadRect:fromImage: will be required to allocate memory on
/// the device.
///
/// @note The texture memory is not allocated until a call to \c load: or \c loadRect: is made, and
/// only the affected regions are set to be in a defined state. Calling \c storeRect:toImage: with
/// an uninitialized rect will return an undefined result.
///
/// @note Designated initializer.
- (instancetype)initWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                      format:(LTTextureFormat)format allocateMemory:(BOOL)allocateMemory;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture. Throws \c LTGLException with \c
/// kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has failed.
- (instancetype)initWithImage:(const cv::Mat &)image;

/// Creates a new byte precision, 4 channels RGBA texture with the given \c size and allocates its
/// memory. This is a convenience method which is similar to calling:
///
/// @code
/// [initWithSize:size precision:LTTexturePrecisionByte
///      channels:LTTextureChannelsRGBA allocateMemory:YES]
/// @endcode
- (instancetype)initByteRGBAWithSize:(CGSize)size;

/// Creates a new, allocated texture with \c size, \c precision and \c channels similar to the given
/// \c texture. This is a convenience method which is similar to calling:
///
/// @code
/// [initWithSize:texture.size precision:texture.precision
///      channels:texture.channels allocateMemory:YES]
/// @endcode
- (instancetype)initWithPropertiesOf:(LTTexture *)texture;

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

/// Creates the texture in the active OpenGL context. If the texture is already allocated, this
/// method has no effect.
///
/// @param allocateMemory if set to \c YES, the texture's memory will be allocated on the GPU (but
/// will not be initialized - see \c initWithSize:precision:channels:allocateMemory note).
/// Otherwise, only a texture object will be created, and a call to \c load: or \c
/// loadRect:fromImage: will be required to allocate memory on the device.
- (void)create:(BOOL)allocateMemory;

/// Releases the texture from the active OpenGL context. If the texture is already released, this
/// method has no effect.
- (void)destroy;

/// Stores the texture's data in the given \c rect to the given \c image. The image will be created
/// with the same precision and size of the given \c rect. The given \c rect must be contained in
/// the texture's rect (0, 0, size.width, size.height).
- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image;

/// Loads data from the given \c image to texture at the given \c rect. The image must have the same
/// precision as the texture's and the same size as the given \c rect. The rect must be contained in
/// the texture's rect (0, 0, size.width, size.height).
- (void)loadRect:(CGRect)rect fromImage:(const cv::Mat &)image;

/// Clones the texture. This creates a new texture with the same content, but with a different
/// OpenGL name. The cloning process tries to preserve the precision of the texture, according to
/// device limitations. This means that the cloned texture can be of lower precision than the
/// original. Float precision textures will always be converted to half-float (if supported by
/// device) or regular precision. Half-float precision textures will be converted to unsigned byte
/// precision if no support for half-float color buffers is available.
///
/// TODO:(yaron) the final precision is controlled by LTFbo, and as discussed with Amit, shouldn't
/// change since we can always use the slow cloning path.
- (LTTexture *)clone;

/// Clones the texture into the given texture. The target \c texture must be of the same size of the
/// receiver.
- (void)cloneTo:(LTTexture *)texture;

/// Marks a beginning of read operation from the texture.
///
/// @note prefers calls to \c readFromTexture: instead of calling \c beginReadFromTexture: and
/// \c endReadFromTexture:.
///
/// @see \c readFromTexture: for more information.
- (void)beginReadFromTexture;

/// Marks an ending of read operation from the texture.
///
/// @note prefers calls to \c readFromTexture: instead of calling \c beginReadFromTexture: and
/// \c endReadFromTexture:.
///
/// @see \c readFromTexture: for more information.
- (void)endReadFromTexture;

/// Marks a beginning of write operation to the texture.
///
/// @note prefers calls to \c writeToTexture: instead of calling \c beginWriteToTexture: and
/// \c endWriteToTexture:.
///
/// @see \c writeToTexture: for more information.
- (void)beginWriteToTexture;

/// Marks an ending of write operation to the texture.
///
/// @note prefers calls to \c writeToTexture: instead of calling \c beginWriteToTexture: and
/// \c endWriteToTexture:.
///
/// @see \c writeToTexture: for more information.
- (void)endWriteToTexture;

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

/// Loads a given image to the texture by replacing the current content of the texture. The size
/// and type of this \c Mat must match the \c size and \c precision properties of the texture. If
/// they don't match, an \c LTGLException with \c kLTOpenGLRuntimeErrorException will be thrown.
- (void)load:(const cv::Mat &)image;

/// Executes the block which is marked as a block that reads from the texture, allowing the texture
/// object to synchronize before and after the read.
///
/// @note all texture reads that are GPU based should be executed via this method, or be wrapped
/// with \c beginReadFromTexture: and endReadFromTexture: calls.
- (void)readFromTexture:(LTVoidBlock)block;

/// Executes the block which is marked as a block that writes to the texture, allowing the texture
/// object to synchronize before and after the read.
///
/// @note all texture writes that are GPU based should be executed via this method.
- (void)writeToTexture:(LTVoidBlock)block;

/// Block for transferring the texture contents while allowing read-only access. If \c isCopy is \c
/// YES, the given image is a copy of the texture and its reference can be stored outside the context
/// of the block. Otherwise, the memory is directly mapped to the texture's memory and \c mapped
/// should not be referenced outside this block (unless it is duplicated to a new \c cv::Mat).
typedef void (^LTTextureMappedReadBlock)(const cv::Mat &mapped, BOOL isCopy);

/// Block for transferring the texture contents and allow updates. If \c isCopy is \c YES, the given
/// image is a copy of the texture and its reference can be stored outside the context of the block.
/// Otherwise, the memory is directly mapped to the texture's memory and \c mapped should not be
/// referenced outside this block (unless it is duplicated to a new \c cv::Mat).
typedef void (^LTTextureMappedWriteBlock)(cv::Mat *mapped, BOOL isCopy);

/// Calls the given \c block with an image with the texture's contents. The contents of \mapped
/// cannot be modified. This allows to incorporate optimizations such as using reader-lock and
/// avoiding copy the buffer back to the GPU upon completion of this method.
///
/// @note if \c isCopy is set to \c YES, the \c mapped mat can be retained. Otherwise, no copies of
/// it should be made outside the block.
///
/// @see LTTextureMappedReadBlock for more information about the \c block.
- (void)mappedImageForReading:(LTTextureMappedReadBlock)block;

/// Calls the given \c block with an image with the texture's contents, which can be modified inside
/// the block. When the method returns, the texture's contents will contain the updated image
/// contents. The texture's \c fillColor will be set to \c LTVector4Null after this method is done.
///
/// @note if \c isCopy is set to \c YES, the \c mapped mat can be retained. Otherwise, no copies of
/// it should be made outside the block.
///
/// @see LTTextureMappedWriteBlock for more information about the \c block.
- (void)mappedImageForWriting:(LTTextureMappedWriteBlock)block;

/// Block for transferring texture contents as a \c CGImageRef for reading. If \c isCopy is \c YES,
/// the given image is a copy of the texture and its reference can be stored outside the context of
/// the block. Otherwise, the memory is directly mapped to the texture's memory and \c mapped should
/// not be referenced outside this block (unless it is duplicated to a new \c CGImageRef).
typedef void (^LTTextureMappedCGImageBlock)(CGImageRef imageRef, BOOL isCopy);

/// Calls the given \c block with a valid \c CGImageRef as a wrapper for the tetxure's data.
///
/// @note current implementation allows to create a image of textures of 1 or 4 channels only. An
/// assert will be thrown for other types of textures.
- (void)mappedCGImage:(LTTextureMappedCGImageBlock)block;

/// Block for transferring a core graphics bitmap context which is bound to the texture's data. The
/// context is only valid in this block and should not be retained. Information about the context
/// can be queried using the \c CGBitmapContextGet* functions.
typedef void (^LTTextureCoreGraphicsBlock)(CGContextRef context);

/// Calls the given \c block with a valid \c CGContextRef bound to the texture's memory. Any draw
/// calls to this context will appear on the texture after the \c block exits.
///
/// @note CoreGraphics' origin is bottom-left, but the given context will already have a
/// transformation attached that will change the origin to be the common top-left.
///
/// @note current implementation allows to draw to textures of 1 or 4 channels only. An assert will
/// be thrown for other types of textures.
///
/// @see LTTextureCoreGraphicsBlock for more information about the \c block.
- (void)drawWithCoreGraphics:(LTTextureCoreGraphicsBlock)block;

/// Returns pixel value at the given location, with symmetric boundary condition.  The returned
/// value is an RBGA value of the texture pixel at the given location. If the texture is of type
/// luminance, the single channel will be placed in the first vector element, while the others will
/// be set to \c 0.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (LTVector4)pixelValue:(CGPoint)location;

/// Returns pixel values at the given locations, with symmetric boundary condition. The returned
/// value is a vector of RBGA values of the texture pixels at the given locations.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (LTVector4s)pixelValues:(const CGPoints &)locations;

/// Returns the texture data that is contains in the given rect. The \c rect must be contained
/// inside the texture's bounds (0, 0, size.width, size.height). The resulting image precision and
/// depth will be set according to the texture's properties.
///
/// @note This is an expensive operation since it requires duplicating the texture to a new memory
/// location.
- (cv::Mat)imageWithRect:(CGRect)rect;

/// Returns a \c Mat object from the texture. This is a heavy operation since it requires
/// duplicating the texture to a new memory location. The matrix type and size depends on the
/// texture's values, but the matrix will always contain 4 channels.
///
/// @see storeRect:toImage: for more information.
- (cv::Mat)image;

/// Executes the given block while recording changes to the texture's openGL parameters (such as
/// \c minFilterInterpolation, \c magFilterInterpolation, and \c wrap). Any change to the parameters
/// inside this block will be recorded and reverted after the block completes executing.
- (void)executeAndPreserveParameters:(LTVoidBlock)execute;

/// Clears the texture with the given \c color. In case this is a mipmap texture, all its levels
/// will be cleared with the given \c color. This will set the texture's \c fillColor to the given
/// color.
- (void)clearWithColor:(LTVector4)color;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Size of the texture.
@property (readonly, nonatomic) CGSize size;

/// Precision of the texture.
@property (readonly, nonatomic) LTTexturePrecision precision;

/// Number of channels of the texture.
@property (readonly, nonatomic) LTTextureChannels channels;

/// Format the texture is stored with on the GPU.
@property (readonly, nonatomic) LTTextureFormat format;

/// Maximal (coarsest) mipmap level to be selected in this texture. For non-mipmap textures, this
/// value is \c 0.
@property (readonly, nonatomic) GLint maxMipmapLevel;

/// Set to \c YES if the texture is using its alpha channel. This cannot be inferred from the
/// texture data itself, and should be set to \c YES when needed. Setting this value to \c YES will
/// enable texture processing algorithms to avoid running computations on the alpha channel, saving
/// time and/or memory.  The default value is \c NO.
@property (nonatomic) BOOL usingAlphaChannel;

/// Interpolation of the texture when downsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation minFilterInterpolation;

/// Interpolation of the texture when upsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation magFilterInterpolation;

/// Warping of texture coordinates outside \c [0, 1]. Default is \c LTTextureWrapClamp. Setting this
/// to \c LTTextureWrapRepeat requires that the texture size will be a power of two. If this
/// condition doesn't hold, the property will not change.
@property (nonatomic) LTTextureWrap wrap;

/// Current generation ID of this texture. The generation ID changes whenever the texture is
/// modified, and is copied when a texture is cloned. This can be used as an efficient way to check
/// if a texture has changed or if two textures have the same content.
///
/// @note While two textures having equal \c generationID implies that they have the same
/// content, the other direction is not necessarily true as two textures can have the same content
/// with different \c generationID.
@property (readonly, nonatomic) NSString *generationID;

/// Returns the color the entire texture (and all its levels for mipmap textures) is filled with,
/// or \c LTVector4Null in case it is uncertain that the texture is filled with a single color.
/// This property is updated when the texture is cleared using \c clearWithColor, and set to
/// \c LTVector4Null whenever the texture is updated by any other method.
@property (readonly, nonatomic) LTVector4 fillColor;

@end

NS_ASSUME_NONNULL_END
