// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Precision of each channel of the texture on the GPU.
typedef NS_ENUM(GLenum, LTTexturePrecision) {
  LTTexturePrecisionByte = GL_UNSIGNED_BYTE,
  LTTexturePrecisionHalfFloat = GL_HALF_FLOAT_OES,
  LTTexturePrecisionFloat = GL_FLOAT,
};

/// Type of interpolation used by the sampler on the GPU.
typedef NS_ENUM(GLenum, LTTextureInterpolation) {
  /// Nearest neighbor interpolation.
  LTTextureInterpolationNearest = GL_NEAREST,
  /// Linear interpolation.
  LTTextureInterpolationLinear = GL_LINEAR,
};

/// Type of wraping used by the sampler for texture coodinates outside [0, 1].
typedef NS_ENUM(GLenum, LTTextureWrap) {
  /// Clamp texture coordinates.
  LTTextureWrapClamp = GL_CLAMP_TO_EDGE,
  /// Wrap texture coordinates cyclically.
  LTTextureWrapRepeat = GL_REPEAT,
};

/// Number of channels stored in the texture.
typedef NS_ENUM(NSUInteger, LTTextureChannels) {
  /// Luminance (single channel).
  LTTextureChannelsLuminance = 1,
  /// RGBA (four channels).
  LTTextureChannelsRGBA = 4,
};

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
@interface LTTexture : NSObject {
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
/// @param size size of the texture.
/// @param precision precision of the texture.
/// @param channels number of channels of the texture.
/// @param allocateMemory if set to \c YES, the texture's memory will be allocated on the GPU (but
/// will not be initialized - see note). Otherwise, only a texture object will be created, and a
/// call to \c load: or \c loadRect:fromImage: will be required to allocate memory on the device.
///
/// @note The texture memory is not allocated until a call to \c load: or \c loadRect: is made, and
/// only the affected regions are set to be in a defined state. Calling \c storeRect:toImage: with
/// an uninitialized rect will return an undefined result.
///
/// @note Designated initializer.
- (id)initWithSize:(CGSize)size precision:(LTTexturePrecision)precision
          channels:(LTTextureChannels)channels allocateMemory:(BOOL)allocateMemory;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture. Throws \c LTGLException with \c
/// kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has failed.
- (id)initWithImage:(const cv::Mat &)image;

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

/// Loads a given image to the texture by replacing the current content of the texture. The size
/// and type of this \c Mat must match the \c size and \c precision properties of the texture. If
/// they don't match, an \c LTGLException with \c kLTOpenGLRuntimeErrorException will be thrown.
- (void)load:(const cv::Mat &)image;

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

/// Stores the texture's data in the given \rect to the given \image. The image will be created with
/// the same precision and size of the given \rect, if needed. The rect must be contained in the
/// texture's rect (0, 0, size.width, size.height).
- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image;

/// Loads data from the given \image to texture at the given \rect. The image must have the same
/// precision as the texture's and the same size as the given \rect. The rect must be contained in
/// the texture's rect (0, 0, size.width, size.height).
- (void)loadRect:(CGRect)rect fromImage:(const cv::Mat &)image;

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

/// Binds the active context to the texture. If the texture is already bounded, nothing will happen.
/// Once \c bind() is called, you must call the matching \c unbind() when the resource is no longer
/// needed for rendering.
- (void)bind;

/// Unbinds the texture from the current active OpenGL context and binds the previous program
/// instead. If the texture is not bounded, nothing will happen.
- (void)unbind;

/// Executes the given block while the texture is bounded to the active context. This will
/// automatically \c bind and \c unbind the texture before and after the block, accordingly.
- (void)bindAndExecute:(LTVoidBlock)block;

/// Clones the texture. This creates a new texture with the same content, but with a different
/// OpenGL name. The cloning process tries to preserve the precision of the texture, according to
/// device limitations. This means that the cloned texture can be of lower precision than the
/// original. Float precision textures will always be converted to half-float (if supported by
/// device) or regular precision. Half-float precision textures will be converted to unsigned byte
/// precision if no support for half-float color buffers is available.
- (LTTexture *)clone;

/// Clones the texture into the given texture. If the target texture is of different size, the
/// texture will be resized to fit exactly into the target texture. This means that if the aspect
/// ratio is different the cloned texture will be distorted.
- (void)cloneTo:(LTTexture *)texture;

/// Returns pixel value at the given location, with symmetric boundary condition.  The returned
/// value is an RBGA value of the texture pixel at the given location. If the texture is of type
/// luminance, the single channel will be placed in the first vector element, while the others will
/// be set to \c 0.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (GLKVector4)pixelValue:(CGPoint)location;

/// Returns pixel values at the given locations, with symmetric boundary condition. The returned
/// value is a vector of RBGA values of the texture pixels at the given locations.
///
/// @note This can be a heavy operation since it may require copying the texture pixel data to the
/// CPU's memory.
- (GLKVector4s)pixelValues:(const CGPoints &)locations;

/// Returns the texture data that is contains in the given rect. The \c rect must be contained
/// inside the texture's bounds (0, 0, size.width, size.height). The resulting image precision and
/// depth will be set according to the texture's properties.
///
/// @note This is an expensive operation since it requires duplicating the texture to a new memory
/// location.
- (cv::Mat)imageWithRect:(CGRect)rect;

/// Returns a \c Mat object from the texture. This is a heavy operation since it requires
/// duplicating the texture to a new memory location. The matrix type, size and number of channels
/// depends on the texture's values.
- (cv::Mat)image;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Size of the texture.
@property (readonly, nonatomic) CGSize size;

/// OpenGL identifier of the texture.
@property (readonly, nonatomic) GLuint name;

/// Precision of the texture.
@property (readonly, nonatomic) LTTexturePrecision precision;

// Number of channels of the texture.  Currently supported number is 1 (luminance only) and 4
// (RGBA).
@property (readonly, nonatomic) LTTextureChannels channels;

/// Set to \c YES if the texture is using its alpha channel. This cannot be inferred from the
/// texture data itself, and should be set to \c YES when needed. Setting this value to \c YES will
/// enable texture processing algorithms to avoid running computations on the alpha channel, saving
/// time and/or memory.  The default value is \c NO.
@property (nonatomic) BOOL usingAlphaChannel;

/// Returns \c YES if the texture is using multiple byte channels to encode higher precision values.
/// This cannot be inferred from the texture data itself, and should be set to \c YES when needed.
/// The default value is \c NO.
@property (nonatomic) BOOL usingHighPrecisionByte;

/// Interpolation of the texture when downsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation minFilterInterpolation;

/// Interpolation of the texture when upsampling. Default is \c LTTextureInterpolationLinear.
@property (nonatomic) LTTextureInterpolation magFilterInterpolation;

/// Warping of texture coordinates outside \c [0, 1]. Default is \c LTTextureWrapClamp. Setting this
/// to \c LTTextureWrapRepeat requires that the texture size will be a power of two. If this
/// condition doesn't hold, the property will not change.
@property (nonatomic) LTTextureWrap wrap;

@end
