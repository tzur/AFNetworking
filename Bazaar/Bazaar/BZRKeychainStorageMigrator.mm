// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRKeychainStorageMigrator.h"

#import "BZREvent.h"
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
  NSString *appIdentiferPrefix =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];
  NSString *privateAccessGroup =
      [appIdentiferPrefix stringByAppendingString:[NSBundle mainBundle].bundleIdentifier];
  NSString *sharedAccessGroup =
      [appIdentiferPrefix stringByAppendingString:@"com.lightricks.shared"];

  BZRKeychainStorage *sourceKeychainStorage = [[BZRKeychainStorage alloc]
                                               initWithAccessGroup:privateAccessGroup];
  BZRKeychainStorage *targetKeychainStorage = [[BZRKeychainStorage alloc]
                                               initWithAccessGroup:sharedAccessGroup];

  return [[BZRKeychainStorageMigrator alloc] initWithSourceKeychainStorage:sourceKeychainStorage
                                                     targetKeychainStorage:targetKeychainStorage];
}

@end

NS_ASSUME_NONNULL_END
