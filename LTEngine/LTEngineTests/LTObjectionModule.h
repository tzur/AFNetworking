// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@interface JSObjectionInjector (LTKitAdditions)

/// Updates the given module. If the module doesn't exists, it is added to the injector.
- (void)lt_updateModule:(JSObjectionModule *)module;

@end

/// Objection module for easily mocking classes and protocols.
@interface LTObjectionModule : JSObjectionModule

/// Mocks the given class.
- (void)mockClass:(Class)className;

/// Nice mocks the given class.
- (void)niceMockClass:(Class)className;

/// Mocks the given protocol.
- (void)mockProtocol:(Protocol *)protocol;

@end
