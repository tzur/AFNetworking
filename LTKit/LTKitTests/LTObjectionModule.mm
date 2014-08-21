// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTObjectionModule.h"

@implementation JSObjectionInjector (LTKitAdditions)

- (void)lt_updateModule:(JSObjectionModule *)module {
  NSSet *mergedSet = [module.eagerSingletons setByAddingObjectsFromSet:_eagerSingletons];
  _eagerSingletons = mergedSet;
  [_context addEntriesFromDictionary:module.bindings];
}

@end

@interface LTObjectionModule ()

// Contains mocks for both classes and protocols which might produce colisions.
@property (strong, nonatomic) NSMutableDictionary *mocks;

@end

@implementation LTObjectionModule

- (id)init {
  if (self = [super init]) {
    self.mocks = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)mockClass:(Class)className {
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    NSString * const key = NSStringFromClass(className);

    if (!self.mocks[key]) {
      self.mocks[key] = OCMStrictClassMock(className);
    }

    return self.mocks[key];
  } toClass:className];
}

- (void)niceMockClass:(Class)className {
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    NSString * const key = NSStringFromClass(className);

    if (!self.mocks[key]) {
      self.mocks[key] = OCMClassMock(className);
    }

    return self.mocks[key];
  } toClass:className];
}

- (void)mockProtocol:(Protocol *)protocol {
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    NSString *const key = NSStringFromProtocol(protocol);

    if (!self.mocks[key]) {
      self.mocks[key] = OCMProtocolMock(protocol);
    }

    return self.mocks[key];
  } toProtocol:protocol];
}

@end
