// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFPaintCodeImageProvider.h"

#import <LTKit/LTCGExtensions.h>
#import <LTKit/UIColor+Utilities.h>

#import "NSErrorCodes+Wireframes.h"

NS_ASSUME_NONNULL_BEGIN

/// Value class holding all fields required to produce an image based on a PaintCode asset.
@interface WFPaintCodeImageRequest : NSObject

/// URL used to create this request.
@property (strong, nonatomic) NSURL *url;

/// Name of the PaintCode module.
@property (copy, nonatomic) NSString *moduleName;

/// Name of the asset in the module.
@property (copy, nonatomic) NSString *assetName;

/// Frame to draw the asset in.
@property (nonatomic) CGRect frame;

/// Color to draw the asset with.
@property (strong, nonatomic, nullable) UIColor *color;

/// Line width used to draw the asset.
@property (strong, nonatomic, nullable) NSNumber *lineWidth;

@end

@implementation WFPaintCodeImageRequest

- (BOOL)isEqual:(WFPaintCodeImageRequest *)object {
  if (self == object) {
    return YES;
  }

  if (![self isKindOfClass:object.class]) {
    return NO;
  }

  return [self.url isEqual:object.url] &&
      [self.moduleName isEqual:object.moduleName] &&
      [self.assetName isEqual:object.assetName] &&
      self.frame == object.frame &&
      (self.color == object.color || [self.color isEqual:object.color]) &&
      (self.lineWidth == object.lineWidth || [self.lineWidth isEqual:object.lineWidth]);
}

- (NSUInteger)hash {
  return self.url.hash ^ self.moduleName.hash ^ self.assetName.hash ^ $(self.frame).hash ^
      self.color.hash ^ self.lineWidth.hash;
}

@end

@interface WFPaintCodeImageProvider ()

/// Cache used to store rendered images.
@property (readonly, nonatomic) NSCache<NSURL *, UIImage *> *cache;

@end

@implementation WFPaintCodeImageProvider

- (instancetype)init {
  if (self = [super init]) {
    _cache = [[NSCache alloc] init];
  }
  return self;
}

- (RACSignal<UIImage *> *)imageWithURL:(NSURL *)url {
  UIImage * _Nullable cachedImage = [self.cache objectForKey:url];
  if (cachedImage) {
    return [RACSignal return:cachedImage];
  }

  return [[[[[RACSignal
      return:url]
      tryMap:^(NSURL *url, NSError *__autoreleasing *error) {
        return [self requestFromURL:url error:error];
      }]
      tryMap:^(WFPaintCodeImageRequest *request, NSError *__autoreleasing *error) {
        return [self imageForRequest:request error:error];
      }]
      doNext:^(UIImage *image) {
        [self.cache setObject:image forKey:url];
      }]
      subscribeOn:[RACScheduler scheduler]];
}

- (nullable WFPaintCodeImageRequest *)requestFromURL:(NSURL *)url
                                               error:(NSError *__autoreleasing *)error {
  if (![self verifyURL:url error:error]) {
    return nil;
  }

  WFPaintCodeImageRequest *request = [[WFPaintCodeImageRequest alloc] init];
  request.url = url;
  request.moduleName = url.host;
  request.assetName = url.pathComponents[1];

  CGSize size = CGSizeZero;
  NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                           resolvingAgainstBaseURL:YES];
  for (NSURLQueryItem *item in components.queryItems) {
    if ([item.name isEqualToString:@"width"]) {
      size.width = [item.value doubleValue];
    } else if ([item.name isEqualToString:@"height"]) {
      size.height = [item.value doubleValue];
    } else if ([item.name isEqualToString:@"color"]) {
      request.color = [UIColor lt_colorWithHex:item.value];
    } else if ([item.name isEqualToString:@"lineWidth"]) {
      request.lineWidth = @([item.value doubleValue]);
    } else {
      if (error) {
        *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                               description:@"Unsupported parameter %@", item.name];
      }
      return nil;
    }
  }

  if (size.width <= 0 || size.height <= 0) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"Illegal image size (%g, %g)", size.width, size.height];
    }
    return nil;
  }
  request.frame = CGRectFromOriginAndSize(CGPointZero, size);

  return request;
}

- (nullable UIImage *)imageForRequest:(WFPaintCodeImageRequest *)request
                                error:(NSError * __autoreleasing *)error {
  id target = NSClassFromString(request.moduleName);
  if (!target) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeAssetNotFound url:request.url
                             description:@"Requested PaintCode module %@ not found",
                request.moduleName];
    }
    return nil;
  }

  SEL selector = [self selectorForRequest:request];
  NSMethodSignature *methodSignature = [target methodSignatureForSelector:selector];
  if (![target respondsToSelector:selector] || !methodSignature) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeAssetNotFound url:request.url
                             description:@"Requested selector %@ not found in module %@",
                NSStringFromSelector(selector), request.moduleName];
    }
    return nil;
  }

  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
  invocation.selector = selector;

  NSInteger paramIndex = 2;
  CGRect frame = request.frame;
  [invocation setArgument:&frame atIndex:paramIndex++];
  if (request.color) {
    UIColor *color = request.color;
    [invocation setArgument:&color atIndex:paramIndex++];
  }
  if (request.lineWidth) {
    CGFloat lineWidth = [request.lineWidth doubleValue];
    [invocation setArgument:&lineWidth atIndex:paramIndex++];
  }
  LTAssert((NSUInteger)paramIndex == methodSignature.numberOfArguments,
           @"Selector %@ is expected to have exactly %ld arguments, but has %lu instead",
           NSStringFromSelector(selector), (long)paramIndex,
           (unsigned long)methodSignature.numberOfArguments);

  UIImage *result;
  UIGraphicsBeginImageContextWithOptions(request.frame.size, NO, 0); {
    [invocation invokeWithTarget:target];
    result = UIGraphicsGetImageFromCurrentImageContext();
  } UIGraphicsEndImageContext();

  return result;
}

- (SEL)selectorForRequest:(WFPaintCodeImageRequest *)request {
  NSMutableString *name = [NSMutableString stringWithFormat:@"draw%@WithFrame:", request.assetName];
  if (request.color) {
    [name appendString:@"color:"];
  }
  if (request.lineWidth) {
    [name appendString:@"lineWidth:"];
  }
  return NSSelectorFromString(name);
}

- (BOOL)verifyURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![url.scheme isEqualToString:@"paintcode"]) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"Unexpected URL scheme %@", url.scheme];
    }
    return NO;
  }

  if (!url.host) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL does not specify a host, which must be a valid "
                                          "PaintCode module"];
    }
    return NO;
  }

  if (url.port) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL must not have a port"];
    }
    return NO;
  }

  if (url.user) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL must not have a user"];
    }
    return NO;
  }

  if (url.password) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL must not have a password"];
    }
    return NO;
  }

  if (url.pathComponents.count != 2) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL path must have a single component: asset name"];
    }
    return NO;
  }

  if (url.pathExtension.length) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL path must not have a path extension"];
    }
    return NO;
  }

  if (url.fragment) {
    if (error) {
      *error = [NSError lt_errorWithCode:WFErrorCodeInvalidURL url:url
                             description:@"URL path must not have a fragment"];
    }
    return NO;
  }

  return YES;
}

@end

NS_ASSUME_NONNULL_END
