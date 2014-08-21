// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"
#import "LTTestModule.h"

/// Sets the current injector to strictly mock the given class.
#define LTStrictMockClass(CLASS) \
    [_module mockClass:CLASS]; \
    [_injector lt_updateModule:_module]

/// Sets the current injector to nicely mock the given class.
#define LTMockClass(CLASS) \
    [_module niceMockClass:CLASS]; \
    [_injector lt_updateModule:_module]

/// Sets the current injector to nicely mock the given protocol.
#define LTMockProtocol(PROTOCOL) \
    [_module mockProtocol:PROTOCOL]; \
    [_injector lt_updateModule:_module]

/// Sets the current injector to bind the given object instance to the given class name.
#define LTBindObjectToClass(OBJECT, CLASS) \
    [_module bind:OBJECT toClass:CLASS]; \
    [_injector lt_updateModule:_module]

/// Defines a beginning of an LTKit test spec.
#define LTSpecBegin(name) \
    SpecBegin(name) \
    \
    __block JSObjectionInjector *_lastUsedInjector; \
    __block JSObjectionInjector *_injector; \
    __block LTTestModule *_module; \
    \
    beforeEach(^{ \
      _module = [[LTTestModule alloc] init]; \
      \
      _lastUsedInjector = [JSObjection defaultInjector]; \
      _injector = [JSObjection createInjector:_module]; \
      [JSObjection setDefaultInjector:_injector]; \
      \
      LTGLContext *context = [[LTGLContext alloc] init]; \
      [LTGLContext setCurrentContext:context]; \
    }); \
    \
    afterEach(^{ \
      [JSObjection setDefaultInjector:_lastUsedInjector]; \
      \
      _injector = nil; \
      _module = nil; \
      \
      [LTGLContext setCurrentContext:nil]; \
    });

/// End of spec.
#define LTSpecEnd SpecEnd
