// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "LTEventTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTEventTarget ()

/// Number of times \c handleEvent: was called.
@property (readwrite, nonatomic) NSUInteger counter;

/// Object received.
@property (readwrite, nonatomic, nullable) id object;

@end

@implementation LTEventTarget

- (instancetype)init {
  if (self = [super init]) {
    self.counter = 0;
    self.object = nil;
  }
  return self;
}

- (void)handleEvent:(id)object {
  ++self.counter;
  self.object = object;
}

- (BOOL)badSelector {
  LTAssert(NO, @"This method should never be called. Check your test.");
}

- (void)badSelector2:(CGFloat __unused)value {
  LTAssert(NO, @"This method should never be called. Check your test.");
}

- (void)badSelector3:(id __unused)object withValue:(CGFloat __unused)value {
  LTAssert(NO, @"This method should never be called. Check your test.");
}

- (void)badSelector4:(id __unused)object withAnother:(id __unused)anotherObject {
  LTAssert(NO, @"This method should never be called. Check your test.");
}

@end

NS_ASSUME_NONNULL_END
