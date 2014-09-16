// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "Specta+LTKit.h"

id _LTStrictMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass) {
  [module mockClass:objectClass];
  [injector lt_updateModule:module];
  return injector[objectClass];
}

id _LTMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass) {
  [module niceMockClass:objectClass];
  [injector lt_updateModule:module];
  return injector[objectClass];
}

id _LTMockProtocol(LTTestModule *module, JSObjectionInjector *injector, Protocol *protocol) {
  [module mockProtocol:protocol];
  [injector lt_updateModule:module];
  return injector[protocol];
}

id _LTBindObjectToClass(LTTestModule *module, JSObjectionInjector *injector, id object,
                        Class objectClass) {
  [module bind:object toClass:objectClass];
  [injector lt_updateModule:module];
  return object;
}
