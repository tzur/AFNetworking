// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTIndicesData.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTIndicesData ()

/// Initializes with the given \c type and and \c data. \c type represents the type of the given
/// indices and \c data is a binary data encoding of the indices.
- (instancetype)initWithType:(LTIndicesBufferType)type data:(NSData *)data
    NS_DESIGNATED_INITIALIZER;

@end

@implementation LTIndicesData

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTIndicesBufferType)type data:(NSData *)data {
  if (self = [super init]) {
    _type = type;
    _data = data;
  }
  return self;
}

#pragma mark
#pragma mark Public Interface
#pragma mark

+ (LTIndicesData *)dataWithByteIndices:(const std::vector<GLubyte> &)indices {
  NSData *data = [NSData dataWithBytes:&indices[0] length:indices.size() * sizeof(GLubyte)];
  return [[LTIndicesData alloc] initWithType:LTIndicesBufferTypeByte data:data];
}

+ (LTIndicesData *)dataWithShortIndices:(const std::vector<GLushort> &)indices {
  NSData *data = [NSData dataWithBytes:&indices[0] length:indices.size() * sizeof(GLushort)];
  return [[LTIndicesData alloc] initWithType:LTIndicesBufferTypeShort data:data];
}

+ (LTIndicesData *)dataWithIntegerIndices:(const std::vector<GLuint> &)indices {
  NSData *data = [NSData dataWithBytes:&indices[0] length:indices.size() * sizeof(GLuint)];
  return [[LTIndicesData alloc] initWithType:LTIndicesBufferTypeInteger data:data];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark Equality
#pragma mark -

- (BOOL)isEqual:(LTIndicesData *)indicesData {
  if (self == indicesData) {
    return YES;
  }

  if (![indicesData isKindOfClass:[LTIndicesData class]]) {
    return NO;
  }

  return self.type == indicesData.type && [self.data isEqualToData:indicesData.data];
}

- (NSUInteger)hash {
  return self.data.hash ^ self.type;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)count {
  return self.data.length / [self elementSize];
}

- (NSUInteger)elementSize {
  switch (self.type) {
    case LTIndicesBufferTypeByte:
      return sizeof(GLbyte);
    case LTIndicesBufferTypeShort:
      return sizeof(GLushort);
    case LTIndicesBufferTypeInteger:
      return sizeof(GLuint);
  }
}

@end

NS_ASSUME_NONNULL_END
