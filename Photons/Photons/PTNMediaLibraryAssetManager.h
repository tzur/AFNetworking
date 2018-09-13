// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager, PTNMediaQueryProvider;

/// Asset manager which backs the Media Library assets.
@interface PTNMediaLibraryAssetManager : NSObject <PTNAssetManager>

/// Initializes with the default implementations of \c PTNMediaQueryProvider and an instance of
/// \c PTNMediaLibraryAuthorizationManager as the authorization manager.
///
/// @see -initWithQueryProvider:authorizationManager:.
- (instancetype)init;

/// Initializes with the given \c queryProvider and an instance of
/// \c PTNMediaLibraryAuthorizationManager as the authorization manager.
///
/// @see -initWithQueryProvider:authorizationManager:.
- (instancetype)initWithQueryProvider:(id<PTNMediaQueryProvider>)queryProvider;

/// Initializes with the given \c queryProvider and the given \c authorizationManager.
- (instancetype)initWithQueryProvider:(id<PTNMediaQueryProvider>)queryProvider
                 authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
