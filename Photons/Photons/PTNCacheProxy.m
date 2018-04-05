// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheProxy.h"

#import "PTNCacheInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheProxy

- (instancetype)initWithUnderlyingObject:(id<NSObject>)underlyingObject
                               cacheInfo:(PTNCacheInfo *)cacheInfo {
  if (self) {
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

- (BOOL)isKindOfClass:(Class)aClass {
  return [PTNCacheProxy.class isEqual:aClass] || [self.underlyingObject isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
  return [PTNCacheProxy.class isEqual:aClass] || [self.underlyingObject isMemberOfClass:aClass];
}

- (Class)superclass {
  return [self.underlyingObject superclass];
}

- (Class)class {
  return [self.underlyingObject class];
}

- (id _Nullable)forwardingTargetForSelector:(SEL)selector {
  return [self.underlyingObject respondsToSelector:selector] ? self.underlyingObject : nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  [invocation setTarget:self.underlyingObject];
  [invocation invoke];
}

- (nullable NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  return [self.underlyingObject methodSignatureForSelector:sel];
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

  if ([object isKindOfClass:PTNCacheProxy.class]) {
    return [self.underlyingObject isEqual:object.underlyingObject] &&
        [self.cacheInfo isEqual:object.cacheInfo];
  }

  if ([object isKindOfClass:self.underlyingObject.class]) {
    return [self.underlyingObject isEqual:object];
  }

  return NO;
}

- (NSUInteger)hash {
  return self.underlyingObject.hash;
}

@end

NS_ASSUME_NONNULL_END
