// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Model class for a menu item. Has the menu item's localized title, icon URL and an
/// identification key.
@interface CUIMenuItemModel : MTLModel <MTLJSONSerializing>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the menu item with the given values.
- (instancetype)initWithLocalizedTitle:(nullable NSString *)localizedTitle
                               iconURL:(nullable NSURL *)iconURL
                                   key:(nullable NSString *)key NS_DESIGNATED_INITIALIZER;

/// Title of the menu item.
@property (readonly, nonatomic, nullable) NSString *localizedTitle;

/// Icon URL for the menu item.
@property (readonly, nonatomic, nullable) NSURL *iconURL;

/// Key of the menu item.
@property (readonly, nonatomic, nullable) NSString *key;

@end

NS_ASSUME_NONNULL_END
