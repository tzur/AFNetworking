// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAcquiredViaSubscriptionProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAcquiredViaSubscriptionProvider ()

/// Storage used to persist the set of products that were acquired via subscription.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Subject used to send storage errors as values.
@property (readonly, nonatomic) RACSubject *storageErrorsSubject;

/// Set of products that were acquired via subscription.
@property (strong, readwrite, nonatomic) NSSet<NSString *> *productsAcquiredViaSubscription;

@end

@implementation BZRAcquiredViaSubscriptionProvider

@synthesize productsAcquiredViaSubscription = _productsAcquiredViaSubscription;

/// Key to the products acquired via subscription stored in the secure storage.
NSString * const kProductsAcquiredViaSubscriptionSetKey = @"productsAcquiredViaSubscriptionSet";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
    _storageErrorsSubject = [RACSubject subject];
  }
  return self;
}

#pragma mark -
#pragma mark Updating products set
#pragma mark -

- (void)addAcquiredViaSubscriptionProduct:(NSString *)productIdentifier {
  self.productsAcquiredViaSubscription =
      [self.productsAcquiredViaSubscription setByAddingObject:productIdentifier];
}

- (void)removeAcquiredViaSubscriptionProduct:(NSString *)productIdentifier {
  NSMutableSet *mutableSet = [NSMutableSet setWithSet:self.productsAcquiredViaSubscription];
  [mutableSet removeObject:productIdentifier];
  self.productsAcquiredViaSubscription = [mutableSet copy];
}

#pragma mark -
#pragma mark Loading/storing products set
#pragma mark -

- (void)setProductsAcquiredViaSubscription:(NSSet<NSString *> *)productsAcquiredViaSubscription {
  @synchronized (self) {
    _productsAcquiredViaSubscription = productsAcquiredViaSubscription;
    NSError *error;
    BOOL success = [self.keychainStorage setValue:productsAcquiredViaSubscription
                                           forKey:kProductsAcquiredViaSubscriptionSetKey
                                            error:&error];
    if (!success) {
      NSString *description =
          @"Failed to store products acquired via subscription set to secure storage";
      [self.storageErrorsSubject sendNext:
          [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed
                        description:description underlyingError:error]];
    }
  }
}

- (NSSet<NSString *> *)productsAcquiredViaSubscription {
  @synchronized (self) {
    if (!_productsAcquiredViaSubscription) {
      _productsAcquiredViaSubscription = [self loadProductsAcquiredViaSubscriptionFromStorage];
    }
    return _productsAcquiredViaSubscription;
  }
}

- (NSSet<NSString *> *)loadProductsAcquiredViaSubscriptionFromStorage {
  NSError *error;
  NSSet<NSString *> * _Nullable productsAcquiredViaSubscription =
      [self.keychainStorage valueOfClass:[NSSet class]
                                  forKey:kProductsAcquiredViaSubscriptionSetKey error:&error];
  if (error) {
    [self.storageErrorsSubject sendNext:error];
    return [NSSet set];
  } else if (!productsAcquiredViaSubscription) {
    return [NSSet set];
  }
  return productsAcquiredViaSubscription;
}

#pragma mark -
#pragma mark Storage errors
#pragma mark -

- (RACSignal *)storageErrorsSignal {
  return self.storageErrorsSubject;
}

@end

NS_ASSUME_NONNULL_END
