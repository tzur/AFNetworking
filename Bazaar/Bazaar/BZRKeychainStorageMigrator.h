// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

@class BZRKeychainStorage;

NS_ASSUME_NONNULL_BEGIN

/// Class for migrating values from one keychain storage to another.
@interface BZRKeychainStorageMigrator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c sourceKeychainStorage that contains the desired values to migrate and
/// \c targetKeychainStorage as the target storage.
- (instancetype)initWithSourceKeychainStorage:(BZRKeychainStorage *)sourceKeychainStorage
                        targetKeychainStorage:(BZRKeychainStorage *)targetKeychainStorage
    NS_DESIGNATED_INITIALIZER;

/// Copies the value specified in \c key of class \c valueCalss from \c sourceKeychainStorage to
/// \c targetKeychainStorage. Returns \c YES if the migration succeeded or if \c key is already
/// exist in the target storage, otherwise returns \c NO and \c error is set with an appropriate
/// error. After successful migration the copied value is deleted from \c sourceKeychainStorage.
- (BOOL)migrateValueForKey:(NSString *)key ofClass:(Class)valueClass error:(NSError **)error;

/// Creates a migrator using an instance of \c BZRKeychainStorage initialized with \c nil access
/// group as the \c sourceKeychainStorage, and another instance of \c BZRKeychainStorage initialized
/// with Lightricks shared access group as \c targetKeychainStorage.
+ (BZRKeychainStorageMigrator *)migratorWithBazaarKeychains;

@end

NS_ASSUME_NONNULL_END
