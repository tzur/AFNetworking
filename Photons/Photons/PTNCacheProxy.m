// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheProxy.h"

#import "PTNCacheInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheProxy

- (instancetype)initWithUnderlyingObject:(id<NSObject>)underlyingObject
                               cacheInfo:(PTNCacheInfo *)cacheInfo {
  if (self = [super init]) {
    _underlyingObject = underlyingObject;
    _cacheInfo = cacheInfo;
  }
  return self;
}

#pragma mark -
#pragma mark Proxy
#pragma mark -

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
  return [super conformsToProtocol:aProtocol] ||
      [self.underlyingObject conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  return [super respondsToSelector:aSelector] ||
      [self.underlyingObject respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
  return [self.underlyingObject respondsToSelector:selector] ?
      self.underlyingObject : [super forwardingTargetForSelector:selector];;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, underlying object: %@, cache info: %@>",
          self.class, self, self.underlyingObject, self.cacheInfo];
}

- (BOOL)isEqual:(PTNCacheProxy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.underlyingObject isEqual:object.underlyingObject] &&
      [self.cacheInfo isEqual:object.cacheInfo];
}

- (NSUInteger)hash {
  return self.underlyingObject.hash ^ self.cacheInfo.hash;
}

@end

NS_ASSUME_NONNULL_END
