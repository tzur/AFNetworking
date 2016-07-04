// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionRequestMarshalling.h"

#import "FBRCompare.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPSessionRequestMarshalling

- (instancetype)init {
  return [self initWithParametersEncoding:$(FBRHTTPRequestParametersEncodingURLQuery) headers:nil];
}

- (instancetype)initWithParametersEncoding:(FBRHTTPRequestParametersEncoding *)parametersEncoding
                                   headers:(nullable FBRHTTPRequestHeaders *)headers {
  if (self = [super init]) {
    _parametersEncoding = parametersEncoding;
    _headers = headers;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  FBRHTTPSessionRequestMarshalling *requestMarshalling = object;
  return FBRCompare(self.parametersEncoding, requestMarshalling.parametersEncoding) &&
      FBRCompare(self.headers, requestMarshalling.headers);
}

- (NSUInteger)hash {
  return self.parametersEncoding.hash ^ self.headers.hash;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
