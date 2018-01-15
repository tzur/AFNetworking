// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorage+TypeSafety.h"

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRKeychainStorage (TypeSafety)

- (nullable id)valueOfClass:(Class)valueClass forKey:(NSString *)key
                      error:(NSError * __autoreleasing *)error {
  NSObject * _Nullable loadedValue = (NSObject *)[self valueForKey:key error:error];
  if (!loadedValue) {
    return nil;
  } else if (![loadedValue isKindOfClass:valueClass]) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Value loaded with key=%@ from keychain storage is not of the "
         "right type, expected %@ got %@", key, valueClass, [loadedValue class]];
    *error =
        [NSError bzr_storageErrorWithCode:BZRErrorCodeLoadingFromKeychainStorageFailed
                          underlyingError:nil description:errorDescription
               keychainStorageServiceName:self.service keychainStorageKey:key
                     keychainStorageValue:nil];
    return nil;
  }
  return loadedValue;
}

@end

NS_ASSUME_NONNULL_END
