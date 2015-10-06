// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTEngine/LTGLContext.h>
#import <LTEngineTests/LTTestModule.h>

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

/// Sets the current injector to bind the given block to the given class name.
#define LTBindBlockToClass(BLOCK, CLASS) \
    _LTBindBlockToClass(_module, _injector, BLOCK, CLASS)

/// Adds the given view to the key window. This will, among other things, set the view's
/// \c traitCollection property, needed for tests involving Auto Layout.
#define LTAddViewToWindow(VIEW) \
    [_keyWindowView addSubview:VIEW];

/// Defines the concrete class to use as Objection module in tests. If \c LTKIT_TEST_MODULE_CLASS
/// macro is defined this class will be used. The default module class is \c LTTestModule.
#ifdef LTKIT_TEST_MODULE_CLASS
  #define _LTTestModule LTKIT_TEST_MODULE_CLASS
#else
  #define _LTTestModule LTTestModule
#endif

/// Defines a beginning of an LTKit test spec.
#define LTSpecBegin(name) \
    SpecBegin(name) \
    \
    __block JSObjectionInjector *_lastUsedInjector; \
    __block JSObjectionInjector *_injector; \
    __block _LTTestModule *_module; \
    __block UIView *_keyWindowView; \
    \
    beforeEach(^{ \
      _module = [[_LTTestModule alloc] init]; \
      \
      _lastUsedInjector = [JSObjection defaultInjector]; \
      _injector = [JSObjection createInjector:_module]; \
      [JSObjection setDefaultInjector:_injector]; \
      \
      LTGLContext *context = [[LTGLContext alloc] init]; \
      [LTGLContext setCurrentContext:context]; \
      \
      _keyWindowView = [[UIView alloc] initWithFrame:CGRectZero]; \
      [[UIApplication sharedApplication].keyWindow addSubview:_keyWindowView]; \
    }); \
    \
    afterEach(^{ \
      [JSObjection setDefaultInjector:_lastUsedInjector]; \
      \
      _injector = nil; \
      _module = nil; \
      \
      [LTGLContext setCurrentContext:nil]; \
      \
      [_keyWindowView removeFromSuperview]; \
      _keyWindowView = nil; \
    });

/// End of spec.
#define LTSpecEnd SpecEnd

typedef id (^JSObjectionBindBlock)(JSObjectionInjector *context);

id _LTStrictMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass);
id _LTMockClass(LTTestModule *module, JSObjectionInjector *injector, Class objectClass);
id _LTMockProtocol(LTTestModule *module, JSObjectionInjector *injector, Protocol *protocol);
id _LTBindObjectToClass(LTTestModule *module, JSObjectionInjector *injector, id object,
                        Class objectClass);
void _LTBindBlockToClass(LTTestModule *module, JSObjectionInjector *injector,
                         JSObjectionBindBlock block, Class objectClass);
