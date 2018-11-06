// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTTypedefs.h>
#import <OpenGLES/ES2/glext.h>

#import "LTFboAttachable.h"
#import "LTGLPixelFormat.h"
#import "LTTypedefs+LTEngine.h"

NS_ASSUME_NONNULL_BEGIN

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

/// Type of wrapping used by the sampler for texture coordinates outside [0, 1].
typedef NS_ENUM(GLenum, LTTextureWrap) {
  /// Clamp texture coordinates.
  LTTextureWrapClamp = GL_CLAMP_TO_EDGE,
  /// Wrap texture coordinates cyclically.
  LTTextureWrapRepeat = GL_REPEAT
};

namespace cv {
  class Mat;
}

struct LTVector4;

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
///
/// @note Binding texture objects binds them to the currently active texture unit in the OpenGL
/// environment. Unbinding textures restores the state previous to the last \c bind call.
@interface LTTexture : NSObject <LTFboAttachable> {
  @protected
  GLuint _name;
  LTGLContext *_context;
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init NS_UNAVAILABLE;

/// Creates an empty texture on the GPU. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if texture creation failed.
///
/// @param size size of the texture. Must be integral.
///
/// @param pixelFormat pixel format the texture is stored in the GPU with. The format must be
/// supported on the target platform, or an \c NSInvalidArgumentException will be thrown.
///
/// @param maxMipmapLevel maximal mipmap level, with \c 0 meaning that only a single level exists.
/// Not all implementations might support mipmap textures, in which case the parameter must be \c 0
/// or an exception will be raised.
///
/// @param allocateMemory an optimization recommendation to implementors of this class. If set to
/// \c YES, the texture's memory will be allocated on the GPU (but will not be initialized - see
/// note). Otherwise, the implementation will try to create a texture object only without allocating
/// the memory, and a call to \c load: or \c loadRect:fromImage: will be required to allocate
/// memory on the device.
///
/// @note The texture memory is not allocated until a call to \c load: or \c loadRect: is made, and
/// only the affected regions are set to be in a defined state. Calling \c storeRect:toImage: with
/// an uninitialized rect will return an undefined result.
///
/// @note Designated initializer. The base implementation performs initialization with the given
/// parameters but does not actually create the texture. Implementations must override this
/// initializer and perform the creation themselves.
- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel
              allocateMemory:(BOOL)allocateMemory NS_DESIGNATED_INITIALIZER;

/// Creates an empty texture on the GPU without mipmap. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if texture creation failed. This is a convenience method which
/// is similar to calling:
///
/// @code
/// initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0 allocateMemory:allocateMemory
/// @endcode
- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              allocateMemory:(BOOL)allocateMemory;

/// Allocates a texture with the \c size and \c pixelFormat properties suitable for the given
/// \c image, and loads the \c image to the texture. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has
/// failed.
- (instancetype)initWithImage:(const cv::Mat &)image;

/// Creates a new, allocated texture with \c size, \c pixelFormat and \c maxMipmapLevel similar to
/// the given \c texture. This is a convenience method which is similar to calling:
///
/// @code
/// initWithSize:texture.size pixelFormat:texture.pixelFormat maxMipmapLevel:texture.maxMipmapLevel
///     allocateMemory:YES
/// @endcode
- (instancetype)initWithPropertiesOf:(LTTexture *)texture;

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

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
- (LTTexture *)clone;

/// Clones the texture into the given texture. The target \c texture must be of the same size of the
/// receiver.
- (void)cloneTo:(LTTexture *)texture;

/// Returns a pixel buffer with the content of this texture. The returned pixel buffer might be a
/// copy of the texture's content, or it might be the actual pixel buffer that backs the texture and
/// is shared with the GPU.
///
/// It is guaranteed that all previous GPU operations involving writes to the texture complete
/// before the pixel buffer is returned. On the other hand, future operations MUST be synchronized
/// manually, which is very difficult to get right. Avoid operating on both the pixel buffer and the
/// texture at all cost.
///
/// The format of the pixel buffer is implementation dependent.
///
/// Raises if the pixel buffer cannot be returned, either because of an allocation failure,
/// unsupported texture format, or any other error.
///
/// @note you <b>MUST NOT</b> write to the texture while holding the returned pixel buffer. The best
/// approach is to avoid using the texture at all after calling this function.
- (lt::Ref<CVPixelBufferRef>)pixelBuffer;

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

/// Loads a given image to the texture by replacing the current content of the texture. The size
/// and type of this \c Mat must match the \c size and \c precision properties of the texture. If
/// they don't match, an \c LTGLException with \c kLTOpenGLRuntimeErrorException will be thrown.
- (void)load:(const cv::Mat &)image;

/// Block for transferring the texture contents while allowing read-only access. If \c isCopy is
/// \c YES, the given image is a copy of the texture and its reference can be stored outside the
/// context of the block. Otherwise, the memory is directly mapped to the texture's memory and
/// \c mapped should not be referenced outside this block (unless it is duplicated to a new
/// \c cv::Mat).
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
- (void)mappedImageForReading:(NS_NOESCAPE LTTextureMappedReadBlock)block;

/// Calls the given \c block with an image with the texture's contents, which can be modified inside
/// the block. When the method returns, the texture's contents will contain the updated image
/// contents. The texture's \c fillColor will be set to \c LTVector4Null after this method is done.
///
/// @note if \c isCopy is set to \c YES, the \c mapped mat can be retained. Otherwise, no copies of
/// it should be made outside the block.
///
/// @see LTTextureMappedWriteBlock for more information about the \c block.
- (void)mappedImageForWriting:(NS_NOESCAPE LTTextureMappedWriteBlock)block;

/// Block for transferring texture contents as a \c CGImageRef for reading. If \c isCopy is \c YES,
/// the given image is a copy of the texture and its reference can be stored outside the context of
/// the block. Otherwise, the memory is directly mapped to the texture's memory and \c mapped should
/// not be referenced outside this block (unless it is duplicated to a new \c CGImageRef).
typedef void (^LTTextureMappedCGImageBlock)(CGImageRef imageRef, BOOL isCopy);

/// Calls the given \c block with a valid \c CGImageRef as a wrapper for the texture's data.
///
/// @note current implementation allows to create a image of textures of 1 or 4 channels only
/// (otherwise assertion fires). Half float pixel format is supported, however it's assumed pixel
/// values are pre multiplied with alpha.
- (void)mappedCGImage:(NS_NOESCAPE LTTextureMappedCGImageBlock)block;

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
- (void)drawWithCoreGraphics:(NS_NOESCAPE LTTextureCoreGraphicsBlock)block;

/// Block for transferring texture contents as a \c CIImage for reading. The given image should not
/// be stored or used outside the context of the block.
typedef void (^LTTextureMappedCIImageBlock)(CIImage *image);

/// Calls the given \c block with a valid \c CIImage as a wrapper for the texture's data.
///
/// @note current implementation allows to create an image of textures of 1 or 4 channels only on
/// certain configurations. An assert will be thrown for other types of textures.
- (void)mappedCIImage:(LTTextureMappedCIImageBlock)block;

/// Block for drawing into the texture's data using Core Image. The block should return a \c CIImage
/// that will be rendered to the entire texture data using a \c CIContext, or \c nil in order to opt
/// out without rendering anything.
typedef CIImage * _Nullable(^LTTextureCoreImageBlock)();

/// Calls the given \c block and renders the \c CIImage it returns (which can be the output of a
/// \c CIFilter for example) into the entire texture. In case the given \c block returns \c nil, the
/// texture is left unchanged.
///
/// @note: On simulator, it is currently possible to draw only to textures of byte precision.
- (void)drawWithCoreImage:(NS_NOESCAPE LTTextureCoreImageBlock)block;

/// Returns pixel value at the given location, with symmetric boundary condition. The returned
/// value is an RBGA value of the texture pixel at the given location.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (LTVector4)pixelValue:(CGPoint)location;

/// Returns pixel values at the given locations, with symmetric boundary condition. The returned
/// value is a vector of RBGA values of the texture pixels at the given locations.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (LTVector4s)pixelValues:(const std::vector<CGPoint> &)locations;

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
- (void)executeAndPreserveParameters:(NS_NOESCAPE LTVoidBlock)execute;

/// Clears the texture with the given \c color. In case this is a mipmap texture, all its levels
/// will be cleared with the given \c color. This will set the texture's \c fillColor to the given
/// color.
- (void)clearColor:(LTVector4)color;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Components of the underlying pixel buffer, derived from \c pixelFormat.
@property (readonly, nonatomic) LTGLPixelComponents components;

/// Data type of each component of pixel of the underlying pixel buffer, derived from
/// \c pixelFormat.
@property (readonly, nonatomic) LTGLPixelDataType dataType;

/// Maximal (coarsest) mipmap level to be selected in this texture. For non-mipmap textures, this
/// value is \c 0.
@property (readonly, nonatomic) GLint maxMipmapLevel;

/// Set to \c YES if the texture is using its alpha channel. This cannot be inferred from the
/// texture data itself, and should be set to \c YES when needed. Setting this value to \c YES will
/// enable texture processing algorithms to avoid running computations on the alpha channel, saving
/// time and/or memory. The default value is \c NO.
@property (nonatomic) BOOL usingAlphaChannel;

/// Interpolation of the texture when downsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation minFilterInterpolation;

/// Interpolation of the texture when upsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation magFilterInterpolation;

/// Warping of texture coordinates outside \c [0, 1]. Default is \c LTTextureWrapClamp. Setting this
/// to \c LTTextureWrapRepeat requires that the texture size will be a power of two. If this
/// condition doesn't hold, the property will not change.
@property (nonatomic) LTTextureWrap wrap;

@end

NS_ASSUME_NONNULL_END
