// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTArrayBuffer;

/// Type of the indices in the \c LTIndicesArray.
typedef NS_ENUM(NSUInteger, LTIndicesBufferType) {
  LTIndicesBufferTypeByte = GL_UNSIGNED_BYTE,
  LTIndicesBufferTypeShort = GL_UNSIGNED_SHORT,
  LTIndicesBufferTypeInteger = GL_UNSIGNED_INT
};

/// Encapsulates an \c LTArrayBuffer of \c LTArrayBufferTypeElement, including the data type of the
/// indices in the underlying buffer.
@interface LTIndicesArray : NSObject

/// Initializes the \c LTIndicesArray with the given type and array buffer (must be of type
/// \c LTArrayBufferTypeElement).
- (instancetype)initWithType:(LTIndicesBufferType)type arrayBuffer:(LTArrayBuffer *)arrayBuffer;

/// Array buffer that contains the indices.
@property (readonly, nonatomic) LTArrayBuffer *arrayBuffer;

/// Type of the indices in the array.
@property (readonly, nonatomic) LTIndicesBufferType type;

/// Number of indices in the array.
@property (readonly, nonatomic) NSUInteger count;

@end
