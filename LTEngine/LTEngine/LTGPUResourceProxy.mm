// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResourceProxy.h"

#import "LTGLContext+Internal.h"
#import "LTGPUResource.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTGPUResourceProxy

- (instancetype)initWithResource:(NSObject<LTGPUResource> *)resource {
  if (self) {
    _resource = resource;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)respondsToSelector:(SEL)aSelector {
  return [_resource respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL __unused)aSelector {
  return _resource;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  [invocation setTarget:self.resource];
  [invocation invoke];
}

- (nullable NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  return [self.resource methodSignatureForSelector:sel];
}

- (void)dealloc {
  auto resource = self.resource;
  [resource.context executeAsyncBlock:^{
    [resource dispose];
  }];
}

- (Class)class {
  return [self.resource class];
}

- (BOOL)isEqual:(id)object {
  return [object isEqual:self.resource];
}

- (NSUInteger)hash {
  return [self.resource hash];
}

- (BOOL)isKindOfClass:(Class)aClass {
  return [self.resource isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
  return [self.resource isMemberOfClass:aClass];
}

- (Class)superclass {
  return [self.resource superclass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
  return [self.resource conformsToProtocol:aProtocol];
}

- (NSString *)description {
  return [self.resource description];
}

- (NSString *)debugDescription {
  if ([self.resource respondsToSelector:@selector(debugDescription)]) {
    return [self.resource debugDescription];
  } else {
    return [NSString stringWithFormat:@"<%@: %p, resource: %@>", self, self, self.resource];
  }
}

@end

NS_ASSUME_NONNULL_END
