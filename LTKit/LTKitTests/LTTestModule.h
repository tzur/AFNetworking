// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Adds Specta's \c beforeEach and \c afterEach blocks to configure \c LTTestModule as an injected
/// module with the default injector, and restores the previously set default injector after the
/// tests (if available).
#define LTKitTestsUseObjection() \
  __block JSObjectionInjector *lastUsedInjector; \
  __block JSObjectionInjector *injector; \
  __block LTTestModule *module; \
  \
  beforeEach(^{ \
    module = [[LTTestModule alloc] init]; \
  \
    lastUsedInjector = [JSObjection defaultInjector]; \
    injector = [JSObjection createInjector:module]; \
    [JSObjection setDefaultInjector:injector]; \
  }); \
  \
  afterEach(^{ \
    [JSObjection setDefaultInjector:lastUsedInjector]; \
  });

/// Objection module for LTKit tests. The module is initially initialized with empty partial mocks
/// of the given classes, allowing the user to override any required functionality in the test
/// class.
@interface LTTestModule : JSObjectionModule

/// \c UIScreen partical mock object.
@property (strong, nonatomic) id uiScreen;

/// \c UIDevice partical mock object.
@property (strong, nonatomic) id uiDevice;

/// \c LTDevice partical mock object.
@property (strong, nonatomic) id ltDevice;

/// \c UIApplication partical mock object.
@property (strong, nonatomic) id uiApplication;

/// \c NSFileManager partical mock object.
@property (strong, nonatomic) id nsFileManager;

/// \c LTFileManager partical mock object.
@property (strong, nonatomic) id ltFileManager;

@end
