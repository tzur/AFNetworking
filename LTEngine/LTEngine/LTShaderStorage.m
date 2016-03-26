// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTShaderStorage.h"

@implementation LTShaderStorage

static NSString * const kEncryptionKey = SHADER_ENCRYPTION_KEY;

+ (NSData *)unpackData:(NSData *)data withKey:(NSString *)key {
  NSUInteger keyLength = key.length;
  const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];

  NSMutableData *result = [NSMutableData dataWithLength:data.length];
  const char *source = data.bytes;
  char *target = result.mutableBytes;

  for (NSUInteger i = 0; i < data.length; ++i) {
    target[i] = source[i] ^ cKey[i % keyLength];
  }

  return result;
}

+ (NSString *)shaderWithBuffer:(void *)buffer ofLength:(NSUInteger)length {
  NSData *data = [NSData dataWithBytesNoCopy:(void *)buffer
                                      length:length
                                freeWhenDone:NO];
  NSData *decrypted = [[self class] unpackData:data withKey:kEncryptionKey];

  return [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
}

@end
