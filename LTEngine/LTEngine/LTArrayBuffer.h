// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

// Type of buffer to create.
typedef NS_ENUM(NSUInteger, LTArrayBufferType) {
  /// Generic buffer that can hold vertex attributes.
  LTArrayBufferTypeGeneric = GL_ARRAY_BUFFER,
  /// Buffer that holds indices of vertices, mostly used in complex geometry.
  LTArrayBufferTypeElement = GL_ELEMENT_ARRAY_BUFFER
};

/// Usage hint for the buffer.
typedef NS_ENUM(NSUInteger, LTArrayBufferUsage) {
  /// Buffer is rendered many times, and its contents are specified once and never change.
  LTArrayBufferUsageStaticDraw = GL_STATIC_DRAW,
  /// Buffer is rendered many times, and its contents change during the rendering loop.
  LTArrayBufferUsageDynamicDraw = GL_DYNAMIC_DRAW,
  /// Buffer is rendered a small number of times and then discarded.
  LTArrayBufferUsageStreamDraw = GL_STREAM_DRAW
};

/// A class representing a GPU array buffer. There are two supported buffer types: array buffer,
/// which is a generic buffer for vertex attribute data such as position, color and normals, and an
/// element buffer, which is a buffer that holds vertex indices, useful for faster drawing of
/// complex geometry.  The user of this class is responsible for managing the CPU copy of the data,
/// together with the data types this buffer holds. For an external viewer, \c LTArrayBuffer holds
/// a buffer of bytes with no meaningful structure or types.
@interface LTArrayBuffer : NSObject <LTGPUResource>

/// Initiailizes a new OpenGL buffer with a given type and buffer usage hint. The buffer will not
/// occupy memory on the GPU until the initial \c updateWithData: is called.
- (instancetype)initWithType:(LTArrayBufferType)type usage:(LTArrayBufferUsage)usage;

/// Updates the buffer with the given data. If the size of the data is different than current size
/// of the buffer, the buffer will be re-allocated.
///
/// @note buffers of type \c LTArrayBufferUsageStaticDraw should only be initialized once. Trying to
/// update will yield an \c LTGLException with \c
/// kLTArrayBufferDisallowsStaticBufferUpdateException. For a buffer than can be updated
/// continuously, use \c LTArrayBufferUsageDynamicDraw or \c LTArrayBufferUsageStreamDraw.
- (void)setData:(NSData *)data;

/// Updates the buffer with the data in the given array (of \c NSData), concatenated one after
/// another according to their order in the array. If the total size of the data is different than
/// the current size of the buffer, the buffer will be re-allocated.
///
/// @note buffers of type \c LTArrayBufferUsageStaticDraw should only be initialized once. Trying to
/// update will yield an \c LTGLException with \c
/// kLTArrayBufferDisallowsStaticBufferUpdateException. For a buffer than can be updated
/// continuously, use \c LTArrayBufferUsageDynamicDraw or \c LTArrayBufferUsageStreamDraw.
///
/// @note The \c NSData objects in the provided \c dataArray are weakly held by this instance, for
/// optimization purposes. Providing identical \c NSData objects in consecutive calls to this method
/// avoids unnecessary memory copying.
- (void)setDataWithConcatenatedData:(NSArray<NSData *> *)dataArray;

/// Retrieves the buffer data back to the CPU. This triggers a GPU -> CPU copy.
///
/// @note this is a heavy operation which should usually be avoided. In common scenarios, try to
/// keep a local copy of your data, then update it and call \c updateWithData: to update it on the
/// GPU.
- (NSData *)data;

/// OpenGL usage type of the buffer.
@property (readonly, nonatomic) LTArrayBufferUsage usage;

/// Type of the buffer array.
@property (readonly, nonatomic) LTArrayBufferType type;

/// Size of the buffer, in bytes.
@property (readonly, nonatomic) NSUInteger size;

@end
