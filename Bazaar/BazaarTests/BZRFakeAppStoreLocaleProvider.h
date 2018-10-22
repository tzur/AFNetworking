// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake \c BZRAppStoreLocaleProvider for testing.
@interface BZRFakeAppStoreLocaleProvider : BZRAppStoreLocaleProvider

/// Initializes with mock objects.
- (instancetype)init;

/// Mutable App Store locale. KVO-compliant.
@property (strong, readwrite, atomic, nullable) NSLocale *appStoreLocale;

/// Mutable flag for locale fetching.
@property (readwrite, atomic) BOOL localeFetchedFromProductList;

@end

NS_ASSUME_NONNULL_END
