// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBTweak+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

/// Observes a given \c tweak and sends its value when its \c currentValue changes to \c subscriber.
@interface SHKTweakSignalObserver : RACDisposable <FBTweakObserver>

/// Initializes with a \c tweak to observe and \c subscriber to send \c tweaks value changes to.
- (instancetype)initWithTweak:(FBTweak *)tweak subscriber:(id<RACSubscriber>)subscriber;

/// The observed tweak.
@property (readonly, nonatomic) FBTweak *tweak;

/// Subscriber to send changes in \c tweak value to.
@property (readonly, nonatomic) id<RACSubscriber> subscriber;

@end

@implementation SHKTweakSignalObserver

- (instancetype)initWithTweak:(FBTweak *)tweak subscriber:(id<RACSubscriber>)subscriber {
  if (self = [super init]) {
    _tweak = tweak;
    _subscriber = subscriber;
    [self.tweak addObserver:self];
  }
  return self;
}

- (void)dealloc {
  [self dispose];
}

- (void)dispose {
  [self.tweak removeObserver:self];
}

- (void)tweakDidChange:(FBTweak *)tweak {
  [self.subscriber sendNext:tweak.currentValue];
}

@end

@implementation FBTweak (RACSignalSupport)

- (RACSignal *)shk_valueChanged {
  return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    return [[SHKTweakSignalObserver alloc] initWithTweak:self subscriber:subscriber];
  }] startWith:self.currentValue ?: self.defaultValue];
}

@end

NS_ASSUME_NONNULL_END
