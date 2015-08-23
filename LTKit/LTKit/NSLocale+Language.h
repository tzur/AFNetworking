// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSLocale (Language)

/// Preferred language for the current device. This is the current iOS interface language, the one
/// appearing on top of the list in Settings-General-International-Language.
///
/// @return the canonicalized IETF BCP 47 representation of the preferred language, or \c nil if the
/// language is not available.
@property (readonly, nonatomic) NSString *lt_preferredLanguage;

/// Language the app is currently using. In case a localization of the preferred language is not
/// available, the best available language will be selected (according to the order of the languages
/// in Settings-General-International-Language).
///
/// @return the canonicalized IETF BCP 47 representation of the preferred language, or \c nil if the
/// language is not available.
///
/// @note the current app language is determined by the main bundle only, meaning it assumes that
/// localizations to the main bundle apply to other bundles as well.
@property (readonly, nonatomic) NSString *lt_currentAppLanguage;

@end

NS_ASSUME_NONNULL_END
