// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSpectaObjectionHook.h"

#import "LTObjectionModule.h"
#import "LTTestModule.h"

NS_ASSUME_NONNULL_BEGIN

/// Defines the concrete class to use as Objection module in tests. If \c LTKIT_TEST_MODULE_CLASS
/// macro is defined this class will be used. The default module class is \c LTTestModule.
#ifdef LTKIT_TEST_MODULE_CLASS
  #define _LTTestModule LTKIT_TEST_MODULE_CLASS
#else
  #define _LTTestModule LTTestModule
#endif

@interface LTSpectaObjectionHook ()

/// Module used for binding configuration.
+ (LTObjectionModule *)module;

/// Default injector used in the spec.
+ (JSObjectionInjector *)injector;

@end

id LTStrictMockClass(Class objectClass) {
  [LTSpectaObjectionHook.module mockClass:objectClass];
  [LTSpectaObjectionHook.injector lt_updateModule:LTSpectaObjectionHook.module];
  return LTSpectaObjectionHook.injector[objectClass];
}

id LTMockClass(Class objectClass) {
  [LTSpectaObjectionHook.module niceMockClass:objectClass];
  [LTSpectaObjectionHook.injector lt_updateModule:LTSpectaObjectionHook.module];
  return LTSpectaObjectionHook.injector[objectClass];
}

id LTMockProtocol(Protocol *protocol) {
  [LTSpectaObjectionHook.module mockProtocol:protocol];
  [LTSpectaObjectionHook.injector lt_updateModule:LTSpectaObjectionHook.module];
  return LTSpectaObjectionHook.injector[protocol];
}

id LTBindObjectToClass(id _Nullable object, Class objectClass) {
  [LTSpectaObjectionHook.module bind:object toClass:objectClass];
  [LTSpectaObjectionHook.injector lt_updateModule:LTSpectaObjectionHook.module];
  return object;
}

void LTBindBlockToClass(JSObjectionBindBlock block, Class objectClass) {
  [LTSpectaObjectionHook.module bindBlock:block toClass:objectClass];
  [LTSpectaObjectionHook.injector lt_updateModule:LTSpectaObjectionHook.module];
}

@implementation LTSpectaObjectionHook

static LTObjectionModule *_module;
static JSObjectionInjector *_injector;
static JSObjectionInjector *_lastUsedInjector;

+ (void)beforeEach {
  _module = [[_LTTestModule alloc] init];

  _lastUsedInjector = [JSObjection defaultInjector];

  _injector = [JSObjection createInjector:self.module];
  [JSObjection setDefaultInjector:self.injector];
}

+ (void)afterEach {
  [JSObjection setDefaultInjector:_lastUsedInjector];

  _lastUsedInjector = nil;
  _injector = nil;
  _module = nil;
}

+ (LTObjectionModule *)module {
  return _module;
}

+ (JSObjectionInjector *)injector {
  return _injector;
}

@end

NS_ASSUME_NONNULL_END
