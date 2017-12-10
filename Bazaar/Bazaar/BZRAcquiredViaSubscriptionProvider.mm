// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAcquiredViaSubscriptionProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRKeychainStorageMigrator.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAcquiredViaSubscriptionProvider ()

/// Storage used to persist the set of products that were acquired via subscription.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

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
    _productsAcquiredViaSubscription = [NSSet set];
    [self refreshProductsAcquiredViaSubscription:nil];
  }
  return self;
}

#pragma mark -
#pragma mark Updating products set
#pragma mark -

- (void)addAcquiredViaSubscriptionProduct:(NSString *)productIdentifier {
  [self addAcquiredViaSubscriptionProducts:[NSSet setWithObject:productIdentifier]];
}

- (void)addAcquiredViaSubscriptionProducts:(NSSet<NSString *> *)productIdentifiers {
  self.productsAcquiredViaSubscription =
      [self.productsAcquiredViaSubscription setByAddingObjectsFromSet:productIdentifiers];
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
    [self.keychainStorage setValue:productsAcquiredViaSubscription
                            forKey:kProductsAcquiredViaSubscriptionSetKey
                             error:nil];
  }
}

- (nullable NSSet<NSString *> *)refreshProductsAcquiredViaSubscription:
    (NSError * __autoreleasing *)error {
  @synchronized (self) {
    NSSet<NSString *> * _Nullable productsAcquiredViaSubscription =
        [self productsAcquiredViaSubscriptionFromCache:error];

    if (productsAcquiredViaSubscription) {
      [self willChangeValueForKey:@keypath(self, productsAcquiredViaSubscription)];
      _productsAcquiredViaSubscription = productsAcquiredViaSubscription;
      [self didChangeValueForKey:@keypath(self, productsAcquiredViaSubscription)];
      return productsAcquiredViaSubscription;
    }

    return nil;
  }
}

- (nullable NSSet<NSString *> *)productsAcquiredViaSubscriptionFromCache:
    (NSError * __autoreleasing *)error {
  NSError *storageError;
  NSSet<NSString *> * _Nullable productsAcquiredViaSubscription =
      [self.keychainStorage valueOfClass:[NSSet class]
                                  forKey:kProductsAcquiredViaSubscriptionSetKey
                                   error:&storageError];
  if (storageError) {
    if (error) {
      *error = storageError;
    }

    return nil;
  }

  return productsAcquiredViaSubscription ?: [NSSet set];
}

#pragma mark -
#pragma mark Migration
#pragma mark -

+ (BOOL)migrateProductsAcquiredViaSubscriptionWithMigrator:(BZRKeychainStorageMigrator *)migrator
                                                     error:(NSError * __autoreleasing *)error {
  return [migrator migrateValueForKey:kProductsAcquiredViaSubscriptionSetKey ofClass:[NSSet class]
                                error:error];
}

@end

NS_ASSUME_NONNULL_END
