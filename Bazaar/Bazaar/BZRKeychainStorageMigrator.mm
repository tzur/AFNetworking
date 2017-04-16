// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRKeychainStorageMigrator.h"

#import "BZREvent.h"
#import "BZRKeychainStorage.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRKeychainStorageMigrator ()

/// The storage the values are copying from.
@property (readonly, nonatomic) BZRKeychainStorage *sourceKeychainStorage;

/// The storage the values are copying to.
@property (readonly, nonatomic) BZRKeychainStorage *targetKeychainStorage;

@end

@implementation BZRKeychainStorageMigrator

- (instancetype)initWithSourceKeychainStorage:(BZRKeychainStorage *)sourceKeychainStorage
                        targetKeychainStorage:(BZRKeychainStorage *)targetKeychainStorage {
  if (self = [super init]) {
    _sourceKeychainStorage = sourceKeychainStorage;
    _targetKeychainStorage = targetKeychainStorage;
  }

  return self;
}

- (BOOL)migrateValueForKey:(NSString *)key ofClass:(Class)valueClass
                     error:(NSError * __autoreleasing *)error {
  if ([self.targetKeychainStorage valueOfClass:valueClass forKey:key error:nil]) {
    return YES;
  }

  NSError *underlyingError;
  id valueToMigrate = [self.sourceKeychainStorage valueOfClass:valueClass forKey:key
                                                         error:&underlyingError];
  if (underlyingError) {
    if (error) {
      *error = underlyingError;
    }
    return NO;
  }

  BOOL success = [self.targetKeychainStorage setValue:valueToMigrate forKey:key
                                                error:&underlyingError];
  if (!success) {
    if (error) {
      *error = underlyingError;
    }
    return NO;
  }

  [self.sourceKeychainStorage setValue:nil forKey:key error:nil];
  return YES;
}

+ (BZRKeychainStorageMigrator *)migratorFromPrivateToSharedAcccessGroup {
  NSString *privateAccessGroup = [BZRKeychainStorage accessGroupWithAppIdentifierPrefix:
                                  [NSBundle mainBundle].bundleIdentifier];
  NSString *sharedAccessGroup = [BZRKeychainStorage defaultSharedAccessGroup];

  auto *sourceKeychainStorage = [[BZRKeychainStorage alloc] initWithAccessGroup:privateAccessGroup];
  auto *targetKeychainStorage = [[BZRKeychainStorage alloc] initWithAccessGroup:sharedAccessGroup];

  return [[BZRKeychainStorageMigrator alloc] initWithSourceKeychainStorage:sourceKeychainStorage
                                                     targetKeychainStorage:targetKeychainStorage];
}

@end

NS_ASSUME_NONNULL_END
