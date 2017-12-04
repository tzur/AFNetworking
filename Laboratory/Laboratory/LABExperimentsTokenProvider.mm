// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABExperimentsTokenProvider.h"

#import <LTKit/LTKeyValuePersistentStorage.h>
#import <LTKit/LTRandom.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kLABExperimentsTokenProviderTokenKey =
    @"LABExperimentsTokenProviderTokenKey";

@interface LABExperimentsTokenProvider ()

/// Used to store the \c experimentsToken.
@property (readonly, nonatomic) id<LTKeyValuePersistentStorage> storage;

/// Used to generate new \c experimentsToken.
@property (readonly, nonatomic) LTRandom *random;

@end

@implementation LABExperimentsTokenProvider

@synthesize experimentsToken = _experimentsToken;

- (instancetype)init {
  return [self initWithStorage:[NSUserDefaults standardUserDefaults]
                        random:[[LTRandom alloc] init]];
}

- (instancetype)initWithStorage:(id<LTKeyValuePersistentStorage>)storage random:(LTRandom *)random {
  if (self = [super init]) {
    _storage = storage;
    _random = random;
    [self setupExperimentsToken];
  }
  return self;
}

- (void)setupExperimentsToken {
  auto _Nullable experimentsToken = [self loadToken];
  if (!experimentsToken) {
    experimentsToken = @([self.random randomDouble]);
    [self storeToken:experimentsToken];
  }
  _experimentsToken = experimentsToken.doubleValue;
}

- (nullable NSNumber *)loadToken {
  id _Nullable object = [self.storage objectForKey:kLABExperimentsTokenProviderTokenKey];
  if ([object isKindOfClass:NSNumber.class]) {
    return object;
  }
  return nil;
}

- (void)storeToken:(NSNumber *)experimentsToken {
  [self.storage setObject:experimentsToken forKey:kLABExperimentsTokenProviderTokenKey];
}

@end

NS_ASSUME_NONNULL_END
