// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"
#import "LTTestModule.h"

/// Sets the current injector to strictly mock the given class and returns the mocked object.
#define LTStrictMockClass(CLASS) \
    _LTStrictMockClass(_module, _injector, CLASS)

/// Sets the current injector to nicely mock the given class and returns the mocked object.
#define LTMockClass(CLASS) \
    _LTMockClass(_module, _injector, CLASS)

/// Sets the current injector to nicely mock the given protocol and returns the mocked protocol.
#define LTMockProtocol(PROTOCOL) \
    _LTMockProtocol(_module, _injector, PROTOCOL)

/// Sets the current injector to bind the given object instance to the given class name and returns
/// it.
#define LTBindObjectToClass(OBJECT, CLASS) \
    _LTBindObjectToClass(_module, _injector, OBJECT, CLASS)

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

id _LTStrictMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass);
id _LTMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass);
id _LTMockProtocol(LTTestModule *module, JSObjectionInjector *injector, Protocol *protocol);
id _LTBindObjectToClass(LTTestModule *module, JSObjectionInjector *injector, id object,
                        Class objectClass);
