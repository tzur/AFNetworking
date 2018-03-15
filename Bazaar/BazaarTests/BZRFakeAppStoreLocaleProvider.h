// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake \c BZRAppStoreLocaleProvider for testing.
@interface BZRFakeAppStoreLocaleProvider : BZRAppStoreLocaleProvider

/// Mutable App Store locale. KVO-compliant.
@property (strong, readwrite, atomic, nullable) NSLocale *appStoreLocale;

@end

NS_ASSUME_NONNULL_END
