// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTIndicesArray.h"

#import "LTArrayBuffer.h"

@interface LTIndicesArray ()

/// Array buffer that contains the indices.
@property (strong, nonatomic) LTArrayBuffer *arrayBuffer;

/// Type of the indices in the array.
@property (nonatomic) LTIndicesBufferType type;

@end

@implementation LTIndicesArray

- (instancetype)initWithType:(LTIndicesBufferType)type arrayBuffer:(LTArrayBuffer *)arrayBuffer {
  LTParameterAssert(arrayBuffer);
  LTParameterAssert(arrayBuffer.type == LTArrayBufferTypeElement);
  if (self = [super init]) {
    self.type = type;
    self.arrayBuffer = arrayBuffer;
  }
  return self;
}

- (NSUInteger)count {
  return self.arrayBuffer.size / [self elementSizeForType:self.type];
}

- (NSUInteger)elementSizeForType:(LTIndicesBufferType)type {
  switch (type) {
    case LTIndicesBufferTypeByte:
      return sizeof(GLbyte);
    case LTIndicesBufferTypeShort:
      return sizeof(GLushort);
    case LTIndicesBufferTypeInteger:
      return sizeof(GLuint);
  }
}

@end
