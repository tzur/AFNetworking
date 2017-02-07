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
    *error =
        [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed
                  underlyingError:underlyingError
                      description:@"Failed to load value with key=%@ from keychain storage", key];
    return nil;
  } else if (!loadedValue) {
    return nil;
  } else if (![loadedValue isKindOfClass:valueClass]) {
    *error =
    [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed
                  description:@"Value loaded with key=%@ from keychain storage is not of the right "
     "type, expected %@ got %@", key, valueClass, [loadedValue class]];
    return nil;
  }
  return loadedValue;
}

@end

NS_ASSUME_NONNULL_END
