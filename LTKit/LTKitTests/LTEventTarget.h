// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Class used to register in \c LTEventBus during tests.
@interface LTEventTarget : NSObject

/// Increments \c counter and keeps \c object.
- (void)handleEvent:(id)object;

/// Raises an exception.
- (BOOL)badSelector;

/// Raises an exception.
- (void)badSelector2:(CGFloat)value;

/// Raises an exception.
- (void)badSelector3:(id)object withValue:(CGFloat)value;

/// Raises an exception.
- (void)badSelector4:(id)object withAnother:(id)anotherObject;

/// Number of times \c handleEvent: was called.
@property (readonly, nonatomic) NSUInteger counter;

/// Object received.
@property (readonly, nonatomic, nullable) id object;

@end

NS_ASSUME_NONNULL_END
