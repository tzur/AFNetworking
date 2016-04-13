// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTAttributeData.h"

#import "LTGPUStruct.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTAttributeData

- (instancetype)initWithData:(NSData *)data inFormatOfGPUStruct:(LTGPUStruct *)gpuStruct {
  LTParameterAssert(data);
  LTParameterAssert(gpuStruct);
  LTParameterAssert(!((size_t)data.length % gpuStruct.size),
                    @"Number of bytes (%lu) of the given data must be multiple of the number of "
                    "bytes (%lu) of the given gpu struct", (unsigned long)data.length,
                    (unsigned long)gpuStruct.size);

  if (self = [super init]) {
    _data = data;
    _gpuStruct = gpuStruct;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, format: %@, data length (in bytes): %lu>",
          [self class], self, self.gpuStruct, (unsigned long)self.data.length];
}

@end

NS_ASSUME_NONNULL_END
