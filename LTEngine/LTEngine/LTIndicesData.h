// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTIndicesArray.h"

NS_ASSUME_NONNULL_BEGIN

/// Value object containing binary data representing vertex indices. The binary data can readily be
/// provided to \c LTArrayBuffer objects of type \c LTArrayBufferTypeElement.
@interface LTIndicesData : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new \c LTIndicesData object with its \c data encoding the given \c indices and type
/// \c LTIndicesBufferTypeByte.
+ (LTIndicesData *)dataWithByteIndices:(const std::vector<GLubyte> &)indices;

/// Returns a new \c LTIndicesData object with its \c data encoding the given \c indices and type
/// \c LTIndicesBufferTypeShort.
+ (LTIndicesData *)dataWithShortIndices:(const std::vector<GLushort> &)indices;

/// Returns a new \c LTIndicesData object with its \c data encoding the given \c indices and type
/// \c LTIndicesBufferTypeInteger.
+ (LTIndicesData *)dataWithIntegerIndices:(const std::vector<GLuint> &)indices;

/// Binary data encoding the indices represented by this instance.
@property (readonly, nonatomic) NSData *data;

/// Type of the indices represented by this instance.
@property (readonly, nonatomic) LTIndicesBufferType type;

/// Number of indices.
@property (readonly, nonatomic) NSUInteger count;

@end

NS_ASSUME_NONNULL_END
