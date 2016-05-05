// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTAttributeData.h"

#import "LTGPUStruct.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTAttributeData

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithData:(NSData *)data inFormatOfGPUStruct:(LTGPUStruct *)gpuStruct {
  LTParameterAssert(data);
  LTParameterAssert(gpuStruct);
  LTParameterAssert(!((size_t)data.length % gpuStruct.size),
                    @"Number of bytes (%lu) of the given data must be multiple of the number of "
                    "bytes (%lu) of the given gpu struct", (unsigned long)data.length,
                    (unsigned long)gpuStruct.size);

  if (self = [super init]) {
    _data = [data copy];
    _gpuStruct = gpuStruct;
  }
  return self;
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

- (BOOL)isEqual:(LTAttributeData *)attributeData {
  if (self == attributeData) {
    return YES;
  }

  if (![attributeData isKindOfClass:[LTAttributeData class]]) {
    return NO;
  }

  return [self.data isEqualToData:attributeData.data] &&
      [self.gpuStruct isEqual:attributeData.gpuStruct];
}

- (NSUInteger)hash {
  return self.data.hash ^ self.gpuStruct.hash;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, format: %@, data length (in bytes): %lu>",
          [self class], self, self.gpuStruct, (unsigned long)self.data.length];
}

@end

NS_ASSUME_NONNULL_END
