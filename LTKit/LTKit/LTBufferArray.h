// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Type of buffer to create.
typedef NS_ENUM(NSUInteger, LTBufferArrayType) {
  /// Generic buffer that can hold vertex attributes.
  LTBufferArrayTypeGeneric = GL_ARRAY_BUFFER,
  /// Buffer that holds indices of vertices, mostly used in complex geometry.
  LTBufferArrayTypeElement = GL_ELEMENT_ARRAY_BUFFER
};

/// Usage hint for the buffer.
typedef NS_ENUM(NSUInteger, LTBufferArrayUsage) {
  /// Buffer is rendered many times, and its contents are specified once and never change.
  LTBufferArrayUsageStaticDraw = GL_STATIC_DRAW,
  /// Buffer is rendered many times, and its contents change during the rendering loop.
  LTBufferArrayUsageDynamicDraw = GL_DYNAMIC_DRAW,
  /// Buffer is rendered a small number of times and then discarded.
  LTBufferArrayUsageStreamDraw = GL_STREAM_DRAW
};

/// @class LTArrayBuffer
///
/// A class representing a GPU array buffer. There are two supported buffer types: array buffer,
/// which is a generic buffer for vertex attribute data such as position, color and normals, and an
/// element buffer, which is a buffer that holds vertex indices, useful for faster drawing of
/// complex geometry.
@interface LTArrayBuffer : NSObject

/// Initiailizes a new OpenGL buffer with a given type and buffer usage hint. The buffer will not
/// occupy memory on the GPU until the initial \c updateWithData: is called.
- (id)initWithType:(LTBufferArrayType)type usage:(LTBufferArrayUsage)usage;

/// Updates the buffer with the given data. If the size of the data is different than current size
/// of the buffer, the buffer will be re-allocated.
///
/// @note buffers of type \c LTBufferArrayUsageStaticDraw should only be initialized once. Trying to
/// update will yield an \c LTGLException with \c
/// kLTArrayBufferDisallowsStaticBufferUpdateException. For a buffer than can be updated
/// continuously, use \c LTBufferArrayUsageDynamicDraw or \c LTBufferArrayUsageStreamDraw.
- (void)setData:(NSData *)data;

/// Retrieves the buffer data back to the CPU. This triggers a GPU -> CPU copy.
///
/// @note this is a heavy operation which should usually be avoided. In common scenarios, try to
/// keep a local copy of your data, then update it and call \c updateWithData: to update it on the
/// GPU.
- (NSData *)data;

/// Binds the active context to the buffer. If the buffer is already bounded, nothing will happen.
/// Once \c bind() is called, you must call the matching \c unbind() when the resource is no longer
/// needed bound.
- (void)bind;

/// Unbinds the buffer from the current active OpenGL context and binds the previous program
/// instead. If the buffer is not bounded, nothing will happen.
- (void)unbind;

/// Executes the given block while the texture is bounded to the active context. This will
/// automatically \c bind and \c unbind the texture before and after the block, accordingly.
- (void)bindAndExecute:(LTVoidBlock)block;

/// OpenGL usage type of the buffer.
@property (readonly, nonatomic) LTBufferArrayUsage usage;

/// Type of the buffer array.
@property (readonly, nonatomic) LTBufferArrayType type;

/// OpenGL name of the buffer.
@property (readonly, nonatomic) GLuint name;

/// Size of the buffer, in bytes.
@property (readonly, nonatomic) NSUInteger size;

@end
