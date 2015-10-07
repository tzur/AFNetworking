// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Specta/SPTGlobalBeforeAfterEach.h>

NS_ASSUME_NONNULL_BEGIN

typedef _Nullable id (^JSObjectionBindBlock)(JSObjectionInjector *context);

/// Sets the current injector to strictly mock the given class and returns the mocked object.
id LTStrictMockClass(Class objectClass);

/// Sets the current injector to nicely mock the given class and returns the mocked object.
id LTMockClass(Class objectClass);

/// Sets the current injector to nicely mock the given protocol and returns the mocked protocol.
id LTMockProtocol(Protocol *protocol);

/// Sets the current injector to bind the given object instance to the given class name and returns
/// it.
id LTBindObjectToClass(id object, Class objectClass);

/// Sets the current injector to bind the given block to the given class name.
void LTBindBlockToClass(JSObjectionBindBlock block, Class objectClass);

/// Specta hook which sets a default injector with an on-the-fly configurable module. This allows
/// binding to classes, protocols and concrete instances in a specific spec. The hook switches the
/// default injector prior to the spec after the spec ends.
@interface LTSpectaObjectionHook : NSObject <SPTGlobalBeforeAfterEach>
@end

NS_ASSUME_NONNULL_END
