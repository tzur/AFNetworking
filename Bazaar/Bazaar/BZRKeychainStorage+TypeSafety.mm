// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorage+TypeSafety.h"

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRKeychainStorage (TypeSafety)

- (nullable id)valueOfClass:(Class)valueClass forKey:(NSString *)key
                      error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSObject *loadedValue = (NSObject *)[self valueForKey:key error:&underlyingError];
  if (!loadedValue && underlyingError) {
    NSString *description =
        [NSString stringWithFormat:@"Failed to load value with key=%@ from keychain storage", key];
    *error =
        [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed
                      description:description underlyingError:underlyingError];
    return nil;
  } else if (!loadedValue) {
    return nil;
  } else if (![loadedValue isKindOfClass:valueClass]) {
    NSString *description =
        [NSString stringWithFormat:@"Value loaded with key=%@ from keychain storage is not of the"
         "right type, expected %@ got %@", key, valueClass, [loadedValue class]];
    *error =
        [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed description:description];
    return nil;
  }
  return loadedValue;
}

@end

NS_ASSUME_NONNULL_END
