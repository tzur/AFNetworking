// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Global settings that can be used by all of the HelpUI model classes.
@interface HUIModelSettings : NSObject

/// Type for block that localizes an \c NSString.
typedef NSString *_Nullable(^HUILocalizationBlock)(NSString *);

/// localizes the given \c text using the \c localizationBlock. If \c localizationBlock is \c nil,
/// returns the given \c text.
+ (NSString *)localize:(NSString *)text;

/// Used to localize strings. In case it is not set or set to \c nil, no localization is done.
@property (class, nonatomic, nullable) HUILocalizationBlock localizationBlock;

@end

NS_ASSUME_NONNULL_END
