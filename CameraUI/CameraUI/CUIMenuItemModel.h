// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Model class for a menu item. Has the menu item's localized title, icon URL and an
/// identification key.
@interface CUIMenuItemModel : MTLModel <MTLJSONSerializing>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the menu item with the given values.
- (instancetype)initWithLocalizedTitle:(NSString *)localizedTitle iconURL:(NSURL *)iconURL
                                   key:(NSString *)key NS_DESIGNATED_INITIALIZER;

/// Title of the menu item.
@property (readonly, nonatomic) NSString *localizedTitle;

/// Icon URL for the menu item.
@property (readonly, nonatomic) NSURL *iconURL;

/// Key of the menu item.
@property (readonly, nonatomic) NSString *key;

@end

NS_ASSUME_NONNULL_END
