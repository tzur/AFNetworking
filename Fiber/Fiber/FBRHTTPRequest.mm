// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPRequest.h"

#import "FBRCompare.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark FBRHTTPRequestMethod
#pragma mark -

LTEnumImplement(NSUInteger, FBRHTTPRequestMethod,
  FBRHTTPRequestMethodGet,
  FBRHTTPRequestMethodHead,
  FBRHTTPRequestMethodPost,
  FBRHTTPRequestMethodPut,
  FBRHTTPRequestMethodPatch,
  FBRHTTPRequestMethodDelete
);

@implementation FBRHTTPRequestMethod (Fiber)

+ (NSDictionary<FBRHTTPRequestMethod *, NSString *> *)enumToHTTPMethodMap {
  static NSDictionary<FBRHTTPRequestMethod *, NSString *> *enumToHTTPMethodMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    enumToHTTPMethodMap = @{
      $(FBRHTTPRequestMethodGet): @"GET",
      $(FBRHTTPRequestMethodHead): @"HEAD",
      $(FBRHTTPRequestMethodPost): @"POST",
      $(FBRHTTPRequestMethodPut): @"PUT",
      $(FBRHTTPRequestMethodPatch): @"PATCH",
      $(FBRHTTPRequestMethodDelete): @"DELETE",
    };
  });

  return enumToHTTPMethodMap;
}

- (NSString *)HTTPMethod {
  return [FBRHTTPRequestMethod enumToHTTPMethodMap][self];
}

- (BOOL)downloadsData {
  return self.value == FBRHTTPRequestMethodGet;
}

- (BOOL)uploadsData {
  return self.value == FBRHTTPRequestMethodPost || self.value == FBRHTTPRequestMethodPut ||
      self.value == FBRHTTPRequestMethodPatch;
}

@end

#pragma mark -
#pragma mark FBRHTTPRequestParametersEncoding
#pragma mark -

LTEnumImplement(NSUInteger, FBRHTTPRequestParametersEncoding,
  FBRHTTPRequestParametersEncodingURLQuery,
  FBRHTTPRequestParametersEncodingJSON
);

#pragma mark -
#pragma mark FBRHTTPRequest
#pragma mark -

@implementation FBRHTTPRequest

+ (BOOL)isProtocolSupported:(NSURL *)URL {
  if (!URL.scheme) {
    return NO;
  }
  return [[self supportedProtocols] containsObject:[URL.scheme lowercaseString]];
}

+ (NSSet<NSString *> *)supportedProtocols {
  return [NSSet setWithObjects:@"http", @"https", nil];
}

- (instancetype)initWithURL:(NSURL *)URL method:(FBRHTTPRequestMethod *)method {
  return [self initWithURL:URL method:method parameters:nil parametersEncoding:nil
                   headers:nil];
}

- (instancetype)initWithURL:(NSURL *)URL method:(FBRHTTPRequestMethod *)method
                 parameters:(nullable FBRHTTPRequestParameters *)parameters
         parametersEncoding:(nullable FBRHTTPRequestParametersEncoding *)parametersEncoding
                    headers:(nullable FBRHTTPRequestHeaders *)headers {
  LTParameterAssert([[self class] isProtocolSupported:URL], @"Invalid URL specified, the protocol "
                    "%@ is not valid for HTTP requests. Supported protocols: %@", URL.scheme,
                    [[self class] supportedProtocols]);

  if (self = [super init]) {
    _URL = [URL copy];
    _method = [method copy];
    _parameters = [parameters copy];
    _parametersEncoding = [parametersEncoding copy];
    _headers = [headers copy];
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(FBRHTTPRequest *)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return FBRCompare(self.URL, object.URL) && FBRCompare(self.method, object.method) &&
      FBRCompare(self.parameters, object.parameters) &&
      FBRCompare(self.parametersEncoding, object.parametersEncoding) &&
      FBRCompare(self.headers, object.headers);
}

- (NSUInteger)hash {
  return self.URL.hash ^ self.method.hash ^ self.parameters.hash ^ self.parametersEncoding.hash ^
      self.headers.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, URL: %@, method: %@, parameters: %@, "
          "parameters-encoding: %@, headers: %@>",
          [self class], self, self.URL, self.method.HTTPMethod, self.parameters,
          self.parametersEncoding, self.headers];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
